# fridgechef module -- rev module-v1.1.0
#
# Difference from module-v1.0.0:
#   - docker_container gains restart = "unless-stopped"
#   - a traceability label is added
# Both show up as a real change in `terraform plan` when a release adopts
# this rev.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "image_ref" {
  type        = string
  description = "Image to deploy, by digest: docker.io/ichtar/fridgechef-app@sha256:..."
}

variable "host_port" {
  type    = number
  default = 8080
}

variable "container_name" {
  type    = string
  default = "fridgechef-app"
}

resource "docker_image" "app" {
  name         = var.image_ref
  keep_locally = false
}

resource "docker_container" "app" {
  name    = var.container_name
  image   = docker_image.app.image_id
  restart = "unless-stopped" # new in module-v1.1.0

  labels {
    label = "fridgechef.module_rev"
    value = "module-v1.1.0"
  }

  ports {
    internal = 80
    external = var.host_port
  }
}

output "url" {
  value = "http://localhost:${var.host_port}"
}

output "deployed_image" {
  value = var.image_ref
}

output "module_rev" {
  value = "module-v1.1.0"
}
