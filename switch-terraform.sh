#!/usr/bin/env bash

# Kill old SSH sessions
kill $(ps aux | grep '[:]localhost:8888 -N -q -f' | awk '{print $2}')

# Glcoud
echo "Choose the right project for this folder; don't set a default compute environ"
gcloud init
gcloud auth application-default login

# Terraform
terraform init -backend-config=backend.conf -reconfigure
