# docker/ -- the demo image

Build context for `docker.io/ichtar/fridgechef-app`, the container the
releases deploy. It is a single static nginx page: a big version label on
a full-bleed colour, so a browser refresh is all it takes to see a
rollout land -- blue `v0.1.0` flips to green `v0.2.0`, rollback flips it
back.

```
Dockerfile            nginx:1.27-alpine + the substituted page
index.html.template   {{VERSION}} {{COLOR}} {{TEXT}} placeholders
Makefile              build + push a version to Docker Hub
```

The page is baked at build time from three build args:

| arg | what it sets | example |
|-----|--------------|---------|
| `VERSION` | the `<h1>` label | `v0.1.0` |
| `COLOR`   | the full-page background (`#rrggbb` or a CSS name) | `#2563eb` |
| `TEXT`    | the tagline under the version | `Fresh recipes of the day` |

## Colour palette

Any CSS colour works; these read well as a full-bleed background with
white text, and keep successive releases visually distinct:

| name | hex | | name | hex |
|------|-----|-|------|-----|
| blue   | `#2563eb` | | teal   | `#0d9488` |
| green  | `#16a34a` | | cyan   | `#0891b2` |
| amber  | `#f59e0b` | | pink   | `#db2777` |
| red    | `#dc2626` | | slate  | `#475569` |
| purple | `#7c3aed` | | black  | `#111827` |

`make palette` prints a short version of this.

## Publish a version (Makefile)

Run from this directory:

```bash
make publish VERSION=v0.3.0 COLOR='#f59e0b' TEXT='Winter warmers'
```

- quote the colour so the shell keeps the `#`;
- `VERSION` is required, `COLOR` defaults to blue, `TEXT` to `Fridge Chef`;
- override the target repo with `REPO=...` if needed.

It runs `docker build --provenance=false` -> `docker push` -> prints:

```
pin this in ../main.tf as image_ref:
docker.io/ichtar/fridgechef-app@sha256:<digest>
```

Other targets: `make build`, `make push`, `make digest`, `make help`.

## Equivalent raw commands

```bash
docker build --provenance=false \
  --build-arg VERSION=v0.3.0 --build-arg COLOR='#f59e0b' --build-arg TEXT='Winter warmers' \
  -t ichtar/fridgechef-app:v0.3.0 .
docker push ichtar/fridgechef-app:v0.3.0
docker inspect --format='{{index .RepoDigests 0}}' ichtar/fridgechef-app:v0.3.0
```

## Reproducibility

The base image is pinned (`nginx:1.27-alpine`) and `--provenance=false`
keeps the build to a single plain manifest, so rebuilding the same
`VERSION`/`COLOR`/`TEXT` produces the **same digest**. What the current
releases pin:

| release | build args | digest |
|---------|-----------|--------|
| `v0.1.0` | `VERSION=v0.1.0 COLOR=#2563eb TEXT='Fresh recipes of the day'` | `sha256:e2f1fef694d4e9030ef291f14ee8cbbeb649bab456df21c08a104c3468783dcf` |
| `v0.2.0` | `VERSION=v0.2.0 COLOR=#16a34a TEXT='Autumn menu'` | `sha256:7d08f489c42573bf630150b471e3fd48ad7175db87eeb843cc471cf0e01d451c` |

If a rebuild yields a different digest (e.g. `nginx:1.27-alpine` moved
upstream), cut a **new** release pinning the new digest -- never
force-push an image tag a release already points at.

## Cutting a new version

1. `make publish VERSION=vX.Y.Z COLOR='#...' TEXT='...'`
2. Copy the printed digest into `../main.tf` `image_ref`.
3. Commit, tag `vX.Y.Z`, push.
