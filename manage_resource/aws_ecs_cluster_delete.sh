#!/bin/bash
#
# To run this you need a Mac or Linux and to install the AWS CLI:
# https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html
#
# Description:
# This script uses the AWS CLI tool to connect to the specified AWS region and delete the
# ECS Services and Cluster instances. This was used when hundreds of ECS clusters and services
# were created and caused a billing issues.

# The region we are working with.
region="eu-west-1"

# Get the cluster nodes in the region.
cluster_nodes=$(aws ecs list-clusters --region $region --output json | jq -r '.clusterArns[] | split("/") | .[-1]')
#cluster_nodes="tMsBBGNfqrvscbsdiBdKTmnRQ ejQjSFDgAyOiNTJJLKEcgerzH DkBSauggBOjblXJptgtDppqhv WKFHvgmUMyCqGZVhyuLHquNCE ExxbJEDxARgVTYmzsAOrcYFXR" # test line to confirm script works as expected.

# Gather that total number of clusters and output it
cluster_number=$(echo $cluster_nodes | wc -w | tr -d ' ')

# I want to be sure this is ready to run before executing.
echo -e "There are $cluster_number clusters in the region $region.\n"

echo -e "Do you want to proceed with the cluster and service removal? (Y/N)\n"
read -r response

# Check for upper case or lower case and convert to upper case
response=$(echo "$response" | tr '[:lower:]' '[:upper:]')

if [ "$response" = "Y" ]; then
    echo -e "Continuing...\n"
    # If yes continue
elif [ "$response" = "N" ]; then
    echo "Cancelling..."
    # If no cancel
    exit 0
else
    # Anything else make them do it again
    echo -e "Invalid input. Please enter Y or N.\n"
    ./aws_ecs_cluster_delete.sh
    exit 1
fi

# Variables used for testing the accurate count of services and clusters
number=0
service_number=0

# Loop through each cluster and determine if there is a service, if there is delete the service and then delete the cluster... If there is no service, delete the cluster 
for cluster_node in $cluster_nodes
do
  number=$((number + 1))
  cluster_services=$(aws ecs list-services --region $region --cluster $cluster_node --output json | jq -r '.serviceArns[] | split("/") | .[-1]')

  if [ -n "$cluster_services" ]; then
    echo "Cluster $cluster_node has service $cluster_services"
    # Added another for loop in case there is more than one service listed.
    for cluster_service in $cluster_services
    do
      service_number=$((service_number + 1))
      # Cluster service delete command here.
      aws ecs delete-service --cluster $cluster_node --service $cluster_service --region $region --force > /dev/null 2>&1
      echo "The cluster service $cluster_service on cluster $cluster_node has been deleted."
    done
    # Delete the cluster here if there are no services.
    aws ecs delete-cluster --cluster $cluster_node --region $region > /dev/null 2>&1
    echo -e "The cluster $cluster_node has been deleted.\n"
    unset cluster_services
  else
    echo "Cluster $cluster_node has no service"
    # Delete the cluster here if there are no services.
    aws ecs delete-cluster --cluster $cluster_node --region $region > /dev/null 2>&1
    echo -e "The cluster $cluster_node has been deleted.\n"
  fi
  sleep 1 # take a break and think about what you did before proceeding.
done

echo "Total number of cluster nodes deleted was $number in region $region."
echo "Total number of cluster services deleted was $service_number in region $region."
