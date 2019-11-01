#!/bin/bash

# Script to count tags in docker registry"
# User is required to input registry credentials or validate with cloud provider CLI
# Ex. aws ecr get-login
## Count tags

count_unique_tags() {
    # Count unique tags in a Docker registry
    read -p "Enter type of container registry (awsecr, dockerhub): " REGISTRY_TYPE
    case $REGISTRY_TYPE in
    ## AWS ECR count
    # Assume the user is able to authenticate with aws ecr get-login
        awsecr)
        read -p "AWS ECR Region: " REGION
        $(aws ecr get-login --no-include-email --region ${REGION})
        TAG_COUNT=0
        aws ecr describe-repositories | jq -c -r '.repositories[].repositoryName' | { while read REPOSITORY_NAME; do
            REPO_TAGS=`aws ecr describe-images --repository-name "${REPOSITORY_NAME}" | jq '.imageDetails | length'`
            echo "Repository name: "${REPOSITORY_NAME}", Unique tag count: ${REPO_TAGS}"
            TAG_COUNT=$((TAG_COUNT + ${REPO_TAGS}))
        done
        echo "Total tags: "${TAG_COUNT}
        }
        ;;

    ## DockerHub
    # Assume the user is able to authenticate with Docker credentials
        dockerhub)
        read -p "DockerHub username: " USERNAME
        echo -n "DockerHub password: "
        read -s PASSWORD
        echo ""
        read -p "DockerHub organization, username, or repository. Ex. anchore, jvalance, consul: " DOCKER_ORG
        read -p "Is this repository in the DockerHub library (Ex. library/ubuntu, library/consul)? yes or no: " DOCKER_LIB

        DOCKERHUB_URL="https://hub.docker.com"

        TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${USERNAME}'", "password": "'${PASSWORD}'"}' ${DOCKERHUB_URL}/v2/users/login/ | jq -r .token)
        if [ "${TOKEN}" == "null" ]
        then
            echo "Login token incorrect, try again."
            exit
        else
            if [ "${DOCKER_LIB}" == "yes" ] || [ "${DOCKER_LIB}" == "y" ] || [ "${DOCKER_LIB}" == "Yes" ]
            then
            ## All container images inside DockerHub library
            ## Ex. library/consul or library/ubuntu
                UNIQUE_IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" ${DOCKERHUB_URL}/v2/repositories/library/${DOCKER_ORG}/tags/?page_size=100 | jq -r -c '[.results[] | {name, digest: .images[].digest}] | unique_by(.digest)')
                REPO_TAG_COUNT=0
                for j in $(echo "${UNIQUE_IMAGE_TAGS}" | jq -r '.[] | @base64'); 
                do
                    ((REPO_TAG_COUNT++))
                done
                echo "Repository name: library/"${DOCKER_ORG}", Unique tag count: $REPO_TAG_COUNT"
            else
            ## Organization or Username repositories
            ## Ex. anchore or jvalance
                REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" ${DOCKERHUB_URL}/v2/repositories/${DOCKER_ORG}/?page_size=100 | jq -r '.results | .[] | .name')
                TOTAL_TAG_COUNT=0
                for i in ${REPO_LIST}
                do
                    UNIQUE_IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" ${DOCKERHUB_URL}/v2/repositories/${DOCKER_ORG}/${i}/tags/?page_size=100 | jq -r -c '[.results[] | {name, digest: .images[].digest}] | unique_by(.digest)')
                    REPO_TAG_COUNT=0
                    for j in $(echo "${UNIQUE_IMAGE_TAGS}" | jq -r '.[] | @base64'); 
                    do
                        ((REPO_TAG_COUNT++))
                        ((TOTAL_TAG_COUNT++))
                    done
                    echo "Repository name: "${DOCKER_ORG}/${i}", Unique tag count: $REPO_TAG_COUNT"
                done
                echo "Total tags: "${TOTAL_TAG_COUNT}
            fi
        fi
        ;;

    esac
}

count_unique_tags