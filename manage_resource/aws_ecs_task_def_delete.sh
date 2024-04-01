#!/bin/bash

# To run this you need a Mac or Linux and to install the AWS CLI:
# https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html
#
# Description:
# This script uses the AWS CLI tool to connect to the specified AWS region to de-resgister
# and delete ECS Task Definitions. This was used when hundreds of ECS clusters and services
# were created and caused a billing issues.


# The region we are working with.
region="eu-north-1"

# Get the list of task definitions in the region.
task_definitions=$(aws ecs list-task-definitions --region $region --output json | jq -r '.taskDefinitionArns[] | split("/") | .[-1]')
#task_definitions="BLHWdviIPmgPiIthOUiuezSjy:1 CkjrIsgCmxgljygIiWqubxYDg:1"

task_definitions_number=$(echo $task_definitions | wc -w | tr -d ' ')

# I want to be sure this is ready to run before executing.
echo -e "There are $task_definitions_number task definitions in the region $region.\n"

echo -e "Do you want to proceed with the task definitions removal? (Y/N)\n"
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
    ./aws_ecs_task_def_delete.sh
    exit 1
fi

# Variables to keep track of what was being deregistered and deleted in the task definitions
task_defs_number=0
delete_number=0

# Loop through each task definitions then deregister and delete when deresgitered.
for task_definition in $task_definitions
do
  task_defs_number=$((task_defs_number + 1))
  delete_number=$((delete_number + 1))

  # Time to deregister the task definition
  aws ecs deregister-task-definition --task-definition $task_definition --region $region > /dev/null 2>&1
  echo "The Task Definition $task_definition has been deregistered in region $region."
  sleep 1 # Break and let the previous command cook
  # Delete the task definition once deregistered
  aws ecs delete-task-definitions --task-definition $task_definition --region $region > /dev/null 2>&1
  echo -e "The Task Definition $task_definition has been deleted/made inactive in region $region\n"
  sleep 1 # Before proceeding let the last process cook also
done

echo "Total number of Task Definitions deregistered was $task_defs_number in region $region."
echo "Total number of Task Definitions deleted was $delete_number in region $region."
