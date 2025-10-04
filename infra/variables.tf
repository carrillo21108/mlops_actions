variable "prefix" {
  description = "Prefijo para namespacing de recursos (dev/stg/prod)"
  type        = string
  default     = "dev"
}

variable "image_repo" {
  description = "Nombre base de la imagen Docker"
  type        = string
  default     = "titanic-pipeline"
}

variable "image_tag" {
  description = "Tag/version de la imagen (usar commit corto idealmente)"
  type        = string
  default     = "local"
}

variable "run_id" {
  description = "Identificador de ejecución batch (para contenedores efímeros)"
  type        = string
  default     = "run-local"
}

variable "root_path" {
  description = "Ruta de contexto para build Docker (proyecto raíz)"
  type        = string
  default     = ".." # la carpeta infra está un nivel por debajo del root
}

variable "train_command" {
  description = "Comando principal para entrenamiento"
  type        = list(string)
  default     = ["python", "-m", "ml_pipeline_titanic.cli", "train"]
}

variable "env_extra" {
  description = "Variables de entorno adicionales para el contenedor de entrenamiento"
  type        = map(string)
  default     = {}
}
