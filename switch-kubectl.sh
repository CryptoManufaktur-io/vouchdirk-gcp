#!/usr/bin/env bash

cluster_region=$(echo $(terraform output -raw kubernetes_cluster_region))
gcloud container clusters get-credentials lido --region=$cluster_region
