# Dev Overlay

Lightweight overlay for development and testing. Uses small PVC sizes, minimal resource limits, and localhost health-check hosts. No ingress is configured -- access services via `kubectl port-forward`.

## Quick Start

### 1. Create the namespace and secret

```bash
BRANCH="my-feature"
NS="omero-dev-${BRANCH}"
kubectl create namespace "$NS"

kubectl -n "$NS" create secret generic omero-secrets \
  --from-literal=POSTGRES_DB=omero \
  --from-literal=POSTGRES_USER=omero \
  --from-literal=POSTGRES_PASSWORD='changeme' \
  --from-literal=OMERO_ROOT_PASSWORD='changeme' \
  --from-literal=ICEGRID_USER='root' \
  --from-literal=ICEGRID_PASS='omero'
```

### 2. (Optional) Set your StorageClass

Edit `patches/pvc-dev.yaml` and change the `storageClassName` to match your cluster:

```yaml
spec:
  storageClassName: "cinder-nova-xfs"  # change to your storage class
```

### 3. Deploy

The recommended way to deploy the dev overlay is via the ArgoCD template (see below), which automatically patches the NFS PersistentVolume with the correct namespace.

If deploying without ArgoCD, render the manifests first and substitute the NFS placeholder values for your namespace before applying:

Update the path to the `overlays/dev` directory.

```bash
OVERLAY_PATH="omero-kustomize/overlays/dev"
kubectl kustomize $OVERLAY_PATH | \
  sed "s/placeholder-omero-nfs/${NS}-omero-nfs/g; \
       s/nfs-export\.placeholder\.svc\.cluster\.local/nfs-export.${NS}.svc.cluster.local/g; \
       s/namespace: placeholder/namespace: ${NS}/g" | \
  kubectl apply -n "$NS" -f -
```

### 4. Access OMERO Web

```bash
kubectl -n "$NS" port-forward service/omeroweb 8080:4080
# Open http://localhost:8080
```

### 5. Access OMERO Server (for OMERO.insight)

```bash
kubectl -n "$NS" port-forward service/omeroserver 4064:4064
# Connect OMERO.insight to localhost:4064
```

## Deploy a Test Instance with ArgoCD

For teams using ArgoCD, this overlay includes a template (`argocd.yml.tmpl`) that spins up an isolated OMERO instance per branch. This lets multiple developers test in parallel without conflicts.

### 1. Create the secret in the target namespace

```bash
NS="omero-dev-${BRANCH}"

kubectl create namespace "$NS"

kubectl -n "$NS" create secret generic omero-secrets \
  --from-literal=POSTGRES_DB=omero \
  --from-literal=POSTGRES_USER=omero \
  --from-literal=POSTGRES_PASSWORD='changeme' \
  --from-literal=OMERO_ROOT_PASSWORD='changeme' \
  --from-literal=ICEGRID_USER='root' \
  --from-literal=ICEGRID_PASS='omero'
```

### 2. Apply the ArgoCD Application

Update the `BRANCH`, `REPO` and the `OVERLAY_PATH` below. 

```bash
BRANCH="my-feature"
REPO="git@github.com:ORG_NAME/repo_name.git"
OVERLAY_PATH="omero-kustomize/overlays/dev" # update to the correct path
sed "s|__BRANCH__|${BRANCH}|g; s|__NAME__|${NS}|g; s|__REPO_URL__|${REPO}|g; s|__PATH__|${OVERLAY_PATH}|g" \
  ${OVERLAY_PATH}/argocd.yml.tmpl | kubectl apply -f -
```

ArgoCD will automatically create the namespace (if `CreateNamespace=true` is set) and deploy the dev overlay from your branch.

### 3. Access the test instance

```bash
# OMERO Web
kubectl -n "$NS" port-forward service/omeroweb 8080:4080
# Open http://localhost:8080

# OMERO Server (for OMERO.insight)
kubectl -n "$NS" port-forward service/omeroserver 4064:4064
# Connect OMERO.insight to localhost:4064
```

### 4. Tear down

```bash
kubectl -n argocd delete application "$NS"
kubectl delete namespace "$NS"
```
