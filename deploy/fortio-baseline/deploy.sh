#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
nodeSelector="--set nodeSelector.nodetype=default"

deploy() {
    # deploy eastus services
    kubectl config use-context usw2-app1
    kubectl apply -f ${SCRIPT_DIR}/.

    echo 
    echo "grafana"
    echo "http://$(kubectl get svc -l app.kubernetes.io/name=grafana -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname'):3000"
    # Output Ingress URL for fortio
    echo
    echo "fortio"
    echo "http://$(kubectl get svc -l app=fortio-client -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname'):8080/fortio"
    echo
}

delete() {
    kubectl config use-context usw2-app1
    kubectl delete -f ${SCRIPT_DIR}/.
}

#Cleanup if any param is given on CLI
if [[ ! -z $1 ]]; then
    echo "Deleting Services"
    delete
else
    echo "Deploying Services"
    deploy
fi
