# Contributing

This repository holds the [Kustomize](https://kustomize.io/) manifests for deploying OMERO on Kubernetes. For an overview of the architecture and components, see the [README](README.md).

## Prerequisites

- `kubectl` (its built-in `kustomize` is sufficient), or a standalone [`kustomize`](https://kubectl.docs.kubernetes.io/installation/kustomize/) binary.
- (Optional) Access to an ArgoCD instance if you want to test changes on a live cluster.

## Repository layout

```
base/                 # Shared manifests for all environments
  apps/               # Application deployments
  storage/            # PVCs and NFS export
overlays/
  dev/                # Lightweight dev/test overlay
  production/         # Production overlay (ingress, larger resources)
```

## Making changes

- Edit `base/` for resources shared across all environments.
- Edit the relevant overlay's `patches/` for environment-specific tweaks (resource limits, storage sizes, domain, etc.). See the [Customization Reference](README.md#customization-reference) for where to change common settings.
- Never hardcode secrets. Sensitive values are provided at deploy time through the `omero-secrets` Secret (see the [Secrets Reference](README.md#secrets-reference)).

## Validate locally before pushing

Both overlays must render without error. This is the same gate enforced at release time by [.github/workflows/release.yml](.github/workflows/release.yml):

```bash
kubectl kustomize overlays/dev
kubectl kustomize overlays/production
```

If either command fails, fix the issue before opening a pull request.

## Branch and pull request workflow

1. Branch from `main`.
2. Make and validate your changes (see above).
3. Open a pull request against `main`.
4. `@ScilifelabDataCentre/teamberserkers` are required reviewers via [.github/CODEOWNERS](.github/CODEOWNERS); a review from the team is needed before merge.

## Testing a change on a cluster

The dev overlay supports spinning up an isolated, per-branch OMERO instance via ArgoCD, so multiple contributors can test in parallel. See [overlays/dev/README.md](overlays/dev/README.md) for the full steps.

## Releases

Releases are cut by maintainers using the manually triggered "Release" workflow ([.github/workflows/release.yml](.github/workflows/release.yml)):

1. Go to the repository's Actions tab and select the "Release" workflow.
2. Click "Run workflow" and enter a version tag (e.g. `v1.0.0`).
3. The workflow validates both overlays, then creates the git tag and a GitHub Release with auto-generated notes.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
