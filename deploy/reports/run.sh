#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
SECONDS=10

baseline() {
    echo "Running ${SECONDS}s HTTP Baseline"
    kubectl -n fortio-baseline exec -it deploy/fortio-client -- fortio load -qps 1000 -c 32 -r .0001 -t ${SECONDS}s -a -labels "HTTP Baseline" http://fortio-server-defaults:8080/echo
    echo "Running ${SECONDS}s GRPC Baseline"
    kubectl -n fortio-baseline exec -it deploy/fortio-client -- fortio load -grpc -ping -qps 1000 -c 32 -r .0001 -t ${SECONDS}s -a -labels "GRPC Baseline" fortio-server-defaults:8079

    echo
    echo "To See Load Test results port-forward fortio client and click on Browse 'saved results'"
    echo "kubectl -n fortio-baseline port-forward deploy/fortio-client 8080:8080"
    echo
    echo "http://localhost:8080/fortio"
}

consul_http() {
    echo "Running ${SECONDS}s HTTP Consul"
    kubectl -n fortio-consul exec -it deploy/fortio-client -- fortio load -qps 1000 -c 32 -r .0001 -t ${SECONDS}s -a -labels "HTTP Consul" http://fortio-server-defaults:8080/echo
    # echo "Running ${SECONDS}s GRPC Consul"
    # kubectl -n fortio-consul exec -it deploy/fortio-client -- fortio load -grpc -ping -qps 1000 -c 32 -r .0001 -t ${SECONDS}s -a -labels "GRPC Consul" fortio-server-defaults-grpc:8079

    echo
    echo "To See Load Test results port-forward fortio client and click on Browse 'saved results'"
    echo "kubectl -n fortio-consul port-forward deploy/fortio-client 8080:8080"
    echo
    echo "http://localhost:8080/fortio"
}
consul_grpc() {
    echo "Running ${SECONDS}s GRPC Consul"
    kubectl -n fortio-consul exec -it deploy/fortio-client -- fortio load -grpc -ping -qps 1000 -c 32 -r .0001 -t ${SECONDS}s -a -labels "GRPC Consul" fortio-server-defaults-grpc:8079

    echo
    echo "To See Load Test results port-forward fortio client and click on Browse 'saved results'"
    echo "kubectl -n fortio-consul port-forward deploy/fortio-client 8080:8080"
    echo
    echo "http://localhost:8080/fortio"
}

if [[ -z $1 ]]; then
    echo "Using Default Run Time : ${SECONDS}s"
    SECONDS=10
else
    echo "Setting Run Time Seconds = ${1}s"
    SECONDS=${1}
fi

# Run Test Cases
#baseline
consul_http