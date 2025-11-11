# kubernetes-keystone-integration

Integration layer between **OpenStack Keystone** and **Kubernetes** to enable unified authentication, authorization, and resource synchronization across cloud and edge environments.

---

## Overview

This project aims to bridge **OpenStack Keystone** — the identity and access management service of OpenStack — with **Kubernetes**, providing a **single source of identity** for both cloud and edge resources.

---

## Architecture

The integration relies on a custom **Kubernetes Operator** (written in Go with Kubebuilder) that periodically synchronizes information between Keystone and the Kubernetes API.

![Architecture Diagram](images/architecture.png)

The operator includes several controllers:

| Controller | Description |
|-------------|-------------|
| **SyncController** | Coordinates synchronization between Keystone and Kubernetes |
| **ProjectController** | Maps Keystone projects to Kubernetes namespaces |
| **RoleController** | Maps Keystone roles and users to Kubernetes RBAC |
| **DeviceController** | Synchronizes IoTronic devices as custom Kubernetes resources |

---

## Goals

- Enable **Single Sign-On (SSO)** between OpenStack and Kubernetes via OIDC  
- Maintain **consistent multi-tenant RBAC policies** across systems  
- Represent **IoT/edge resources** (via Stack4Things) as Kubernetes-managed entities  
- Provide a foundation for **unified cloud-edge orchestration**

---

## Stack

- **Language:** Go (Kubebuilder)  
- **Identity provider:** OpenStack Keystone  
- **Edge framework:** Stack4Things (IoTronic)  
- **Authentication:** OIDC federation  
- **Target platform:** Kubernetes ≥ 1.28  

---

## 📜 License

MIT License © 2025
