## DNS

This chart syncs DNS records from istio gateways, ingress, and services to GCP's CloudDNS.  It does that by implementing the external-dns chart.

### Docs

[External DNS Chart](https://github.com/helm/charts/tree/master/stable/external-dns)
[External DNS](https://github.com/kubernetes-incubator/external-dns)
[External DNS Istio Integration](https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/istio.md)

### Terraform is currently creating this secret for us, so no need to run this command

`kubectl create secret generic -n kube-system external-dns-service-account --from-file=credentials.json`

### Helm install or upgrade DNS chart

```shell
helm upgrade --install dns . --namespace ${K8S_ENV}-system -f environments/${K8S_ENV}.yaml
```

### The list of DNS nameservers

Which will be authoritative for this domain. Use NS records to redirect from your DNS provider to these names, thus making Google Cloud DNS authoritative for this zone.  To obtain list of DNS nameservers infrastructure env directory and run:

`terraform output public_dns_name_servers`

### To view DNS sync logs

```
$ kubectl get po -n kube-system -l app=external-dns
NAME                                READY     STATUS    RESTARTS   AGE
dns-external-dns-858f68cb69-89btc   1/1       Running   0          12m

$ kubectl logs -n kube-system dns-external-dns-858f68cb69-89btc -f
```

### Istio

Be sure to enable istio as a source, this can be done like:

```
private-dns:     
  sources:
    - service
    - ingress
    - istio-gateway
public-dns:     
  sources:
    - service
    - ingress
    - istio-gateway
```
By default only `service`, `ingress` sources are enabled, this is b/c external-dns pod throws an error if istio is enabled and has not been installed in the cluster and external-dns doesn't function properly.

Currently External DNS works with Istio Gateways but not VirtualServices.  It also has a bug were it finds all Istio Gateways and publishes a record for them where its the istio gateway specified via `--istio-ingress-gateway=istio-system/istio-ingressgateway` or not.  To get by this issue we are currently deploying 2 different copies of external-dns, `public-dns` and `private-dns` we then specify:

```
private-dns:
  domainFilters: [ "private.ds24-prod.com" ]
  txtOwnerId: prod-private
public-dns:
  domainFilters: [ "public.ds24-prod.com" ]
  txtOwnerId: prod-public
```

`domainFilters` force each chart to only publish appropriate records and `txtOwnerId` which ensures that another install won't overwrite the dns records on accident.  Once [Issue](https://github.com/kubernetes-incubator/external-dns/issues/884) is fixed, we can go back to 1 chart and will no longer need 1 per dns zone.

### Open Related Issue

* Support External DNS syncing on VirtualServices [Issue](https://github.com/kubernetes-incubator/external-dns/issues/893)
* Syncing Gateways Bug that finds all Gateways, not just gateway requested via argument at boot [Issue](https://github.com/kubernetes-incubator/external-dns/issues/884)
