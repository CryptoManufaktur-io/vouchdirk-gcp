#!/usr/bin/env bash
set -e

# Deploy only the VPC and VMS
terraform apply -target=module.compute -target=google_compute_firewall.ssh

# Deploy the GKE Cluster.
terraform apply -target=module.gke

# Deploy the BackendConfig for health checks.
terraform apply -target=kubernetes_manifest.vouch_backend_config

# Kill the existing ssh session to the dirk1 proxy.
kill $(ps aux | grep '[:]localhost:8888 -N -q -f' | awk '{print $2}')

# Deploy everything else.
terraform apply
