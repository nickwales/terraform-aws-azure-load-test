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
There are multiple test cases contained within the `fortio-tests` directory.

Deploy a single test use case
```
cd fortio-tests
deploy.sh
```

Undeploy the test use case by providing any value as a parameter (ex: delete)
```
cd <fortio-baseline>
deploy_all.sh delete
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