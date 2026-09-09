# Fridge Chef -- release repository

The deployment contract between Fridge Chef (the vendor) and a customer
tenant. A **release** is a git tag and contains Terraform only: `main.tf`
(the release root) and `modules/fridgechef/` (the module it consumes -- a
`docker_image` + `docker_container` and three outputs).

The customer clones this repo, checks out a release tag, and runs
`terraform apply`. The vendor never connects in: the customer pulls the
repo, the module (from git at a pinned commit), and the image (from Docker
Hub at a pinned digest).

## Repository layout

```
main.tf                the release root -- `terraform apply` here
modules/fridgechef/    the module the root consumes
docker/                how the deployed image is built (see below)
architecture/          the enterprise design doc for this delivery model
demo.md                a local, customer-side walkthrough: release + rollback
```

`docker/`, `architecture/` and `demo.md` live on `main` only. Checking out
a release tag (`v0.1.0`, `v0.2.0`, ...) gives you just the Terraform --
`main.tf`, `modules/`, `.gitignore`, `README.md`.

### `docker/`

Build context and tooling for `docker.io/ichtar/fridgechef-app`, the
container the releases deploy:

- `Dockerfile` + `index.html.template` -- an nginx page whose version
  label and background colour are baked in at build time;
- `Makefile` -- `make publish VERSION=v0.3.0 COLOR='#f59e0b' TEXT='...'`
  builds `--provenance=false`, pushes the tag, and prints the
  `@sha256:` digest to pin in `main.tf`;
- `README.md` -- the colour palette and the digests the current releases
  pin, with a reproducibility note.

The demo images are already on Docker Hub; you only need `docker/` to cut
a **new** image version.

### `architecture/`

"Fridge Chef goes Enterprise" -- the design doc behind this repo: why ECS
over Kubernetes or image+VM, why git-based distribution over a cloud
marketplace, product lifecycle, observability (push-mode Prometheus to a
central single pane of glass), security, the scale limits of a two-person
team, and a first-30-minutes support runbook. Section 8 embeds the
architecture diagrams from `architecture/diagrams/`.

## Releases are git tags

| Tag | Image (digest-pinned) | Module (commit-pinned) | What changed |
|-----|-----------------------|------------------------|--------------|
| `v0.1.0` | `fridgechef-app` v0.1.0 (blue) | `module-v1.0.0` | baseline |
| `v0.2.0` | `fridgechef-app` v0.2.0 (green) | `module-v1.1.0` | container gains `restart = "unless-stopped"` and a `fridgechef.module_rev` label |

Everything a release pins is an **immutable hash**, never a movable name:

- the module `source` ends in `?ref=<40-hex commit SHA>`, not `?ref=module-v1.0.0`;
- `image_ref` is `docker.io/ichtar/fridgechef-app@sha256:<64-hex>`, not `:v0.1.0`.

The tag names above are for humans reading this table. The repo pins the
hash, so re-pointing a git tag or re-pushing an image tag cannot change
what an already-cut release deploys.

`module-v1.0.0` / `module-v1.1.0` tag `modules/fridgechef/` on its own, so
the image and the module can move independently -- but a release tag fixes
the pair. Checking out `v0.1.0` yields a `main.tf` that names both; there
is nothing else to select and no way to end up mismatched.

## The release root (`main.tf`)

```hcl
module "fridgechef" {
  source    = "git::ssh://git@github.com/ichtar/FridgeChef.git//modules/fridgechef?ref=<module commit SHA>"
  image_ref = "docker.io/ichtar/fridgechef-app@sha256:<64 hex digest>"
  host_port = 8080
}
```

`source` points back at this repo at a pinned commit, so `terraform init`
fetches the module from git at that exact revision -- not from the working
tree. When a release moves the ref, `terraform init` must run again to
re-fetch.

## The module (`modules/fridgechef/`)

| Input | Default | Meaning |
|-------|---------|---------|
| `image_ref` | (required) | image to deploy, by digest (`...@sha256:...`) |
| `host_port` | `8080` | published port, forwarded to container `:80` |
| `container_name` | `fridgechef-app` | |

| Output | Meaning |
|--------|---------|
| `url` | `http://localhost:<host_port>` |
| `deployed_image` | the image reference deployed (digest) |
| `module_rev` | the module rev in effect (`module-v1.0.0` / `module-v1.1.0`) |

It creates a `docker_image` (pulled from Docker Hub by digest) and a
`docker_container` publishing `:80`.

## Consuming a release

```bash
git clone git@github.com:ichtar/FridgeChef.git
cd FridgeChef

git checkout v0.1.0
terraform init          # fetches the module at its pinned commit
terraform apply         # deploys image v0.1.0  -> blue page on :8080

git checkout v0.2.0
terraform init          # ref moved -> re-fetch the module
terraform apply         # deploys image v0.2.0  -> green page

git checkout v0.1.0     # rollback is the same move, an earlier tag
terraform init
terraform apply
```

## Cutting a release (vendor)

1. Build and push `docker.io/ichtar/fridgechef-app:<version>`; record its
   digest (`docker inspect --format='{{index .RepoDigests 0}}' ...`).
2. If the module changed: commit `modules/fridgechef/`, tag
   `module-v<x.y.z>`, and record the commit SHA (`git rev-parse HEAD`).
3. Write `main.tf` with the module `?ref=<SHA>` and `image_ref` at
   `@<digest>`; commit; tag the commit `v<version>`; push `main` with the
   tags.

## Requirements

- Docker daemon running.
- Outbound network: `docker.io/ichtar/fridgechef-app` (public) for the
  image, `git@github.com:ichtar/FridgeChef.git` for the module fetch (a read-only deploy key in
  production).

## Scope

A mechanism prototype. Not covered: image signature verification (trust
here is by digest but the digest itself is not signed), a private registry
with per-tenant pull grants (the image repo here is public Docker Hub), a
managed container runtime (the module runs a local `docker_container`),
and multi-tenant isolation.
