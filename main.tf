resource "google_compute_firewall" "ssh" {
  name    = "${var.project_id}-firewall-basion-ssh-only"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges =  var.ssh_in_addresses
}

module "compute" {
  source   = "./modules/compute"
  for_each = var.compute

  compute_name  = each.key
  compute_image = "debian-cloud/debian-11"
  compute_size  = var.compute_size
  zone          = "${each.value.region}-${each.value.zone}"
  tags          = concat(var.default_tags, each.value.extra_tags)
  region = each.value.region

  network = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet[each.value.region].name

  ssh_user =  var.ssh_user
  ssh_pub_key =  var.ssh_pub_key
  ssh_private_key = var.ssh_private_key

  metadata_startup_script = each.value.metadata_startup_script
}

module "gke" {
  source = "./modules/gke"
  depends_on = [ module.compute ]

  for_each = var.gke

  cluster_name = each.key
  region = each.value.region
  network = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet["lido"].id
  authorized_network =  "${module.compute["dirk1"].ip_address.address}/32"
}

resource "google_compute_router" "router" {
  name    = "router"
  project = var.project_id
  region  = var.gke.lido.region
  network = google_compute_network.vpc.name
}

resource "google_compute_address" "nat" {
  name         = "${var.project_id}-nat-ip"
  address_type = "EXTERNAL"
  region = var.gke.lido.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat"
  project                            = var.project_id
  region                             = var.gke.lido.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "MANUAL_ONLY"

  nat_ips = [google_compute_address.nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  subnetwork {
    name                    = "gke-lido-subnet"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "dirk" {
  depends_on = [ module.compute ]

  name    = "${var.project_id}-firewall-dirk-in"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["13141"]
  }

  target_tags   = ["firewall-dirk"]
  source_tags = ["mynetwork"]
  source_ranges = concat(["${google_compute_address.nat.address}/32"], [for key,value in module.compute: "${value.ip_address.address}/32"])
}

output "kubernetes_cluster_names" {
  value = {
    for key, cluster in module.gke : key => { name = cluster.kubernetes_cluster_name, host = cluster.kubernetes_cluster_host }
  }
}

output "compute_addresses" {
  value = {
    for key,value in module.compute: key => value.ip_address.address
  }
}

output "nat_address" {
  value = google_compute_address.nat.address
}

data "google_client_config" "default" {}

provider "kubernetes" {
  # Configuration options
  host = "https://${module.gke["lido"].kubernetes_cluster_host}"
  cluster_ca_certificate = base64decode(module.gke["lido"].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
  proxy_url = "http://localhost:${data.external.bastion[0].result.port}"
}

data "external" "bastion" {
  count   = 1
  program = ["python3", "${path.module}/start_proxy.py"]
  query = {
    project  = var.project_id
    zone     = "${module.compute["dirk1"].zone}"
    instance = "dirk1"
    ssh_user = var.ssh_user
    ssh_private_key = var.ssh_private_key
    ssh_extra_args = var.ssh_extra_args
    host = "https://${module.gke["lido"].kubernetes_cluster_host}"
  }
}

# Vouch 1
resource "kubernetes_config_map" "vouch1-config" {
  metadata {
    name = "vouch1-config"
  }

  data = {
    "vouch-ee.json" = "${file("${path.module}/config/vouch-ee.json")}"
    "vouch.yml" = "${file("${path.module}/config/vouch1.yml")}"
  }
}

resource "kubernetes_secret" "vouch1-secret" {
  metadata {
    name = "vouch1-secret"
  }

  data = {
    "vouch1.crt" = "${file("${path.module}/config/certs/vouch1.crt")}"
    "vouch1.key" = "${file("${path.module}/config/certs/vouch1.key")}"
    "dirk_authority.crt" = "${file("${path.module}/config/certs/dirk_authority.crt")}"
  }
}

resource "kubernetes_deployment" "vouch1" {
  metadata {
    name = "vouch1"
    labels = {
      vouch = "vouch1"
      app = "vouch"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        vouch = "vouch1"
      }
    }

    template {
      metadata {
        labels = {
          vouch = "vouch1"
        }
      }

      spec {
        container {
          image = "attestant/vouch:${var.vouch_tag}"
          name  = "vouch1"
          args = ["--base-dir=/config"]

          port {
            container_port = 18550
          }

          volume_mount {
            mount_path = "/config/vouch-ee.json"
            sub_path = "vouch-ee.json"
            name       = "config"
          }
          
          volume_mount {
            mount_path = "/config/vouch.yml"
            sub_path = "vouch.yml"
            name       = "config"
          }

          volume_mount {
            mount_path = "/config/certs/vouch1.crt"
            sub_path = "vouch1.crt"
            name       = "secret"
          }

          volume_mount {
            mount_path = "/config/certs/vouch1.key"
            sub_path = "vouch1.key"
            name       = "secret"
          }

          volume_mount {
            mount_path = "/config/certs/dirk_authority.crt"
            sub_path = "dirk_authority.crt"
            name       = "secret"
          }

          resources {
            limits = {
              cpu    = "1"
              memory = "2Gi"
            }

            requests = {
              cpu    = "1"
              memory = "2Gi"
            }
          }
        }

        volume {
          name = "config"

          config_map {
            name = "vouch1-config"
            default_mode = "0644"
          }
        }
        
        volume {
          name = "secret"

          secret {
            default_mode = "0644"
            secret_name = "vouch1-secret"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "external_dns" {

  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_cluster_role" "external_dns" {

  metadata {
    name = "external-dns"
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
  }
  
  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["endpoints"]
  }
  

  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["nodes"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns_viewer" {

  metadata {
    name = "external-dns-viewer"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "external-dns"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "external-dns"
  }
}

resource "kubernetes_deployment" "external_dns" {

  metadata {
    name = "external-dns"
  }

  spec {
    selector {
      match_labels = {
        app = "external-dns"
      }
    }

    template {
      metadata {
        labels = {
          app = "external-dns"
        }
      }

      spec {
        container {
          name  = "external-dns"
          image = "registry.k8s.io/external-dns/external-dns:v0.13.2"
          args  = ["--source=service", "--source=ingress", "--domain-filter=${var.cf_domain}", "--provider=cloudflare", "--registry=txt", "--txt-owner-id=${var.mev_subdomain}"]

          env {
            name  = "CF_API_KEY"
            value = var.cf_api_key
          }

          env {
            name  = "CF_API_EMAIL"
            value = var.cf_api_email
          }
        }

        service_account_name = "external-dns"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_manifest" "vouch_backend_config" {

  lifecycle {
    ignore_changes = all
  }

  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "mev-backend-config"
      namespace = "default"
    }
    spec = {
      healthCheck = {
         requestPath = "/eth/v1/builder/status"
       }
    }
  }
}

resource "kubernetes_service" "vouch1-mev" {

  metadata {
    name = "vouch1-mev"
    annotations = {
      "cloud.google.com/backend-config" = "{\"ports\": {\"80\":\"mev-backend-config\"}}"
    }
  }

  spec {
    port {
      # protocol    = "TCP"
      port        = 80
      target_port = 18550
      name = "mev"
      # name = "http"
      # port = 18550
    }

    selector = {
      vouch = "vouch1"
    }

    type = "NodePort"
  }
}

resource "kubernetes_cluster_role" "traefik_role" {
  metadata {
    name = "traefik-role"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services", "endpoints", "secrets"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses", "ingressclasses"]
  }

  rule {
    verbs      = ["update"]
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status"]
  }
}

resource "kubernetes_service_account" "traefik_account" {
  metadata {
    name = "traefik-account"
  }
}

resource "kubernetes_cluster_role_binding" "traefik_role_binding" {
  metadata {
    name = "traefik-role-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "traefik-account"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "traefik-role"
  }
}

resource "kubernetes_deployment" "traefik" {

  depends_on = [
    kubernetes_service_account.traefik_account
  ]

  metadata {
    name = "traefik"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "traefik"
      }
    }

    template {
      metadata {
        labels = {
          app = "traefik"
        }
      }

      spec {
        service_account_name = "traefik-account"
        
        container {
          name  = "traefik"
          image = "traefik:latest"
          args  = [
            "--log.level=DEBUG",
            # "--certificatesResolvers.letsencrypt.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory",
            "--providers.kubernetesingress",
            "--certificatesresolvers.letsencrypt.acme.dnschallenge=true",
            "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare",
            "--certificatesresolvers.letsencrypt.acme.email=${var.acme_email}",
            "--entrypoints.websecure.address=:443",
            "--entrypoints.websecure.http.tls=true",
            "--entrypoints.websecure.http.tls.certResolver=letsencrypt"
          ]

          port {
            name           = "websecure"
            container_port = 443
          }

          env {
            name  = "CLOUDFLARE_API_KEY"
            value = var.cf_api_key
          }

          env {
            name  = "CLOUDFLARE_EMAIL"
            value = var.cf_api_email
          }
        }
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "traefik_service" {

  metadata {
    name = "traefik-service"

    annotations = {
      "external-dns.alpha.kubernetes.io/hostname" = "${var.mev_subdomain}.${var.cf_domain}"
      "external-dns.alpha.kubernetes.io/ttl" = 120
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 443
      target_port = 443
      name = "websecure"
    }

    selector = {
      app = "traefik"
    }

    type = "LoadBalancer"

    load_balancer_source_ranges = concat(var.vouch_https_in_addresses, ["${google_compute_address.nat.address}/32"])
  }
}

resource "kubernetes_ingress_v1" "vouch_ingress" {
  metadata {
    name = "vouch-ingress"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
    }
  }

  spec {
    rule {
      host = "${var.mev_subdomain}.${var.cf_domain}"
      http {
        path {
          backend {
            service {
              name = "vouch1-mev"

              port {
                name = "mev"
              }
            }
          }
        }

        path {
          backend {
            service {
              name = "whoami"
              port {
                name = "http"
              }
            }
          }

          path = "/foo"
        }
      }
    }
  }
}

# Prometheus

resource "kubernetes_config_map" "prometheus-config" {
  metadata {
    name = "prometheus-config"
  }

  data = {
    "prometheus.yml" = "${file("${path.module}/prometheus.yml")}${file("${path.module}/prometheus-custom.yml")}"
  }
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name = "prometheus"
    labels = {
      app = "prometheus"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          image = "ubuntu/prometheus:latest"
          name  = "prometheus"

          volume_mount {
            mount_path = "/etc/prometheus/prometheus.yml"
            name       = "config"
            sub_path = "prometheus.yml"
          }
        }

        volume {
          name = "config"

          config_map {
            name = "prometheus-config"
            default_mode = "0644"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vouch_metrics" {

  metadata {
    name = "vouch-metrics"
  }

  spec {
    port {
      name        = "vouch-metrics"
      port        = 8081
    }

    selector = {
      vouch = "vouch1"
    }

    type = "NodePort"
  }
}

resource "kubernetes_deployment" "whoami" {
  metadata {
    name = "whoami"

    labels = {
      app = "traefiklabs"

      name = "whoami"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "traefiklabs"

        task = "whoami"
      }
    }

    template {
      metadata {
        labels = {
          app = "traefiklabs"

          task = "whoami"
        }
      }

      spec {
        container {
          name  = "whoami"
          image = "traefik/whoami"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "whoami" {
  metadata {
    name = "whoami"
  }

  spec {
    port {
      name = "http"
      port = 80
    }

    selector = {
      app = "traefiklabs"

      task = "whoami"
    }

    type = "NodePort"
  }
}
