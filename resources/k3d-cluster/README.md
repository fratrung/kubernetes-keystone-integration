# Local Development Cluster (k3d)

This guide explains how to install **k3d** and how to create a local Kubernetes
cluster named **stack4things-cluster** using the configuration file
`s4t-config-cluster.yaml`.

This cluster will be used for developing and testing:
- the **RBAC Operator**
- the **Stack4Things Crossplane Provider**
- the **Project**, **Device**, and **Plugin** controllers

---

## Install k3d

k3d is a lightweight wrapper to run Kubernetes (k3s) inside Docker.
It is the recommended environment for developing operators and providers.

### Requirements
- Docker installed and running
- curl
---

### Install on Linux

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

## Create the cluster using the provided configuration file

Run the following command from the root of the repository:

```bash
k3d cluster create --config s4t-config-cluster.yaml
```

This command will:

- create a k3s-based Kubernetes cluster named stack4things-cluster

- start 1 control plane and 2 worker nodes

- create a load balancer

- automatically update your kubeconfig


## Verify that the cluster is running

List all clusters managed by k3d:

```bash
k3d cluster list
```

You should see:
```bash
NAME                   SERVERS   AGENTS   LOADBALANCER
stack4things-cluster   1/1       2/2      true
```

## Set the kubeconfig context (optional but recommended)
```bash
kubectl config use-context k3d-stack4things-cluster
```

## Verify cluster nodes
```bash
kubectl get nodes
```
Expected output:
```bash
NAME                                STATUS   ROLES                  AGE   VERSION
k3d-stack4things-cluster-agent-0    Ready    <none>                 13m   v1.31.5+k3s1
k3d-stack4things-cluster-agent-1    Ready    <none>                 13m   v1.31.5+k3s1
k3d-stack4things-cluster-server-0   Ready    control-plane,master   13m   v1.31.5+k3s1
```

## Check default namespaces

```bash
kubectl get ns
```
You should see namespaces such as:

```bash
NAME              STATUS   AGE
default           Active   14m
kube-node-lease   Active   14m
kube-public       Active   14m
kube-system       Active   14m
```

## RBAC for the project creators

```bash
kubectl apply -f deployments/bootstrap_rbac.yaml
```
bootstrap_RBAC.yaml:
```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: s4t-project-creator
rules:
- apiGroups: ["s4t.s4t.io"]
  resources: ["projects"]
  verbs: ["create","get","patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: s4t-project-creator-binding
subjects:
- kind: Group
  name: s4t:project-creator
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: s4t-project-creator
  apiGroup: rbac.authorization.k8s.io

```
The `ClusterRole` **s4t-project-creator** allows `create`, `get`, and `patch` operations on the `projects` resource in the `s4t.s4t.io` API group.  

The `ClusterRoleBinding` binds this role to the **s4t:project-creator** group, so only members of this group can perform these actions.  

After applying this RBAC, only users in the **s4t:project-creator** group can create or modify Project CRDs.

After this, only the users of the "s4t:project-creator" groups can create the Project CR.

