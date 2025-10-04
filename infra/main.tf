############################
# Módulo de capa de datos  #
############################
module "data_layer" {
  source = "./modules/data_layer"
  prefix = var.prefix
}

############################
# Módulo de ML Training    #
############################
module "ml_training" {
  source         = "./modules/ml_training"
  prefix         = var.prefix
  image_repo     = var.image_repo
  image_tag      = var.image_tag
  root_path      = var.root_path
  run_id         = var.run_id
  network_name   = module.data_layer.network_name

  raw_volume_name      = module.data_layer.raw_volume
  silver_volume_name   = module.data_layer.silver_volume
  gold_volume_name     = module.data_layer.gold_volume
  features_volume_name = module.data_layer.features_volume
  models_volume_name   = module.data_layer.models_volume

  train_command = var.train_command
  env_extra     = var.env_extra
}
