# Fridge Chef -- release v0.2.0
#
# This file IS the release. Both references below are immutable hashes, not
# movable tags:
#   - the module is pinned to a git commit SHA  (tag module-v1.1.0)
#   - the image is pinned to a registry digest  (tag v0.2.0)
#
# Compared with v0.1.0 exactly those two references move.

terraform {
  required_version = ">= 1.3"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

module "fridgechef" {
  source = "git::ssh://git@github.com/ichtar/FridgeChef.git//modules/fridgechef?ref=263924bb1aa231cbfa7d0b54c991ef67167b6245"

  image_ref = "docker.io/ichtar/fridgechef-app@sha256:7d08f489c42573bf630150b471e3fd48ad7175db87eeb843cc471cf0e01d451c"
  host_port = 8080
}

output "url" {
  value = module.fridgechef.url
}

output "deployed_image" {
  value = module.fridgechef.deployed_image
}

output "module_rev" {
  value = module.fridgechef.module_rev
}
