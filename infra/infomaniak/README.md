# Infomaniak cluster

Managed Kubernetes (KaaS) on Infomaniak Public Cloud: shared control plane, 2× `a4-ram8-disk20-perf1` workers in `dc4-a`.

## Provisioning

```sh
export INFOMANIAK_TOKEN=$(cat ~/.config/infomaniak/token)
cp terraform.tfvars.example terraform.tfvars  # fill in the IDs
terraform init
terraform apply
(umask 077; terraform output -raw kubeconfig > ~/.kube/infomaniak-ysi.yaml)
```

State is local and gitignored: it contains the kubeconfig.

## Bootstrapping Argo CD

A few secrets aren't in git and have to be copied from a running cluster (or recreated):

| Secret | Namespace | Used by |
|---|---|---|
| `op-credentials` | `kube-system` | 1Password Connect |
| `onepassword-token` | `kube-system` | 1Password operator |
| `cluster-…` (label `argocd.argoproj.io/secret-type: cluster`, name `bootc`) | `argocd` | Argo CD access to the on-prem cluster |

```sh
NEW=~/.kube/infomaniak-ysi.yaml
copy() { kubectl --context "$OLD" -n "$1" get secret "$2" -o json \
  | jq 'del(.metadata.uid,.metadata.resourceVersion,.metadata.creationTimestamp,.metadata.ownerReferences,.metadata.managedFields)' \
  | kubectl --kubeconfig $NEW apply -f -; }

kubectl --kubeconfig $NEW create namespace argocd
copy kube-system op-credentials
copy kube-system onepassword-token
copy argocd "$(kubectl --context "$OLD" -n argocd get secret -l argocd.argoproj.io/secret-type=cluster -o name | cut -d/ -f2)"

# Plain install; the argocd app takes it over with values/argocd.yaml once 1Password is up
# (the controller's WireGuard sidecar needs the 1Password-provided secret).
helm --kubeconfig $NEW install argocd argo-cd --repo https://argoproj.github.io/argo-helm \
  --version "$(yq '.spec.sources[0].targetRevision' ../../apps/argocd.yaml)" -n argocd
kubectl --kubeconfig $NEW apply -f ../../app-of-apps.yaml
kubectl --kubeconfig $NEW -n argocd delete secret -l owner=helm,name=argocd  # Argo CD owns it now
```

## Moving from DigitalOcean (one-time)

Only one Argo CD may manage the on-prem cluster and only one external-dns may own the
`siegrist.io` records, so the old cluster is frozen before the new one takes over.
Its workloads keep serving until DNS points away from them.

1. **Freeze DigitalOcean**: `kubectl --context do-fra1-ysi -n argocd scale statefulset argocd-application-controller --replicas 0`
   and `kubectl --context do-fra1-ysi -n external-dns scale deployment external-dns --replicas 0`.
   This must happen before the merge: the DO Argo CD would otherwise apply the Octavia load balancer config to DO.
2. Merge the migration PR.
3. Bootstrap Argo CD as above, but apply app-of-apps with external-dns held back so DNS
   doesn't switch before WordPress is restored:
   `yq '.spec.source.directory.exclude = "external-dns.yaml"' ../../app-of-apps.yaml | kubectl --kubeconfig $NEW apply -f -`
4. Restore WordPress: `mariadb-dump` from the DO MariaDB into the new one, copy `/bitnami/wordpress`
   across, and add the `wordpressExtraConfigContent` snippet from `values/arnold-wordpress.yaml` to the
   restored `wp-config.php`.
5. Check every host against the new load balancer IP: `curl --resolve <host>:443:<ip> https://<host>/`.
6. Pin the IP: set `loadBalancerIP` on the `public` EnvoyProxy's `envoyService`.
7. Hand DNS over: `kubectl --kubeconfig $NEW apply -f ../../app-of-apps.yaml` (without the exclude).
   external-dns uses the same TXT owner as before, so it updates the existing records.
8. Matrix is migrated separately; afterwards the DO cluster, its load balancer and volumes can be deleted.
