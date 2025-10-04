resource "docker_image" "pipeline" {
  name = "${var.image_repo}:${var.image_tag}"
  build {
    context    = var.root_path
    dockerfile = "Dockerfile"
  }
}

output "image_name" { value = docker_image.pipeline.name }
