#!/usr/bin/env bash

# Kill old SSH sessions
kill $(ps aux | grep '[:]localhost:8888 -N -q -f' | awk '{print $2}')

# GCloud
if gcloud config configurations list | grep -q "^$(basename $(pwd))"; then
    echo "Activate the config named $(basename $(pwd))"
    gcloud config configurations activate $(basename $(pwd))
    echo "Set quota project to $(basename $(pwd))"
    gcloud auth application-default set-quota-project $(basename $(pwd))
else
    echo "Create a config named $(basename $(pwd)) with matching Google project; don't set a default compute region"
    gcloud init
fi

active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)

if gcloud auth application-default print-access-token &> /dev/null; then
    echo "Application default credentials are set."
else
    echo "Application default credentials are not yet set."
    gcloud auth application-default login
fi

if [[ -z "$active_account" ]]
then
    echo "No interactive gcloud login yet"
    gcloud auth login
else
    echo "Active gcloud account is: $active_account"
fi

# Terraform
terraform init -backend-config=backend.conf -reconfigure -upgrade
