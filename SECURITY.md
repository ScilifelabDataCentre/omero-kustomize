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

## Handling secrets

Secrets (the `omero-secrets` Secret) must **never** be committed to this
repository. They are supplied at deploy time on the cluster (see the
[Secrets Reference](README.md#secrets-reference) and [CONTRIBUTING.md](CONTRIBUTING.md)).

If a secret is ever committed, treat it as compromised: rotate the affected
credentials immediately and remove the value from the repository history.
