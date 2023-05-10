#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
RESULTS=/tmp/fortio.results.csv
DURATION=10
RECOVERY_TIME=30
PAYLOAD=""
JSON=""
QPS=1000
CONNECTIONS=(2 4 8 16 32 64)

baseline_http() {
    Label="Baseline-HTTP"
    if [[ -z $NAMESPACE ]]; then
        NAMESPACE="fortio-baseline"
    fi
    for c in "${CONNECTIONS[@]}"
    do
        DATE=$(date '+%m%d%Y-%H%M%S')
        REPORT="/tmp/$(echo ${Label}|sed s"/ /_/g")_${NAMESPACE}_${c}c_${DATE}.json"
        echo "Running ${Label} for ${DURATION}s with $c connections in K8s ns $NAMESPACE"
        command="kubectl -n $NAMESPACE exec -it deploy/fortio-client -c fortio -- fortio load -qps ${QPS} -c ${c} -r .0001 -t ${DURATION}s -payload "${PAYLOAD}" -a -labels "${Label}" ${JSON} http://fortio-server-defaults:8080/echo"
        kubectl -n $NAMESPACE exec -it deploy/fortio-client -c fortio -- fortio load -qps ${QPS} -c ${c} -r .0001 -t ${DURATION}s -payload "${PAYLOAD}" -a -labels "${Label}" ${JSON} http://fortio-server-defaults:8080/echo > "${REPORT}"
        sleep $RECOVERY_TIME
        report $REPORT $DATE
    done
    echo
    echo "To See Load Test results port-forward fortio client and click on Browse 'saved results'"
    echo "kubectl -n $NAMESPACE port-forward deploy/fortio-client 8080:8080"
    echo
    echo "http://localhost:8080/fortio"
}
baseline_grpc() {
    Label="Baseline-GRPC"
    if [[ -z $NAMESPACE ]]; then
        NAMESPACE="fortio-baseline"
    fi
    for c in "${CONNECTIONS[@]}"
    do
        DATE=$(date '+%m%d%Y-%H%M%S')
        REPORT="/tmp/$(echo ${Label}|sed s"/ /_/g")_${NAMESPACE}_${c}c_${DATE}.json"
        echo "Running ${Label} for ${DURATION}s with $c connections in K8s ns $NAMESPACE"
        kubectl -n $NAMESPACE exec -it deploy/fortio-client -c fortio -- fortio load -grpc -ping -qps 1000 -c $c -s 1 -r .0001 -t ${DURATION}s -payload "${PAYLOAD}" -a -labels "${Label}" ${JSON} fortio-server-defaults:8079 > "${REPORT}"
        sleep $RECOVERY_TIME
        report $REPORT $DATE
        
    done
    echo
    echo "To See Load Test results port-forward fortio client and click on Browse 'saved results'"
    echo "kubectl -n $NAMESPACE port-forward deploy/fortio-client 8080:8080"
    echo
    echo "http://localhost:8080/fortio"
}
consul_http() {
    Label="Consul-HTTP"
    if [[ -z $NAMESPACE ]]; then
        NAMESPACE="fortio-consul-100"
    fi
    for c in "${CONNECTIONS[@]}"
    do
        DATE=$(date '+%m%d%Y-%H%M%S')
        REPORT="/tmp/$(echo ${Label}|sed s"/ /_/g")_${NAMESPACE}_${c}c_${DATE}.json"
        echo "Running ${Label} for ${DURATION}s with $c connections in K8s ns $NAMESPACE"
        kubectl -n $NAMESPACE exec -it deploy/fortio-client -c fortio -- fortio load -qps 1000 -c $c -r .0001 -t ${DURATION}s -payload "${PAYLOAD}" ${HEADERS} -a -labels "${Label}" ${JSON} http://fortio-server-defaults:8080/echo > "${REPORT}"
        sleep $RECOVERY_TIME
        report $REPORT $DATE
        
    done
    echo
    echo "To See Load Test results port-forward fortio client and click on Browse 'saved results'"
    echo "kubectl -n $NAMESPACE port-forward deploy/fortio-client 8080:8080"
    echo
    echo "http://localhost:8080/fortio"
}
consul_grpc() {
    Label="Consul-GRPC"
    if [[ -z $NAMESPACE ]]; then
        NAMESPACE="fortio-consul-100"
    fi
    for c in "${CONNECTIONS[@]}"
    do
        DATE=$(date '+%m%d%Y-%H%M%S')
        REPORT="/tmp/$(echo ${Label}|sed s"/ /_/g")_${NAMESPACE}_${c}c_${DATE}.json"
        echo "Running ${Label} for ${DURATION}s with $c connections in K8s ns $NAMESPACE"
        kubectl -n $NAMESPACE exec -it deploy/fortio-client -c fortio -- fortio load -grpc -ping -qps 1000 -c $c -s 1 -r .0001 -t ${DURATION}s -payload "${PAYLOAD}" -a -labels "${Label}" -json - fortio-server-defaults-grpc:8079 > "${REPORT}"
        sleep $RECOVERY_TIME
        report $REPORT  $DATE
        
    done
    echo
    echo "To See Load Test results port-forward fortio client and click on Browse 'saved results'"
    echo "kubectl -n $NAMESPACE port-forward deploy/fortio-client 8080:8080"
    echo
    echo "http://localhost:8080/fortio"
}
report () {
    REPORT="${1}"
    DATE="${2}"
    # if [[  ${JSON} == "" ]]; then
    #     break 1
    # fi
    # Sometimes Fortio doesn't finish creating stdout.  Not sure why...
    if [[ ! -f $REPORT ]]; then
        echo "ERROR: File not found. $REPORT"
    fi
    TMP_JSON=$(cat $REPORT | grep -e "^{" -e "^}" -e "^\s")
    Labels=$(echo $TMP_JSON |  jq -r '.Labels')
    RunType=$(echo $TMP_JSON |  jq -r '.RunType')
    RequestedQPS=$(echo $TMP_JSON |  jq -r '.RequestedQPS')
    NumThreads=$(echo $TMP_JSON |  jq -r '.NumThreads')
    RequestedDuration=$(echo $TMP_JSON |  jq -r '.RequestedDuration')
    Errors=$(echo $TMP_JSON |  jq -r '.ErrorsDurationHistogram.Count')
    Destination=$(echo $TMP_JSON |  jq -r '.Destination')
    URL=$(echo $TMP_JSON |  jq -r '.URL')
    Streams=$(echo $TMP_JSON |  jq -r '.Streams')
    p50=$(echo $TMP_JSON |  jq -r '.DurationHistogram.Percentiles[] | select(.Percentile==50) | .Value')
    p75=$(echo $TMP_JSON | jq -r '.DurationHistogram.Percentiles[] | select(.Percentile==75) | .Value')
    p90=$(echo $TMP_JSON | jq -r '.DurationHistogram.Percentiles[] | select(.Percentile==90) | .Value')
    p99=$(echo $TMP_JSON | jq -r '.DurationHistogram.Percentiles[] | select(.Percentile==99) | .Value')
    p999=$(echo $TMP_JSON| jq -r '.DurationHistogram.Percentiles[] | select(.Percentile==99.9) | .Value')

    if [[ ! -f $RESULTS ]]; then
        echo "Date,Name,Type,Namespace,Duration,QPS,Connections,P50_${Labels},P75_${Labels},P90_${Labels},P99_${Labels},P99.9_${Labels},Errors,Streams,Destination" > $RESULTS
    fi
    if [[ $Destination == "null" ]]; then
        Destination=$URL
    fi
    echo "$DATE,$Labels,$RunType,$NAMESPACE,$RequestedDuration,$RequestedQPS,$NumThreads,${p50},${p75},${p90},${p99},${p999},$Errors,$Streams,$Destination" >> $RESULTS
    echo "${Labels} Report: wrote csv output to file: $RESULTS"
}

usage() { 
    echo "Usage: $0 [-d <seconds>] [-c <#threads>] [-n <k8s_namespace>] [-t <test_case>] [-p <payload_string>] [-j]" 1>&2; 
    echo
    echo "Example: $0 -t consul_http -d 300 -c 32"
    exit 1; 
}

while getopts "d:c:n:t:p:w:jh:q:" o; do
    case "${o}" in
        q)
            QPS=(${OPTARG})
            if ! [[ ${QPS} =~ ^[0-9]+$ ]]; then
                usage
            fi
            ;;
        c)
            CONNECTIONS=(${OPTARG})
            if ! [[ ${CONNECTIONS} =~ ^[0-9]+$ ]]; then
                usage
            fi
            ;;
        d)
            DURATION="${OPTARG}"
            echo "Setting Run Duration to ${DURATION}"
            ;;
        n)
            NAMESPACE="${OPTARG}"
            echo "Setting K8s Namespace to ${NAMESPACE}"
            ;;
        t)
            TEST=${OPTARG}
            echo "Running test case: $TEST"
            ;;
        p)
            PAYLOAD="${OPTARG}"
            echo "Running with Payload: $PAYLOAD"
            ;;
        w)
            RECOVERY_TIME="${OPTARG}"
            echo "Injecting Recovery Time of $RECOVERY_TIME between tests"
            ;;
        j)
            JSON="-json -"
            echo "Redirecting JSON Output to STDOUT for reporting"
            echo "Fortio will NOT save graphs in UI when this is enabled"
            ;;
        h)
            HEADERS="-H ${OPTARG}"
            echo "Adding Headers: ${HEADERS}"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z $DURATION ]]; then
    echo "Setting Run Duration to 10s"
    DURATION=10
fi

if [[ -z $TEST ]]; then
    echo "Running Default HTTP Test: consul_http in k8s namespace fortio-consul"
    TEST="consul_http"
fi

$TEST