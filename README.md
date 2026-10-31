# k8s-gitops

This repository contains the GitOps configuration for my personal Kubernetes cluster hosted on Infomaniak (see [infra/infomaniak](infra/infomaniak/README.md)), managed using ArgoCD. It follows the "App of Apps" pattern to organize and deploy applications and infrastructure components.

## Getting Started

1. **ArgoCD Deployment**:
   - This configuration requires ArgoCD to be installed in the cluster. For instructions, visit [ArgoCD's documentation](https://argo-cd.readthedocs.io/en/stable/).

2. **Manual Configuration**:
   - The initial setup requires manual application of the `app-of-apps.yaml` manifest to register the core applications in ArgoCD.

```bash
kubectl apply -f app-of-apps.yaml
```
