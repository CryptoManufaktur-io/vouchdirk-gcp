# vouchdirk-gcp

This terraform project creates all the infrastructure necessary for [vouchdirk-docker](https://github.com/CryptoManufaktur-io/vouchdirk-docker/) in GCP.

The infrastructure includes:

- 5 dirk VMs with reserved IP addresses
- 1 GKE [Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#what-is-autopilot) Private Cluster, running:
    - Vouch
    - Grafana agent (for prometheus metrics and logs)
    - ExternalDNS
    - Traefik
- dirk firewall to allow port 13141 traffic from the other dirks and from vouch
- ssh firewall to allow ssh traffic from the defined addresses
- 5 subnets for the dirks
- 1 subnet for the GKE cluster
- 1 NAT gateway with reserved IP address for the Pods to connect to the internet

The GKE cluster uses Authorized Networks and only traffic from the `dirk1` VM has access to the Control Plane.

In order for terraform to create the multiple Kubernetes resources, an SSH tunnel is created to `dirk1` which then proxies the traffic to the Kubernetes Control Plane.

The tunnel is achieved by an External Data Source which runs the necessary shell commands.

Vouch's MEV-boost service is exposed via Traefik on a Service with a Load Balancer behind a firewall.

## Requirements

- Cloudflare Global API keys.
- GCP Account with billing enabled
- GCP Project with:
    - [Cloud Logging API](https://console.cloud.google.com/apis/library/logging.googleapis.com) enabled
    - [Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com) enabled
    - [Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com) enabled
    - [Cloud Storage Bucket](https://console.cloud.google.com/storage/browser) to store Terraform state
- [Terraform cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [kubectl cli](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [gcloud cli](https://cloud.google.com/sdk/docs/install-sdk#installing_the_latest_version)

## Setup
- Generate the [vouchdirk-docker](https://github.com/CryptoManufaktur-io/vouchdirk-docker/#initial-setup) `config/` folder and copy it to the root of project folder.
- Initialize gcloud:
```shell
gcloud init
gcloud auth application-default login
gcloud auth login
```
- Copy `backend.conf.sample` to `backend.conf` and set the Bucket name and Prefix for Terraform state data.
- Copy `terraform.tfvars.sample` to `terraform.tfvars` and modify as needed.
- Copy `prometheus-remoteurl.yml.sample` to `prometheus-remoteurl.yml` and modify as needed. Grafana agent will scrape prometheus metrics and remote write to a server with the details provided on this file.
- Copy `promtail-lokiurl.yml.sample` to `promtail-lokiurl.yml` and modify as needed. Grafana agent will collect logs of pods running in the kubernetes and send them to remote loki using the details on this file.
- Initialize terraform:
```shell
terraform init -backend-config=backend.conf
```

When switching between multiple copies of this project for multiple environments, you can use `switch-terraform.sh`.

- Deploy

On initial deploy, use
```shell
./deploy.sh
```

Subsequent changes come in with
```shell
terraform apply
```

## Using kubectl

In order to create the ssh tunnel when needed, you can execute `terraform plan`.

You can then use the environment variable `HTTPS_PROXY` with the kubectl command for the requests to be tunneled and proxied.

E.g:

```shell
HTTPS_PROXY=localhost:8888 kubectl get pods
```

Once finished, you can run `killall ssh` to kill the ssh tunnel or you can find the specific process ID and kill it if you need to keep other ssh processes running.

## Development

- Install dependencies:
```shell
npm install
```
- Install pre-commit: https://pre-commit.com/#installation
- Install git hook scripts:
```shel
pre-commit install
```
