# fridgechef module -- rev module-v1.0.0
#
# Deploys one image (by digest) as a local container.

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
  name  = var.container_name
  image = docker_image.app.image_id

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
  value = "module-v1.0.0"
}
