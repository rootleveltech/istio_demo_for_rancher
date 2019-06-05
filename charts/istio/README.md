Docs: https://preliminary.istio.io/docs/setup/kubernetes/helm-install/
GitHub Install Instructions: https://github.com/istio/istio/tree/master/install/kubernetes/helm/istio

## Install

```
git clone git@github.com:istio/istio.git
# git checkout 785b109d335e7000d1346b63671cbe9e21f068fc # <-- time of writing this README
helm repo add istio.io https://storage.googleapis.com/istio-prerelease/daily-build/master-latest-daily/charts

### Helm Install Istio-Init (CRDs)
cd ~/digistore24/istio/install/kubernetes/helm/istio-init
helm upgrade --install istio-init . --namespace istio-system
```

### Create Secret for Kiali login

Should move this to Terraform code:

```
$ echo -n 'admin' | base64
YWRtaW4=

$ echo -n 'P@ssw0rd!' | base64
UEBzc3cwcmQh

$ kubectl create namespace istio-system

$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: istio-system
  labels:
    app: kiali
type: Opaque
data:
  username: YWRtaW4=
  passphrase: UEBzc3cwcmQh
EOF
```

```
helm upgrade --install istio . --namespace istio-system -f environments/${K8S_ENV}.yaml
```

### DNS Chart Changes

Be sure to enable istio as a source, this can be done like:

```
external-dns:
  sources:
    - service
    - ingress
    - istio-gateway
```
By default only `service`, `ingress` sources are enabled, this is b/c external-dns pod throws an error if istio is enabled and has not been installed in the cluster


### Jaeger

Access WebUI, you can find the url via:

http://tracing.int-rancher-demo.rootleveltech.com/jaeger/search

### Kiali

Access WebUI, you can find the url via:

http://kiali.int-rancher-demo.rootleveltech.com/kiali/console/overview 

Login User/Password was created earlier via K8s Secret

### Prometheus

http://istio-prometheus.int-rancher-demo.rootleveltech.com


### Istio CertManager

IAM Service Account is created via Terraform [here](https://gitlab.com/ds24/infra/blob/master/infrastructure/modules/dns/iam.tf#L1-18), a K8s secret with the Service Account Creds is created [here](https://gitlab.com/ds24/infra/blob/master/infrastructure/modules/dns/main.tf#L12-21)

#### After Helm install you should see a renewal scheduled for each certificate after its been renewed.  Currently there should be 2 per Istio install istio-system/istio-istio-gateway-private and istio-system/istio-istio-gateway-public which respectively renew certs for *.rancher-demo.rootleveltech.com and *.int-rancher-demo.rootleveltech.com

```
kubectl -n istio-system logs deployment/certmanager -f

I0215 23:21:16.498964       1 controller.go:171] certificates controller: syncing item 'istio-system/istio-istio-gateway-public'
I0215 23:21:16.499598       1 sync.go:206] Certificate istio-system/istio-istio-gateway-public scheduled for renewal in 1438 hours
I0215 23:21:16.499739       1 controller.go:185] certificates controller: Finished processing work item "istio-system/istio-istio-gateway-public"
I0215 23:22:11.616283       1 controller.go:171] certificates controller: syncing item 'istio-system/istio-istio-gateway-private'
I0215 23:22:11.617021       1 sync.go:206] Certificate istio-system/istio-istio-gateway-private scheduled for renewal in 1438 hours
I0215 23:22:11.617190       1 controller.go:185] certificates controller: Finished processing work item "istio-system/istio-istio-gateway-private"
```

```
# Restart gateway pods so they get new SSL cert, this needs to be done every 60-90 days
# Cert Manager fetches a new cert every 60 days and cert is valid for 90 days
kubectl -n istio-system delete pods -l chart=gateways
```

