# terraform-aws-azure-load-test

## Deploy the monitoring stack with Helm
Current Monitoring Stack:
* prometheus
* prometheus-consul-exporter
* grafana

```
cd deploy
./deploy_helm.sh
```

## Deploy Fortio
There are multiple test cases contained within a directory.
* fortio-baseline
* fortio-consul

Deploy a single test use case
```
cd <fortio-baseline>
deploy_all.sh
```

Undeploy the test use case by providing any value as a parameter (ex: delete)
```
cd <fortio-baseline>
deploy_all.sh delete
```

## Troubleshooting

Verify monitoring endpoints
```
# consul server
kc exec -it consul-server-0 -- curl http://127.0.0.1:8500/v1/agent/metrics\?format\=prometheus

# prometheus consul exporter
kubectl exec -it multitool-767f4f6fd4-d5pmk -- curl http://prometheus-consul-exporter:9107/metric
```

Start multitool container in service mesh and use to verify monitoring endpoints are available within mesh.
```
cd deploy/multitool
kubectl apply -f .

kc get svc  # get consul-expose-services external ip/lb
kubectl get po # get multitool pod name

# Test metrics endpoint is available on http
kubectl exec -it multitool-767f4f6fd4-jmzst -- curl http://k8s-consul-consulex-18697e9cbf-73d9c87f1ede912a.elb.us-west-2.amazonaws.com:8500/v1/agent/metrics | jq -r

curl http://127.0.0.1:8500/v1/agent/metrics\?format\=prometheus
```


### Fortio CLI

Reports
```
fortio report -data-dir ./reports/
```

GRPC
```
kubectl exec -it deploy/fortio-client -- fortio load -a -grpc -ping -grpc-ping-delay 0.25s -payload "01234567890" -c 2 -s 4 -json - fortio-server-defaults-grpc:8079

kubectl exec -it deploy/fortio-client -- fortio load -grpc -ping -qps 100 -c 10 -r .0001 -t 3s -labels "grpc test" fortio-server-defaults-grpc:8079

# -s multiple streams per -c connection.  .25s delay in replies using payload of 10bytes
kubectl exec -it deploy/fortio-client -- fortio load -a -grpc -ping -grpc-ping-delay 0.25s -payload "01234567890" -c 2 -s 4 fortio-server-defaults-grpc:8079
```

HTTP
* `-json -` write json output to stdout
```
kubectl -n fortio-baseline exec -it deploy/fortio-client -- fortio load -qps 1000 -c 32 -r .0001 -t 300s -labels "http test" -json - http://fortio-server-defaults:8080/echo
```

TCP
```
fortio load -qps -1 -n 100000 tcp://localhost:8078
```

UDP
```
fortio load -qps -1 -n 100000 udp://localhost:8078/
```
