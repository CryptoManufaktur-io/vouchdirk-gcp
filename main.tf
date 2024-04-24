resource "google_compute_firewall" "ssh" {
  name    = "${var.project_id}-firewall-bastion-ssh-only"
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

  compute_name  = "${var.hostname_prefix}-${each.value.hostname}"
  compute_image = var.compute_image
  compute_size  = var.compute_size
  zone          = "${each.value.region}-${each.value.zone}"
  tags          = concat(var.default_tags, each.value.extra_tags)
  region        = each.value.region

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

resource "google_compute_firewall" "exiter" {
  name    = "${var.project_id}-firewall-exiter-in"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags   = ["firewall-exiter"]
  source_ranges =  var.exiter_https_in_addresses
}

output "kubernetes_cluster_names" {
  value = {
    for key, cluster in module.gke : key => { name = cluster.kubernetes_cluster_name, host = cluster.kubernetes_cluster_host }
  }
}

output "kubernetes_cluster_region" {
  value = module.gke["lido"].kubernetes_cluster_region
}

output "compute_addresses" {
  value = {
    for key,value in module.compute: key => value.ip_address.address
  }
}

output "nat_address" {
  value = google_compute_address.nat.address
  description = "Outgoing NAT address of Vouch and Dirk"
}

output "mev_address" {
  value = kubernetes_service.traefik_service.status.0.load_balancer.0.ingress.0.ip
  description = "MEV endpoint public IP, use for A record"
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
    instance = module.compute["dirk1"].name
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
    "dirk_authority.crt" = "${file("${path.module}/config/certs/dirk_authority.crt")}",
    "tempo_client.crt" = "${file("${path.module}/config/certs/tempo_client.crt")}",
    "tempo_client.key" = "${file("${path.module}/config/certs/tempo_client.key")}",
    "tempo_authority.crt" = "${file("${path.module}/config/certs/tempo_authority.crt")}",
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

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].security_context,
      spec[0].template[0].spec[0].security_context,
      spec[0].template[0].spec[0].toleration
    ]
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
        annotations = {
          "vouch.yml" = filesha256("${path.module}/config/vouch1.yml")
          "vouch-ee.json" = filesha256("${path.module}/config/vouch-ee.json")
          "vouch1.crt" = filesha256("${path.module}/config/certs/vouch1.crt")
          "vouch1.key" = filesha256("${path.module}/config/certs/vouch1.key")
          "dirk_authority.crt" = filesha256("${path.module}/config/certs/dirk_authority.crt")
          "tempo_client.crt" = filesha256("${path.module}/config/certs/tempo_client.crt")
          "tempo_client.key" = filesha256("${path.module}/config/certs/tempo_client.key")
          "tempo_authority.crt" = filesha256("${path.module}/config/certs/tempo_authority.crt")
          "promtail.io/logs" = true
        }
      }

      spec {
        hostname = "${var.hostname_prefix}-vouch1"
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

          volume_mount {
            mount_path = "/config/certs/tempo_client.crt"
            sub_path = "tempo_client.crt"
            name       = "secret"
          }

          volume_mount {
            mount_path = "/config/certs/tempo_client.key"
            sub_path = "tempo_client.key"
            name       = "secret"
          }

          volume_mount {
            mount_path = "/config/certs/tempo_authority.crt"
            sub_path = "tempo_authority.crt"
            name       = "secret"
          }

          resources {
            limits = {
              cpu    = "0.25"
              memory = var.vouch_mem
              ephemeral-storage = "100Mi"
            }

            requests = {
              cpu    = "0.25"
              memory = var.vouch_mem
              ephemeral-storage = "100Mi"
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

resource "kubernetes_persistent_volume_claim" "traefik_pvc" {
  metadata {
    name      = "traefik-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Mi"
      }
    }
  }
}

resource "kubernetes_deployment" "traefik" {

  depends_on = [
    kubernetes_service_account.traefik_account
  ]

  metadata {
    name = "traefik"
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].security_context,
      spec[0].template[0].spec[0].security_context,
      spec[0].template[0].spec[0].toleration
    ]
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
        annotations = {
          "promtail.io/logs" = true
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
            "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json",
            "--entrypoints.websecure.address=:443",
            "--entrypoints.websecure.http.tls=true",
            "--entrypoints.websecure.http.tls.certResolver=letsencrypt",
            "--metrics",
            "--metrics.prometheus"
          ]

          port {
            name           = "websecure"
            container_port = 443
          }

          env {
            name  = "CF_DNS_API_TOKEN"
            value = var.cf_api_token
          }

          volume_mount {
            mount_path = "/letsencrypt"
            name      = "traefik-certs"
          }

          resources {
            limits = {
              cpu    = "0.25"
              memory = "0.5Gi"
              ephemeral-storage = "10Mi"
            }

            requests = {
              cpu    = "0.25"
              memory = "0.5Gi"
              ephemeral-storage = "10Mi"
            }
          }
        }
        volume {
          name = "traefik-certs"
          persistent_volume_claim {
            claim_name = "traefik-pvc"
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

    load_balancer_source_ranges = var.vouch_https_in_addresses
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
      }
    }
  }
}

# Grafana agent
resource "kubernetes_cluster_role" "grafana-agent-monitoring-cluster-role" {
  metadata {
    name = "grafana-agent-monitoring-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods", "nodes/metrics"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs = ["get"]
  }
}

resource "kubernetes_service_account" "grafana-agent-monitoring-service-account" {
  metadata {
    name = "grafana-agent-monitoring-service-account"
  }
}

resource "kubernetes_cluster_role_binding" "grafana-agent-monitoring-cluster-role-binding" {
  metadata {
    name = "grafana-agent-monitoring-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "grafana-agent-monitoring-cluster-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "grafana-agent-monitoring-service-account"
    namespace = "default"
  }
}

resource "kubernetes_config_map" "grafana-agent-entrypoint-config" {
  metadata {
    name = "grafana-agent-entrypoint-config"
  }

  data = {
    "grafana-agent-entrypoint.sh" = "${file("${path.module}/grafana-agent-entrypoint.sh")}"
  }
}

resource "kubernetes_config_map" "grafana-agent-promtail-config" {
  metadata {
    name = "grafana-agent-promtail-config"
  }

  data = {
    "promtail.yml" = "${file("${path.module}/promtail.yml")}"
  }
}

resource "kubernetes_config_map" "grafana-agent-promtail-lokiurl-config" {
  metadata {
    name = "grafana-agent-promtail-lokiurl-config"
  }

  data = {
    "promtail-lokiurl.yml" = "${file("${path.module}/promtail-lokiurl.yml")}"
  }
}

resource "kubernetes_config_map" "grafana-agent-prometheus-config" {
  metadata {
    name = "grafana-agent-prometheus-config"
  }

  data = {
    "prometheus.yml" = "${file("${path.module}/prometheus.yml")}"
  }
}

resource "kubernetes_config_map" "grafana-agent-prometheus-remoteurl-config" {
  metadata {
    name = "grafana-agent-prometheus-remoteurl-config"
  }

  data = {
    "prometheus-remoteurl.yml" = "${file("${path.module}/prometheus-remoteurl.yml")}"
  }
}

resource "kubernetes_persistent_volume_claim" "grafana-agent-pvc" {
  metadata {
    name      = "grafana-agent-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "grafana-agent" {
  metadata {
    name = "grafana-agent"
    labels = {
      app = "grafana-agent"
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].security_context,
      spec[0].template[0].spec[0].security_context,
      spec[0].template[0].spec[0].toleration
    ]
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "grafana-agent"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana-agent"
        }
        annotations = {
          "grafana-agent-entrypoint.sh" = filesha256("${path.module}/grafana-agent-entrypoint.sh")
          "promtail.yml" = filesha256("${path.module}/promtail.yml")
          "promtail-lokiurl.yml" = filesha256("${path.module}/promtail-lokiurl.yml")
          "prometheus-remoteurl.yml" = filesha256("${path.module}/prometheus-remoteurl.yml")
          "prometheus.yml" = filesha256("${path.module}/prometheus.yml")
          "promtail.io/logs" = true
        }
      }

      spec {
        service_account_name = "grafana-agent-monitoring-service-account"
        container {
          image = "grafana/agent:latest"
          name  = "grafana-agent"
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path = "spec.nodeName"
              }
            }
          }
          command = ["/usr/bin/bash", "-c", "/configs/grafana-agent-entrypoint.sh ${var.project_id}-vouch"]

          volume_mount {
            mount_path = "/configs/grafana-agent-entrypoint.sh"
            name       = "grafana-agent-entrypoint-config"
            sub_path = "grafana-agent-entrypoint.sh"
          }
          volume_mount {
            mount_path = "/configs/promtail.yml"
            name       = "grafana-agent-promtail-config"
            sub_path = "promtail.yml"
          }
          volume_mount {
            mount_path = "/configs/promtail-lokiurl.yml"
            name       = "grafana-agent-promtail-lokiurl-config"
            sub_path = "promtail-lokiurl.yml"
          }
          volume_mount {
            mount_path = "/configs/prometheus.yml"
            name       = "grafana-agent-prometheus-config"
            sub_path = "prometheus.yml"
          }
          volume_mount {
            mount_path = "/configs/prometheus-remoteurl.yml"
            name       = "grafana-agent-prometheus-remoteurl-config"
            sub_path = "prometheus-remoteurl.yml"
          }
          volume_mount {
            mount_path = "/etc/agent/data"
            name       = "grafana-agent-data"
          }
          volume_mount {
            mount_path = "/var/log/pods"
            name       = "grafana-agent-pods"
            read_only = true
          }
          resources {
            limits = {
              cpu    = "0.5"
              memory = "1Gi"
              ephemeral-storage = "10Mi"
            }

            requests = {
              cpu    = "0.5"
              memory = "1Gi"
              ephemeral-storage = "10Mi"
            }
          }
        }

        volume {
          name = "grafana-agent-data"
          persistent_volume_claim {
            claim_name = "grafana-agent-pvc"
          }
        }
        volume {
          name = "grafana-agent-entrypoint-config"

          config_map {
            name = "grafana-agent-entrypoint-config"
            default_mode = "0775"
          }
        }
        volume {
          name = "grafana-agent-promtail-config"

          config_map {
            name = "grafana-agent-promtail-config"
            default_mode = "0644"
          }
        }
        volume {
          name = "grafana-agent-promtail-lokiurl-config"

          config_map {
            name = "grafana-agent-promtail-lokiurl-config"
            default_mode = "0644"
          }
        }
        volume {
          name = "grafana-agent-prometheus-config"

          config_map {
            name = "grafana-agent-prometheus-config"
            default_mode = "0644"
          }
        }
        volume {
          name = "grafana-agent-prometheus-remoteurl-config"

          config_map {
            name = "grafana-agent-prometheus-remoteurl-config"
            default_mode = "0644"
          }
        }
        volume {
          name = "grafana-agent-pods"

          host_path {
            path = "/var/log/pods"
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

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "traefik_metrics" {

  metadata {
    name = "traefik-metrics"
  }

  spec {
    port {
      name        = "traefik-metrics"
      port        = 8080
      protocol = "TCP"
    }

    selector = {
      app = "traefik"
    }

    type = "ClusterIP"
  }
}

# kube-state-metrics
resource "kubernetes_cluster_role" "kube-state-metrics-cluster-role" {
  metadata {
    name = "kube-state-metrics-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods", "nodes/metrics"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs = ["get"]
  }
}

resource "kubernetes_service_account" "kube-state-metrics-service-account" {
  metadata {
    name = "kube-state-metrics-service-account"
  }
}

resource "kubernetes_cluster_role_binding" "kube-state-metrics-cluster-role-binding" {
  metadata {
    name = "kube-state-metrics-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kube-state-metrics-cluster-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kube-state-metrics-service-account"
    namespace = "default"
  }
}

resource "kubernetes_deployment" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].security_context,
      spec[0].template[0].spec[0].security_context,
      spec[0].template[0].spec[0].toleration
    ]
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kube-state-metrics"
      }
    }

    template {
      metadata {
        labels = {
          app = "kube-state-metrics"
        }
      }

      spec {
        service_account_name = "kube-state-metrics-service-account"

        container {
          name  = "kube-state-metrics"
          image = "k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.8.2"
          args  = [
            "--resources=pods,deployments,nodes",
            "--node=",
            "--port=8080"
          ]

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "0.25"
              memory = "0.5Gi"
              ephemeral-storage = "10Mi"
            }

            requests = {
              cpu    = "0.25"
              memory = "0.5Gi"
              ephemeral-storage = "10Mi"
            }
          }
        }
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "kube_state_metrics" {

  metadata {
    name = "kube-state-metrics"
  }

  spec {
    port {
      name        = "kube-state-metrics"
      port        = 8080
      protocol = "TCP"
    }

    selector = {
      app = "kube-state-metrics"
    }

    type = "ClusterIP"
  }
}
