# Fridge Chef -- release v0.1.0
#
# This file IS the release. Both references below are immutable hashes, not
# movable tags:
#   - the module is pinned to a git commit SHA  (tag module-v1.0.0)
#   - the image is pinned to a registry digest  (tag v0.1.0)

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
  source = "git::ssh://git@github.com/ichtar/FridgeChef.git//modules/fridgechef?ref=738d60b19d29336c82e1108e269ed22ffdf3a2ec"

  image_ref = "docker.io/ichtar/fridgechef-app@sha256:e2f1fef694d4e9030ef291f14ee8cbbeb649bab456df21c08a104c3468783dcf"
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
