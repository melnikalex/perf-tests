#!/bin/bash
set -u
set -e
set -x

USAGE="./startup.sh <config-url> <config-name> <kubeconfig-name> [cleanup]"
if [ "$#" -lt 3 ]; then
    echo "USAGE:"
    echo $USAGE
    exit 1
fi

CONFIG_URL=$1
CONFIG_NAME=$2
KUBECONFIG_NAME=$3

echo "getting task metadata..."
curl ${ECS_CONTAINER_METADATA_URI_V4}/task
TASK_ID=$(basename $(curl ${ECS_CONTAINER_METADATA_URI_V4}/task | jq -r .TaskARN))
CLUSTER=$(curl ${ECS_CONTAINER_METADATA_URI_V4}/task | jq -r .Cluster)

echo "copying config from s3..."
aws s3 cp --recursive $CONFIG_URL config/

##### CLEANUP PATH OF THE SCRIPT
if [ "$#" -eq 4 ]; then
    if [ $4 != "cleanup" ]; then
        echo "invalid 4th argument to script: $4"
        echo "USAGE:"
        echo $USAGE
        exit 1
    fi

    echo "cleaning up orphaned namespaces..."
    kubectl --kubeconfig config/$KUBECONFIG_NAME get ns | cut -d' ' -f1 > /tmp/namespaces
    aws ecs list-tasks --cluster $CLUSTER > /tmp/tasks
    for n in $(cat /tmp/namespaces); do
        if echo $n | grep -v "test-" > /dev/null; then
            # if the namespace isn't called test-* then we skip it/continue
            continue
        fi

        task_id=$(echo $n | cut -d"-" -f2)
        if cat /tmp/tasks | grep $task_id > /dev/null; then
            continue
        else
            kubectl --kubeconfig config/$KUBECONFIG_NAME delete ns $n &
            echo "Deleting ns $n"
        fi
        sleep 100
    done
    sleep 60

    exit 0
fi

##### REGULAR PATH OF THE SCRIPT

# prefix namespaces with ECS_TASK_ID so that our cleanup task knows which namespaces to delete
sed -i -e "s/ECS_TASK_ID/$TASK_ID/" config/$CONFIG_NAME

echo "running clusterloader..."
ENABLE_EXEC_SERVICE=false ./clusterloader \
    --kubeconfig config/$KUBECONFIG_NAME \
    --testconfig config/$CONFIG_NAME \
    --provider eks \
    -v 2 \
    --nodes 1000
