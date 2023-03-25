#!/bin/sh

## Convert terraform to kube Config

server=$(cat ./terraform.tfstate| jq -r '.resources[0].instances[0].attributes.kube_config[0].host')
token=$(cat ./terraform.tfstate| jq -r '.resources[0].instances[0].attributes.kube_config[0].password')
client_key=$(cat ./terraform.tfstate| jq -r '.resources[0].instances[0].attributes.kube_config[0].client_key')
client_certificate=$(cat ./terraform.tfstate| jq -r '.resources[0].instances[0].attributes.kube_config[0].client_certificate')
cluster_ca=$(cat ./terraform.tfstate| jq -r '.resources[0].instances[0].attributes.kube_config[0].cluster_ca_certificate')
username=$(cat ./terraform.tfstate| jq -r '.resources[0].instances[0].attributes.kube_config[0].username')


cat <<EOF > ~/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${cluster_ca}
    server: ${server}
  name: consul-test
contexts:
- context:
    cluster: consul-test
    namespace: default
    user: clusterUser_consul-test_consul-test
  name: consul-test
current-context: consul-test
kind: Config
preferences: {}
users:
- name: clusterUser_consul-test_consul-test
  user:
    client-certificate-data: ${client_certificate}
    client-key-data: ${client_key}
    token: ${token}
EOF