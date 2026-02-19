# capi-kubevirt-kubeadm-external-kamaji-poc

Proof of concept for running **Cluster API (CAPI)** with **kubeadm** and **Kamaji**, using a local management cluster and an **external control plane**.

## Scope of PoC

- Creates **two kind clusters**:
  - **kind** (management cluster)
  - **external** (external control-plane cluster)

- On **kind**:
  - Installs Cluster API (CAPI)
  - Installs Kamaji
  - Installs KubeVirt (infrastructure provider)

- On **external**:
  - Installs **only Kamaji**
  - Acts as a remote control-plane host

## ClusterClasses

### 1. Local control plane
- Creates a KubeVirt-based workload cluster
- Kamaji control plane is deployed **locally** in the management cluster
- Workers are provisioned via **KubeVirt**
- Nodes are bootstrapped with **kubeadm**

### 2. External control plane
- Infrastructure (workers) is still created via **local KubeVirt**
- **Kamaji control plane is deployed in the external cluster**
- External cluster hosts the Kamaji-managed control plane
- Workers join using **kubeadm**

## Usage

### Prerequisites

- [Task](https://taskfile.dev/)
- kind
- kubectl
- helm

### Running tasks

```bash
task setup
task run
task cleanup
```
