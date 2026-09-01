# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in this repository, please report it
privately by emailing **omero@scilifelab.se**. Do not open a public issue or
pull request for security problems.

When reporting, please include as much of the following as you can:

- A description of the vulnerability and its potential impact.
- The affected overlay or manifest (e.g. `base/...`, `overlays/production/...`).
- Steps to reproduce or a proof of concept.

You can expect an acknowledgement of your report, and we will keep you informed
as we investigate and address the issue.

## Supported versions

Security fixes target the latest release and the `main` branch. Releases are
tagged `vX.Y.Z` via the manual release workflow
([.github/workflows/release.yml](.github/workflows/release.yml)). Please make
sure you are on the latest release before reporting.

## Scope

This repository contains Kubernetes deployment configuration (Kustomize
manifests) for OMERO. It is **not** the OMERO application source code.

Vulnerabilities in the OMERO software itself or in the upstream container
images it uses (for example `openmicroscopy/*` and
`ghcr.io/scilifelabdatacentre/omero-server-extended`) should be reported to
their respective projects. This policy covers the manifests and configuration
maintained in this repository.

## Security model and assumptions

These manifests are written for a **trusted, single-tenant cluster**. The points below
are known properties of the current design, not undisclosed vulnerabilities, and they do
not need to be reported through the process above. Review them before deploying,
especially on a shared or multi-tenant cluster.

### Privileged and root workloads

- **The NFS export pod is privileged.** `nfs-export` in
  [base/storage/nfs-export.yaml](base/storage/nfs-export.yaml) runs with
  `privileged: true` because it mounts `nfsd` and starts a kernel NFS server.
  It is defined in `base/`, so both overlays are affected by this.

- **Two init containers run as root.** `fix-permissions` in
  [base/apps/omeroserver/deploy.yaml](base/apps/omeroserver/deploy.yaml) and `fix-perms` in
  [base/apps/database/deploy.yaml](base/apps/database/deploy.yaml) use `runAsUser: 0` to
  chown their volumes before the application container starts.
