# OIDC User Access Test (Stack4Things)

This short guide shows how to test Kubernetes access using an OIDC user by
switching contexts and verifying RBAC restrictions.

---
## Prerequisites

The commands in Step 1 must be executed from a directory such that the following file exists relative to the current working directory:
```bash
../../resources/k3d-cluster/certificate/certs/ca.crt
```
This file contains the Certificate Authority (CA) used to sign the TLS certificate of Keycloak.
If your directory layout is different, adjust the --cacert path accordingly.

## 1. Get an OIDC Token from Keycloak

```bash
TOKEN=$(curl -s --cacert ../../resources/k3d-cluster/certificate/certs/ca.crt \
  -X POST "https://host.k3d.internal:8443/realms/stack4things/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=kubernetes" \
  -d "username=testuser" \
  -d "password=testpassword" | jq -r .access_token)
```

## 2. Add the OIDC User Context
```bash
CLUSTER=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')
echo "$CLUSTER"
```


```bash
kubectl config set-credentials testuser-oidc --token="$TOKEN"
```

```bash
kubectl config set-context testuser \
  --cluster="$CLUSTER" \
  --user=testuser-oidc
```

## 3. Switch Context and Test Access
```bash
kubectl config use-context testuser
kubectl auth whoami
``` 
```bash
kubectl get nodes
kubectl get pods
```

Expected result: 

```bash
Error from server (Forbidden): pods is forbidden: User "https://host.k3d.internal:8443/realms/stack4things#testuser" cannot list resource "pods" in API group "" in the namespace "default"
```
## 4. Switch Back to Admin
```bash
kubectl config use-context k3d-stack4things-cluster
kubectl get nodes 
```
 
 (Optional) Delete testuser context:

```bash
kubectl config delete-context testuser
kubectl config delete-user testuser-oidc
```
