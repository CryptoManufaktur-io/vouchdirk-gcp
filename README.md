# GCP

Repository to house all GCP related resources for blockchain infrastructure.

## What is GCP Autopilot

* Autopilot is a managed Google Kubernetes Engine (GKE) that is designed to reduce the operational cost of managing clusters, optimize your clusters for production, and yield higher workload availability.

* Autopilot GKE provisions and manages the cluster's underlying infrastructure, including nodes and node pools, giving you an optimized cluster with a hands-off experience.

* GKE Autopilot can be enabled for your Kubernetes cluster by adding the variable `enable_autopilot = true` to your GKE Terraform configuration.

## Terraform

* You need to initialize terraform. For shared use we use a remote backend saved in s3 compatible storage. Copy `backend_template.conf` to `backend.conf` and update as required. Then initialize terraform using `terraform init -backend-config=backend.conf`

* The repository is created with Terraform modules.

* The `modules` folder are the resources needed for the project.

* You need to change configuration as needed. For the different resources to provision, just copy `template_template.tfvars` to `template.tfvars` and update it as required.

* To provision the resources in your folder, **make sure you are in the `root` folder**, then just do `terraform apply`.

## Google SDK

* **Google SDK commands sheet** <https://gist.github.com/pydevops/cffbd3c694d599c6ca18342d3625af97>

* **Google Cloud SDK:** command line utility for managing Google Cloud Platform resources.

* Install Google SDK: <https://cloud.google.com/sdk/docs/install-sdk>

* Initialize the gcloud environment:  `gcloud init`
* You’ll be able to connect your Google account with the gcloud environment by following the on-screen instructions in your browser.

* You can also intiliaze your environment with the following command: **example** `gcloud auth application-default login`

* Verify your account and project. `gcloud config list`

* After your provision the GKE cluster with `terraform apply` run the following command to retrieve the access credentials for your cluster and automatically configure. **example** `gcloud container clusters get-credentials lido --region asia-northeast1`

* Finally set the context of the cluster to the desired cluster. **example** `kubectl config use-context my-cluster-name`
