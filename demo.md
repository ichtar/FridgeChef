# Fridge Chef -- live demo

Customer side only. Run the commands top to bottom.

## Setup

Nothing to prepare. The images live on Docker Hub
(`docker.io/ichtar/fridgechef-app`) and `terraform apply` pulls them by
digest.

```bash
cd "$(mktemp -d)"
git clone git@github.com:ichtar/FridgeChef.git
cd FridgeChef
```

**macOS:** Docker Desktop's socket is not at `/var/run/docker.sock`, where
the Terraform docker provider looks. Point it at the real one first:

```bash
export DOCKER_HOST="$(docker context inspect --format '{{.Endpoints.docker.Host}}')"
```

(or Docker Desktop -> Settings -> Advanced -> "Allow the default Docker
socket to be used").

---

## 1. Get release v0.1.0

```bash
git checkout v0.1.0
sed -n '/module "fridgechef"/,/}/p' main.tf
```

The module block is the whole release. `source` pins the Terraform module
to a git commit (`?ref=<40 hex>`); `image_ref` pins the container image to
a registry digest (`@sha256:<64 hex>`). Both are immutable -- no tag to
move.

## 2. Deploy it

```bash
terraform init      # clones the module from git at that commit
terraform apply     # answer: yes
```

Outputs:

```
deployed_image = "docker.io/ichtar/fridgechef-app@sha256:e2f1fef6..."
module_rev     = "module-v1.0.0"
url            = "http://localhost:8080"
```

Open **http://localhost:8080** -- blue page, `v0.1.0`.

## 3. Move to release v0.2.0

```bash
git checkout v0.2.0
git diff v0.1.0 v0.2.0 -- main.tf
terraform init      # the module ref changed, so re-clone it
terraform apply     # answer: yes
```

The diff is the module `?ref=` SHA, the `image_ref` digest, and the file's
own header comment -- nothing else.

`terraform plan` replaces the container. Its output changes are exact:

```
~ deployed_image = "...@sha256:e2f1fef6..." -> "...@sha256:7d08f489..."
~ module_rev     = "module-v1.0.0" -> "module-v1.1.0"
```

and in the resource diff `restart` goes `"no" -> "unless-stopped"` and a
`fridgechef.module_rev` label is added -- the module-v1.1.0 changes.

Open **http://localhost:8080** -- green page, `v0.2.0`.

```bash
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' fridgechef-app
```

prints `unless-stopped` -- the module rev really changed, not just the image.

## 4. Roll back

Same move, earlier tag:

```bash
git checkout v0.1.0
terraform init
terraform apply     # answer: yes
```

Blue `v0.1.0` again, and `restart` is back to `no`: the module rolled back
with the image, because the release tag pins both.

---

## Reset between runs

```bash
terraform destroy -auto-approve       # from inside the clone
cd .. && rm -rf FridgeChef
docker rm -f fridgechef-app
```
