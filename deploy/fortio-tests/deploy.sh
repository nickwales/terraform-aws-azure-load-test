#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

deploy() {
    # deploy eastus services
    kubectl config use-context usw2-app1
    kubectl create namespace fortio-consul-100
    kubectl create namespace fortio-consul-150

    kubectl apply -f ${SCRIPT_DIR}/baseline/init  # create ns fortio-baseline
    kubectl apply -f ${SCRIPT_DIR}/baseline
    kubectl apply -f ${SCRIPT_DIR}/consul-100/init-consul-config
    kubectl apply -f ${SCRIPT_DIR}/consul-100
    kubectl apply -f ${SCRIPT_DIR}/consul-150/init-consul-config
    kubectl apply -f ${SCRIPT_DIR}/consul-150
    echo
    echo "Waiting for fortio client pod to be ready..."
    echo
    kubectl -n fortio-consul wait --for=condition=ready pod -l app=fortio-client
    echo
    echo 
    echo "grafana"
    echo "http://$(kubectl -n metrics get svc -l app.kubernetes.io/name=grafana -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname'):3000"
    # Output Ingress URL for fortio
    echo
    echo "fortio"
    echo "http://$(kubectl -n consul get svc -l component=ingress-gateway -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname'):8080/fortio"
    echo
}

delete() {
    kubectl config use-context usw2-app1
    kubectl delete -f ${SCRIPT_DIR}/consul-100
    kubectl delete -f ${SCRIPT_DIR}/consul-100/init-consul-config
    kubectl delete -f ${SCRIPT_DIR}/consul-150
    kubectl delete -f ${SCRIPT_DIR}/consul-150/init-consul-config
    kubectl delete -f ${SCRIPT_DIR}/baseline
    kubectl delete -f ${SCRIPT_DIR}/baseline/init
    kubectl delete namespace fortio-consul-150
    kubectl delete namespace fortio-consul
}

#Cleanup if any param is given on CLI
if [[ ! -z $1 ]]; then
    echo "Deleting Services"
    delete
else
    echo "Deploying Services"
    deploy
fi
