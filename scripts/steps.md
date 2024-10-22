
### Start "api" service
### SSH to Consul client node
#docker run -d --name api -p 8080:9090 -e MESSAGE="api-v1.0" panchalravi/fake-service:0.24.2
MESSAGE=hello-fake LISTEN_ADDR=127.0.0.1:8080 ~/fake-service > /tmp/api.log 2>&1 &


k create ns consul
k create secret -n consul generic consul-ca-cert --from-literal="tls.crt=$(terraform output -raw consul_ca)" 
k create secret generic consul-license -n consul --from-literal="key=$(cat ./files/config/consul_license.hclic)" 
k create secret -n consul generic consul-bootstrap-acl-token --from-literal="token=$(terraform output -raw consul_token)" 

export CONSUL_VERSION=1.5.3
### Update externalServers hosts
helm install consul hashicorp/consul --values ./scripts/consul-client.yaml --namespace consul --version "$CONSUL_VERSION"

helm upgrade consul hashicorp/consul --values ./scripts/consul-client.yaml --namespace consul --version "$CONSUL_VERSION"

helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace default --create-namespace

kaf ./scripts/frontend.yaml
kaf ./scripts/ingress.yaml



### Delete K8s objects
kdelf ./scripts/ingress.yaml
kdelf ./scripts/frontend.yaml

helm uninstall -n default ingress-nginx 
helm uninstall -n consul consul