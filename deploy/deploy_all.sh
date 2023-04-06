#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
nodeSelector="--set nodeSelector.nodetype=default"

helmDeploy() {
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install -f ${SCRIPT_DIR}/helm/prometheus-values-with-nodeselector.yaml prometheus prometheus-community/prometheus --version "15.5.3" --wait
    helm install prometheus-consul-exporter prometheus-community/prometheus-consul-exporter ${nodeSelector} --wait

    helm repo add grafana https://grafana.github.io/helm-charts
    helm install -f ${SCRIPT_DIR}/helm/grafana-values.yaml grafana grafana/grafana ${nodeSelector} --wait
}

deploy() {
    # deploy eastus services
    kubectl config use-context usw2-app1
    kubectl apply -f ${SCRIPT_DIR}/fortio/init-consul-config
    kubectl apply -f ${SCRIPT_DIR}/fortio

    # Output Ingress URL for fortio
    echo
    echo "http://$(kubectl -n consul get svc -l component=ingress-gateway -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname'):8080/fortio"
    echo
}

delete() {
    kubectl config use-context usw2-app1
    kubectl delete -f ${SCRIPT_DIR}/fortio
    kubectl delete -f ${SCRIPT_DIR}/fortio/init-consul-config
    helm uninstall prometheus prometheus-consul-exporter grafana
}

#Cleanup if any param is given on CLI
if [[ ! -z $1 ]]; then
    echo "Deleting Services"
    delete
else
    echo "Deploying Services"
    helmDeploy
    sleep 5
    deploy
fi