# Switch existing compute instance boot disks in a project to pd-ssd
# Does not confirm, use with caution!
# Script is meant as a fix for legacy deployments, only.

#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1+x}" ]; then
    echo "This script requires one argument"
    echo "./hdd-to-ssd.sh google_project_id"
    exit 1
fi

# Set project id
PROJECT_ID="$1"

instances=$(gcloud compute instances list --project=$PROJECT_ID --format="csv[no-heading](name,zone)")
echo "Instances to be changed:"
echo "$instances"
echo

echo "$instances" | while IFS=',' read -r instance zone; do
  disks=$(gcloud compute instances describe $instance --project=$PROJECT_ID --zone=$zone --format="value(disks.source.basename())")
  num_disks=$(echo "$disks" | wc -w)

  if [[ $num_disks -ne 1 ]]; then
    echo "This instance has $num_disks, which is unexpected. The script only knows how to handle one disk. Skipping."
    continue
  fi
  
  disk_type=$(gcloud compute disks describe $disks --project=$PROJECT_ID --zone=$zone --format="value(type.basename())")
  if [ ! "${disk_type}" = "pd-standard" ]; then
    echo "Disk $disks is of type $disk_type. This script only migrates pd-standard. Skipping."
    continue
  fi
  echo "Will switch $disk_type disk $disks for instance $instance in zone $zone to pd-ssd"
  echo
  gcloud compute instances stop $instance --project=$PROJECT_ID --zone=$zone
  gcloud compute disks snapshot $disks --project=$PROJECT_ID --zone=$zone --snapshot-names=${instance}-snapshot-hdd
  echo "Creating new disk from snapshot"
  gcloud compute disks create ${disks}-ssd --project=$PROJECT_ID --zone=$zone --source-snapshot=${instance}-snapshot-hdd --type=pd-ssd
  echo "Detach the HDD disk"
  gcloud compute instances detach-disk $instance --project=$PROJECT_ID --zone=$zone --disk=$disks
  echo "Attach the SSD disk"
  gcloud compute instances attach-disk $instance --project=$PROJECT_ID --zone=$zone --disk=${disks}-ssd --boot
  echo "Set disk to auto-delete"
  gcloud compute instances set-disk-auto-delete $instance --project=$PROJECT_ID --disk=${disks}-ssd --auto-delete
  gcloud compute instances start $instance --project=$PROJECT_ID --zone=$zone
  echo "Delete the HDD disk"
  gcloud compute disks delete $disks --project=$PROJECT_ID --zone=$zone --quiet
  echo "Sleep for a minute"
  sleep 60
  echo
done
