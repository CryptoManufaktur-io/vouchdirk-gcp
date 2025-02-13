#!/usr/bin/env bash

# Kill old SSH sessions
kill $(ps aux | grep '[:]localhost:8888 -N' | awk '{print $2}')

project_id=$(grep -o 'project_id\s*=\s*"[^"]*"' terraform.tfvars | cut -d'"' -f2)
# folder_name=$(basename $(pwd))
folder_name=$project_id

# GCloud
if gcloud config configurations list | grep -q "^$folder_name"; then
    echo "Activate the config named $folder_name"
    gcloud config configurations activate $folder_name
#    echo "Set quota project to $folder_name"
#    gcloud auth application-default set-quota-project $folder_name
else
    echo "Create a config named $folder_name with matching Google project; don't set a default compute region"
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
