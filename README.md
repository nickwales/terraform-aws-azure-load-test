
### Configure Azure CLI
```
doormat az login --subscription <sub_id>
doormat az export --subscription <sub_id>

export ARM_MSI_ENDPOINT=http://127.0.0.1:9000/azure/nwales@hashicorp.com-developer-7f60b297-f17e-4dcc-998a-4ca95806c542/metadata/identity/oauth2/token && export MSI_ENDPOINT=http://127.0.0.1:9000/azure/nwales@hashicorp.com-developer-7f60b297-f17e-4dcc-998a-4ca95806c542/metadata/identity/oauth2/token && export ARM_USE_MSI=true && ARM_SUBSCRIPTION_ID=7f60b297-f17e-4dcc-998a-4ca95806c542 && ARM_TENANT_ID=f5662df6-dc40-4331-bbd5-550bc91adef4
```

### Configure Kube Config File

```
./update_kube_config.sh
```


### Deploy Consul

We need an older version for pre-dataplane.
```
export VERSION=0.49.4
helm install consul hashicorp/consul --set global.name=consul --version ${VERSION} --create-namespace --namespace consul --values deploy/helm/values_sidecar.yaml
```

Latest version looks like this:
```
helm install consul hashicorp/consul --set global.name=consul --create-namespace --namespace consul --values deploy/helm/values_dataplane.yaml
```

### Deploy Prometheus
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install -f deploy/helm/prometheus-values.yaml prometheus prometheus-community/prometheus --version "15.5.3" --wait
helm install prometheus-consul-exporter prometheus-community/prometheus-consul-exporter

helm repo add grafana https://grafana.github.io/helm-charts
helm install -f deploy/helm/grafana-values.yaml grafana grafana/grafana --wait
 ```

### Connect to prometheus
```
kubectl port-forward service/grafana 3000:3000
open http://localhost:8081
```

### Configure default deny intention

```
kubectl apply -f deploy/config/crd/intentions/default-deny.yaml
```


### Deploy Fortio

We're deploying a fortio client and a selection of servers with different resource characteristics.
```
kubectl apply -f deploy/apps/fortio-client.yaml
kubectl apply -f deploy/apps/fortio-server-defaults.yaml
kubectl apply -f deploy/apps/fortio-server-small.yaml
kubectl apply -f deploy/apps/fortio-server-medium.yaml
kubectl apply -f deploy/apps/fortio-server-large.yaml

# Open fortio to the ingress controller (optional)
kubectl apply -f deply/config/crd/ingress-controller/ingress-controller.yaml

# Alternatively port forward to fortio
kubectl port-forward service/fortio-client 8080:8080
open http://localhost:8080
```

### Configure Fortio

Use this base URL

http://fortio-server-<size>.default.svc.cluster.local:8080/echo


### Available options:

See https://github.com/fortio/fortio#server-urls-and-features

## Example

Delay 10% of responses by 150 microseconds, 5% by 2 milliseconds
Respond to 10% of requests wiht a 1k payload and 5% with a 512 byte response.

The remaining 85% of queries will get an echo of whatever was sent back.

 `http://fortio-server.default.svc.cluster.local:8080/echo?delay=150us:10,2ms:5,0.5s:1&size=1024:10,512:5`





