output "image_name" {
  description = "Nombre completo de la imagen construida"
  value       = module.ml_training.image_name
}

output "train_container_name" {
  description = "Nombre del contenedor de entrenamiento"
  value       = module.ml_training.train_container_name
}

output "data_volumes" {
  description = "Volúmenes de datos creados en el módulo data_layer"
  value = {
    raw      = module.data_layer.raw_volume
    silver   = module.data_layer.silver_volume
    gold     = module.data_layer.gold_volume
    features = module.data_layer.features_volume
    models   = module.data_layer.models_volume
  }
}
