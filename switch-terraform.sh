#!/usr/bin/env bash

# Kill old SSH sessions
kill $(ps aux | grep '[:]localhost:8888 -N -q -f' | awk '{print $2}')

# GCloud
if gcloud config configurations list | grep -q "^$(basename $(pwd))"; then
    echo "Activate the config named $(basename $(pwd))"
    gcloud config configurations activate $(basename $(pwd))
else
    echo "Create a config named $(basename $(pwd)) with matching Google project; don't set a default compute region"
    gcloud init
fi
if ! gcloud auth list | grep -q cryptomanufaktur.io; then
    gcloud auth application-default login
fi

# Terraform
terraform init -backend-config=backend.conf -reconfigure -upgrade
