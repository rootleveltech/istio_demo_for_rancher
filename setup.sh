##################################################################
# 1. Terraform
##################################################################
cd terraform
terraform plan
terraform apply -auto-approve
cd ..

##################################################################
# 2. Install Istio CRDs
##################################################################
cd charts
helm dep up istio-init
helm upgrade --install istio-init istio-init --namespace istio-system

kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

echo "28 istio.io and certmanager.k8s.io CRD's should exist"

##################################################################
# 3. Istio Public Gateway only
##################################################################
helm dep up istio
helm upgrade --install istio istio --namespace istio-system -f prd.yaml -f istio/03-values.yaml

kubectl get gw -n istio-system
kubectl describe gw -n istio-system istio-public
kubectl get svc -n istio-system -l app=istio-gateway-public
kubectl describe svc -n istio-system -l app=istio-gateway-public

helm upgrade --install myapp myapp --namespace prd-app  -f prd.yaml

# Edit /etc/hosts

##################################################################
# 4. Istio, Public and Private Gateway
##################################################################
helm upgrade --install istio istio --namespace istio-system -f prd.yaml -f istio/04-values.yaml

kubectl get gw -n istio-system
kubectl describe gw -n istio-system istio-private
kubectl get svc -n istio-system -l app=istio-gateway-private
kubectl describe svc -n istio-system -l app=istio-gateway-private
kubectl describe po -n istio-system -l app=istio-gateway-private

##################################################################
# 5. DNS
##################################################################
helm dep up dns
helm upgrade --install dns dns --namespace prd-system -f prd.yaml

kubectl logs -n prd-system -f $(kubectl get pod -n prd-system -l app=public-dns -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n prd-system -f $(kubectl get pod -n prd-system -l app=private-dns -o jsonpath="{.items[0].metadata.name}")
nslookup *.rancher-demo.rootleveltech.com
nslookup *.int-rancher-demo.rootleveltech.com

echo "http://istio-prometheus.int-rancher-demo.rootleveltech.com/graph"

##################################################################
# 6. SSL staging LetsEncrypt
##################################################################
helm upgrade --install istio istio --namespace istio-system -f prd.yaml -f istio/06-values.yaml

kubectl logs -n istio-system -f $(kubectl get pod -n istio-system -l app=certmanager -o jsonpath="{.items[0].metadata.name}")
kubectl delete po -n istio-system -l chart=gateways

##################################################################
# 7. SSL Prod LetsEncrypt
##################################################################

kubectl delete deploy -n istio-system certmanager
kubectl delete secrets -n istio-system istio-ingressgateway-certs
kubectl delete secrets -n istio-system istio-ingressgateway-private-certs
helm upgrade --install istio istio --namespace istio-system -f prd.yaml -f istio/07-values.yaml
kubectl logs -n istio-system -f $(kubectl get pod -n istio-system -l app=certmanager -o jsonpath="{.items[0].metadata.name}")
kubectl delete po -n istio-system -l chart=gateways

##################################################################
# 8. SSL SDS with CertManager
##################################################################
# Broken with CertManager

##################################################################
# 9. Egress 
##################################################################
helm upgrade --install istio istio --namespace istio-system -f prd.yaml -f istio/09-values.yaml

##################################################################
# 10. ServiceEntry
##################################################################
helm upgrade --install istio istio --namespace istio-system -f prd.yaml -f istio/10-values.yaml

##################################################################
# Clean Up
##################################################################
# delete all helm charts
# delete namespaces (should delete certmanager secrets)
kubectl delete secrets -n istio-system istio-ingressgateway-certs
kubectl delete secrets -n istio-system istio-ingressgateway-private-certs
terraform destroy -target kubernetes_namespace.istio_system
terraform destroy -target kubernetes_namespace.system
terraform destroy -target kubernetes_namespace.app
