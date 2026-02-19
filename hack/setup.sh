#!/bin/bash
# Copyright (c) 2025 Patryk Rostkowski
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


set -xeu

export CLUSTER_TOPOLOGY=true

KUBECTX_ROOT=kind-kind
KUBECTX_EXTERNAL=kind-external

echo "Bootstrap clusters"

kind create cluster --config ./config/kind.yaml || true
kind create cluster --config ./config/kind-external.yaml || true

for c in $(kind get clusters); do
  kind load docker-image docker.io/clastix/kamaji:afebfea88ae5585a0ce85f133e2508859168b61b7f843077f2a52b4f087e0abc --name "$c"
done

echo "Run on management cluster"
kubectx "${KUBECTX_ROOT}"
clusterctl init \
  --core cluster-api \
  --bootstrap kubeadm \
  --infrastructure kubevirt --control-plane kamaji

kubectl -n kamaji-system patch deployment capi-kamaji-controller-manager \
  --type='json' \
  -p='[
    {
      "op": "replace",
      "path": "/spec/template/spec/containers/0/args/1",
      "value": "--feature-gates=DynamicInfrastructureClusterPatch=false,ExternalClusterReference=true,ExternalClusterReferenceCrossNamespace=true,SkipInfraClusterPatch=false"
    }
  ]'

helm upgrade --install kamaji clastix/kamaji \
  --namespace kamaji-system \
  --create-namespace \
  --set 'resources=null' \
  --set image.repository=clastix/kamaji \
  --set image.tag=afebfea88ae5585a0ce85f133e2508859168b61b7f843077f2a52b4f087e0abc \
  --set image.pullPolicy=Never \
  --version 0.0.0+latest

export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
echo $VERSION
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'

kubectl apply -f ./config/cloud-provider-kind/cloud-provider-kind.yaml
kubectl apply --server-side --force-conflicts -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml

EXT_CP_NAME=external-control-plane
EXT_CP_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$EXT_CP_NAME")
echo "$EXT_CP_IP"
kubectl --context kind-external config view --raw --minify --flatten > kind-external.kubeconfig
sed -i -E \
  "s#https://[^:]+:[0-9]+#https://${EXT_CP_IP}:6443#g" \
  kind-external.kubeconfig
kubectl -n default delete secret kind-external-kubeconfig || true
kubectl -n default create secret generic kind-external-kubeconfig \
  --from-file=kubeconfig=kind-external.kubeconfig

echo "Run on external cluster"
kubectx "${KUBECTX_EXTERNAL}"
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

helm upgrade --install kamaji clastix/kamaji \
  --namespace kamaji-system \
  --create-namespace \
  --set 'resources=null' \
  --set image.repository=clastix/kamaji \
  --set image.tag=afebfea88ae5585a0ce85f133e2508859168b61b7f843077f2a52b4f087e0abc \
  --set image.pullPolicy=Never \
  --version 0.0.0+latest

kubectl apply -f ./config/cloud-provider-kind/cloud-provider-kind.yaml
kubectl apply --server-side --force-conflicts -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml
kubectl create ns kamaji-tenants

