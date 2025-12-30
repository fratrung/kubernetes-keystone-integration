# kubernetes-keystone-integration

Integration layer between **OpenStack Keystone** and **Kubernetes** to enable unified authentication, authorization, and resource synchronization across cloud and edge environments.

---

## Overview

This project aims to bridge **OpenStack Keystone** — the identity and access management service of OpenStack — with **Kubernetes**, providing a **single source of identity** for both cloud and edge resources.

---

## Architecture

The integration is composed of two main components:

### 1. **Stack4Things RBAC Operator (Local Kubernetes Operator)**
A custom Kubernetes Operator written in Go with Kubebuilder.  
It is responsible for managing *local cluster resources* derived from Keystone
information and user project definitions.  
This controller handles:

- Automatic creation of per-project Kubernetes namespaces  
- Dynamic Role + RoleBinding generation for OIDC/Keystone users  
- Local project lifecycle cleanup via finalizers 
- Set the new CR Project status to Ready

**It ensures that every Keystone project has an isolated Kubernetes environment
with proper RBAC enforcement.**

### 2. **Stack4Things Provider (Crossplane Provider)**
A Crossplane Provider that integrates Kubernetes with the Stack4Things
(IoTronic) platform.  
It consumes the resources prepared by the RBAC Controller and manages
*remote resources* inside Stack4Things, such as:

- S4T Projects  
- Devices  
- Plugins 
- Service
- BoardPluginInjection
- BoardServiceInjection

**The provider implements the Crossplane `Connector` and `ExternalClient` pattern
to synchronize the state of Kubernetes CRDs with the corresponding resources in
Stack4Things, ensuring end-to-end lifecycle management.**

---

![Architecture Diagram](images/architecture.png)


| Controller / Component           | Repository        | Description                                                                                   |
|----------------------------------|-------------------|-----------------------------------------------------------------------------------------------|
| **RBACController**               | rbac-operator     | Standalone Kubernetes operator built with Kubebuilder.                                        |
|                                  |                   | Responsible for LOCAL cluster resources:                                                      |
|                                  |                   | - Creates per-project Namespace                                                               |
|                                  |                   | - Creates per-user Role and RoleBinding (OIDC preferred_username)                             |
|                                  |                   | - Creates Keystone authentication Secret                                                      |
|                                  |                   | - Handles local cleanup via finalizers                                                        |
|                                  |                   | Does NOT interact with Stack4Things.                                                          |
|                                  |                   |                                                                                               |
| **ProjectController**            | s4t-provider      | Part of the Crossplane Provider for Stack4Things.                                             |
|                                  |                   | Watches the `Project` custom resource.                                                        |
|                                  |                   | Uses the Secret created by RBACController to authenticate to S4T.                             |
|                                  |                   | Creates/updates/deletes projects on Stack4Things via Connector + ExternalClient.              |
|                                  |                   | Syncs remote S4T project state back into the Project CR status.                               |
|                                  |                   |                                                                                               |
| **DeviceController**             | s4t-provider      | Crossplane managed resource controller.                                                       |
|                                  |                   | Synchronizes IoTronic/Stack4Things devices with Kubernetes `Device` CRs.                      |
|                                  |                   | Handles: Observe, Create, Update, Delete for S4T devices.                                     |
|                                  |                   |                                                                                               |
| **PluginController**             | s4t-provider      | Crossplane managed resource controller for IoTronic plugins.                                  |
|                                  |                   | Responsible for injecting/uninjecting plugins on devices via S4T API.                         |
|                                  |                   | Ensures plugin lifecycle on S4T matches the state of the `Plugin` CR in Kubernetes.           |

---

## Create S4T Project

Creating a new `Project` resource automatically initializes the corresponding Stack4Things environment for the authenticated user.  
The flow involves OIDC authentication, a Mutating Admission Webhook, etcd persistence, and the RBAC Operator that prepares the user’s development space.

![RBAC Operator Sequence Diagram](images/RBAC_Operator_Sequence_Diagram.drawio.png)

### Flow Summary

- The user submits a `Project` using a Keystone OIDC JWT (`kubectl --token="$JWT" apply -f project.yaml`).
- The Kubernetes API Server authenticates the JWT and extracts the user identity.
- The **Mutating Webhook** injects the authenticated username into `spec.owner`.
- The mutated CRD is validated and stored in **etcd**.
- The **RBAC Operator** detects the new Project and provisions:
  - a dedicated Namespace  
  - a Role defining project-level permissions.
  - a RoleBinding mapping the Keystone user to the Role  
- For each S4T Project, the RBAC Operator creates and manages a set of **federated groups** following a deterministic naming convention:
```bash
s4t:<owner>-<projectName>:<role>
```

where `<role>` can be one of:

- `admin_iot_project`  
  Full administrative permissions on the project.
- `member_iot_project`  
  Developer / power-user permissions.
- `user_iot_project`  
  Read-only or limited service usage permissions.

These groups are bound to the corresponding Kubernetes `Role` objects through `RoleBinding` resources, enabling RBAC enforcement based on OIDC group claims.
- Once the setup is complete, the operator marks the Project as **Ready**, enabling the S4T Crossplane provider to manage the remote resource in Stack4things.

---

## Update S4T Project 

WIP

---

## Delete S4T Project

WIP

---

## Goals

- Enable **Single Sign-On (SSO)** between OpenStack and Kubernetes via OIDC
- Maintain **consistent multi-tenant RBAC policies** across systems
- Represent **IoT/edge resources** (via Stack4Things) as Kubernetes-managed entities
- Provide a foundation for **unified cloud-edge orchestration**
- Allowing the user to manage Stack4things projects and resources through Kubernetes using the same Identity provided by Keystone
---

## Stack

- **Language:** Go (Kubebuilder and Crossplane S4T provider)
- **Identity provider:** Keycloak
- **Identity service:** OpenStack Keystone
- **Edge framework:** Stack4Things 
- **Authentication:** OIDC federation 
- **Platform:** Kubernetes

---

## 📜 License

MIT License © 2025
