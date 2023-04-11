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