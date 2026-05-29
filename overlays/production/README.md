# Production Overlay

Production-ready overlay with ingress (Gateway API HTTPRoute), NodePort for OMERO.insight clients. Requires domain configuration and a Gateway API implementation.

## Deployment Steps

### 1. Customize your domain

Replace `omero.example.com` in these files with your actual domain:

- `patches/omeroweb-prod.yaml`
- `ingress/omeroweb-routes.yaml`

```bash
# Quick find-and-replace
grep -rl "omero.example.com" . | \
  xargs sed -i 's/omero\.example\.com/omero.yourdomain.org/g'
```

### 2. Configure storage

Edit `patches/pvc-prod.yaml` and set the StorageClass and size for your cluster:

```yaml
spec:
  storageClassName: "your-storage-class"
  resources:
    requests:
      storage: 500Gi  # adjust to your needs
```

### 3. Configure the Gateway / NodePort

The production overlay includes:
- **HTTPRoute** (`ingress/omeroweb-routes.yaml`): Routes web traffic to OMERO Web and thumbnail requests to the thumbnail microservice. Update `parentRefs` to match your Gateway resource.
- **NodePort** (`ingress/omeroserver-nodeport.yaml`): Exposes port 4064 for OMERO.insight desktop clients. Adjust the `nodePort` value (default: 30012) if needed.

### 4. Create the namespace and secret

```bash
NS="omero-production"
kubectl create namespace "$NS"

kubectl -n "$NS" create secret generic omero-secrets \
  --from-literal=POSTGRES_DB=omero \
  --from-literal=POSTGRES_USER=omero \
  --from-literal=POSTGRES_PASSWORD='<strong-password>' \
  --from-literal=OMERO_ROOT_PASSWORD='<strong-password>' \
  --from-literal=ICEGRID_USER='root' \
  --from-literal=ICEGRID_PASS='<strong-password>'
```
**OR**

### 4.1 Using Sealed Secrets

For production, consider using [Sealed Secrets](https://sealed-secrets.netlify.app/). First generate a plain Secret manifest, then seal it:

```bash
kubectl -n "$NS" create secret generic omero-secrets \
  --from-literal=POSTGRES_DB=omero \
  --from-literal=POSTGRES_USER=omero \
  --from-literal=POSTGRES_PASSWORD='<strong-password>' \
  --from-literal=OMERO_ROOT_PASSWORD='<strong-password>' \
  --from-literal=ICEGRID_USER='root' \
  --from-literal=ICEGRID_PASS='<strong-password>' \
  --dry-run=client -o yaml > /tmp/omero-secrets-$NS.yaml
```

Update the path to the `overlays/production` directory.

```bash
kubeseal --format yaml -n "$NS" \
  < /tmp/omero-secrets-$NS.yaml \
  > path/to/overlays/production/sealedsecret-omero.yaml
```

```bash
rm /tmp/omero-secrets-$NS.yaml
```

Then uncomment `sealedsecret-omero.yaml` in the `resources:` list in `overlays/production/kustomization.yaml`.

### 5. Deploy

Render the manifests and substitute the NFS placeholder values for your namespace before applying:

Update the path to the `overlays/production` directory.
```bash
kubectl kustomize path/to/overlays/production | \
  sed "s/placeholder-omero-nfs/${NS}-omero-nfs/g; \
       s/nfs-export\.placeholder\.svc\.cluster\.local/nfs-export.${NS}.svc.cluster.local/g; \
       s/namespace: placeholder/namespace: ${NS}/g" | \
  kubectl apply -n "$NS" -f -
```

If using Argo CD instead, the inline patches handle this automatically (see below).

## Deploy with Argo CD

### 1. Complete the configuration steps

Before deploying with Argo CD, complete steps 1-3 above:

1. Customize your domain (replace `omero.example.com`)
2. Configure storage (set StorageClass and sizes)
3. Configure the Gateway / NodePort (update `parentRefs`)

Commit these changes to your repository.

### 2. Create the namespace and secret

Argo CD creates the namespace automatically (`CreateNamespace=true`), but the secret must be created beforehand (see step 4 above or use Sealed Secrets).

### 3. Apply the Argo CD Application

This overlay includes a template (`argocd.yml.tmpl`) with placeholders. Substitute your values and apply:

Update the `NS`, `REPO`, `BRANCH` and `STORAGE` below.

```bash
NS="omero-production" # update to the correct namespace
REPO="git@github.com:ORG_NAME/repo_name.git" # update to the correct repo
BRANCH="main"
OVERLAY_PATH="omero-kustomize/overlays/production" # update to the correct path
STORAGE="500Gi"

sed "s|__NS__|${NS}|g; s|__REPO_URL__|${REPO}|g; s|__BRANCH__|${BRANCH}|g; s|__STORAGE_SIZE__|${STORAGE}|g; s|__PATH__|${OVERLAY_PATH}|g" \
  ${OVERLAY_PATH}/argocd.yml.tmpl | kubectl apply -f -
```

### 4. Verify

```bash
kubectl -n argocd get application "$NS" -o wide
kubectl -n "$NS" get pods
```
