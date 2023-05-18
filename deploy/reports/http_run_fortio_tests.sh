#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
DURATION=300
WAIT_PERIOD=30
NAMESPACES=(fortio-consul-default fortio-consul-150 fortio-consul-logs)
TEST_TYPE=(consul_http)
if [[ $1 ]]; then
    CONNECTIONS=($1)
else
    CONNECTIONS=(2 4 8 16 32 64)
fi

#Run Baseline Test Cases
baseline(){
    c=${1}  # Pass Connection count to run test with
    for type in "${TEST_TYPE[@]}"
    do
        if [[ ${type} =~ consul_http ]]; then
            echo "Running Test Type 'baseline_http' in namespace fortio-baseline with $c connections"
            nohup ${SCRIPT_DIR}/fortio_cli.sh  -j -t baseline_http -n fortio-baseline -d${DURATION} -w${WAIT_PERIOD} -c${c} &
            pid=$!
            wait $pid
            echo "Test completed (PID: $pid)"
        else
            echo echo "Running Test Type 'baseline_grpc' in namespace fortio-baseline with $c connections"
            nohup ${SCRIPT_DIR}/fortio_cli.sh  -j -t baseline_grpc -n fortio-baseline -d${DURATION} -w${WAIT_PERIOD} -c${c} &
            pid=$!
            wait $pid
        fi
        # echo "waiting ${DURATION}s before next test..."
        # sleep ${DURATION}
    done
}

# Consul Test Cases
for c in "${CONNECTIONS[@]}"
do
    for type in "${TEST_TYPE[@]}"
    do
        for ns in "${!NAMESPACES[@]}"
        do
            echo "Running Test Type '${type}' in namespace ${NAMESPACES[$ns]} with $c connections"
            nohup ${SCRIPT_DIR}/fortio_cli.sh -j -t ${type} -n ${NAMESPACES[$ns]} -d ${DURATION} -w${WAIT_PERIOD} -c${c} &
            pids[${ns}]=$!
        done
        baseline ${c}
        for pid in ${pids[@]}; do
            wait $pid
            echo "Test completed (PID: $pid)"
        done
    done
done
