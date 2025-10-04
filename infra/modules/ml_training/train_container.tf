locals {
  base_env = {
    MODE            = "train"
    RUN_ID          = var.run_id
    EXPERIMENT_NAME = "titanic_baseline"
  }
  merged_env_list = [for k, v in merge(local.base_env, var.env_extra) : "${k}=${v}"]
}

resource "docker_container" "train" {
  name  = "${var.prefix}-train-${var.run_id}"
  image = docker_image.pipeline.name

  env = local.merged_env_list
  command = var.train_command

  networks_advanced { name = var.network_name }

  # Montajes de volúmenes relevantes
  mounts {
    target = "/app/data/raw"
    source = var.raw_volume_name
    type   = "volume"
  }
  mounts {
    target = "/app/data/silver"
    source = var.silver_volume_name
    type   = "volume"
  }
  mounts {
    target = "/app/data/gold"
    source = var.gold_volume_name
    type   = "volume"
  }
  mounts {
    target = "/app/data/features"
    source = var.features_volume_name
    type   = "volume"
  }
  mounts {
    target = "/app/models"
    source = var.models_volume_name
    type   = "volume"
  }

  restart = "no"
}

output "train_container_name" { value = docker_container.train.name }
