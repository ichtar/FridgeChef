# Fridge Chef -- release repository

The deployment contract between Fridge Chef (the vendor) and a customer
tenant. A **release** is a git tag (`v0.1.0`, `v0.2.0`, ...): the customer
clones this repo, checks out a release tag, and runs `terraform apply`.

The vendor never connects in. Everything is pulled by the customer: this
repo, the Terraform module (from git), and the container image (from
Docker Hub).

## Repository structure

```
main.tf                 the release root -- `terraform apply` runs here
modules/fridgechef/     the module it consumes (docker_image + docker_container)
docker/                 build context + Makefile for the deployed image
architecture/           enterprise design doc + diagrams
demo.md                 walkthrough: deploy, upgrade, roll back
```

`docker/`, `architecture/` and `demo.md` are supporting material, not part
of what a release deploys -- Terraform fetches only `modules/fridgechef/`
from the pinned commit. Each has its own README.

## Using a release

Needs a running Docker daemon, and outbound access to GitHub and Docker
Hub.

```bash
git checkout v0.1.0
terraform init      # fetches the module from git at its pinned commit
terraform apply
```

Upgrade or roll back by checking out another release tag and repeating --
`terraform init` again, because the module ref moved. See `demo.md`.

## What a release pins

| Release tag | Image | Module | What changed |
|-------------|-------|--------|--------------|
| `v0.1.0` | `fridgechef-app` v0.1.0 (blue) | `module-v1.0.0` | baseline |
| `v0.2.0` | `fridgechef-app` v0.2.0 (green) | `module-v1.1.0` | container gains `restart = "unless-stopped"` and a `fridgechef.module_rev` label |

A release tag points at a `main.tf` naming both by **immutable hash**,
never by a movable name:

```hcl
module "fridgechef" {
  source    = "git::ssh://.../FridgeChef.git//modules/fridgechef?ref=<commit SHA>"
  image_ref = "docker.io/ichtar/fridgechef-app@sha256:<digest>"
}
```

So re-pointing a git tag or re-pushing an image tag cannot change what an
already-cut release deploys.

The module is tagged separately (`module-v1.0.0`, `module-v1.1.0`), so
image and module can advance independently -- but a release tag freezes
one specific pair. There is nothing else to choose and no way to end up
mismatched.

## Cutting a release (vendor)

1. Build and push the image, and record its digest -- see `docker/`.
2. If the module changed: commit `modules/fridgechef/`, tag
   `module-vX.Y.Z`, record the commit SHA.
3. Point `main.tf` at both hashes, commit, tag `vX.Y.Z`, push with tags.

## Scope

A mechanism prototype. Not covered: image signature verification (trust is
by digest, but the digest itself is not signed), a private registry with
per-tenant pull grants (this image repo is public Docker Hub), a managed
container runtime (the module runs a local `docker_container`), and
multi-tenant isolation.
