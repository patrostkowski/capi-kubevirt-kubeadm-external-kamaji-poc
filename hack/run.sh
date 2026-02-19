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

KUBECTX_ROOT=kind-kind
KUBECTX_EXTERNAL=kind-external
KUBECONFIG_DEMO=./demo.conf
KUBECONFIG_DEMO_EXTERNAL=./demo-external.conf

echo "Deploy"

kubectx "${KUBECTX_ROOT}"
kubectl apply -f ./config/capi

clusterctl get kubeconfig demo > "${KUBECONFIG_DEMO}"
clusterctl get kubeconfig demo-external > "${KUBECONFIG_DEMO_EXTERNAL}"

# KUBECONFIG="${KUBECONFIG_DEMO}"  helm install cilium cilium/cilium --namespace=kube-system || true
KUBECONFIG="${KUBECONFIG_DEMO}" kubectl get nodes -A
KUBECONFIG="${KUBECONFIG_DEMO}" kubectl get all -A

# KUBECONFIG="${KUBECONFIG_DEMO_EXTERNAL}" helm install cilium cilium/cilium --namespace=kube-system || true
KUBECONFIG="${KUBECONFIG_DEMO_EXTERNAL}" kubectl get nodes -A
KUBECONFIG="${KUBECONFIG_DEMO_EXTERNAL}" kubectl get all -A
