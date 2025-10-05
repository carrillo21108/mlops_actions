terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

############################################################
# Taller / Demo: Separación Ingeniería de Datos vs Ciencia de Datos
# ----------------------------------------------------------
# Este archivo extiende el ejemplo mínimo para ilustrar cómo
# representar con Terraform (provider Docker) una arquitectura
# lógica donde:
# - Ingeniería de Datos administra capas raw / silver / gold / features
# - Ciencia de Datos entrena modelos consumiendo la capa de features
# - Se usan volúmenes para persistencia y una red para aislar tráfico
# - Se parametrizan tags y prefijos para facilitar ambientes
############################################################

####################
# Variables básicas #
####################
variable "image_tag" {
  type        = string
  description = "Tag de la imagen Docker del pipeline ML"
  default     = "dev"
}

variable "prefix" {
  type        = string
  description = "Prefijo para nombrar recursos (ej: dev, stg, prod)"
  default     = "dev"
}

variable "run_id" {
  type        = string
  description = "Identificador lógico de la ejecución batch / entrenamiento"
  default     = "local-run"
}

variable "network_name" {
  type        = string
  description = "Nombre de la red Docker para aislar flujo analítico"
  default     = "dev_analytics_net"
}

#############################
# Red aislada de analítica   #
#############################
resource "docker_network" "analytics" {
  name = var.network_name
  driver = "bridge"
}

#############################
# Volúmenes (Capas de Datos) #
#############################
resource "docker_volume" "raw"      { name = "${var.prefix}_raw" }
resource "docker_volume" "silver"   { name = "${var.prefix}_silver" }
resource "docker_volume" "gold"     { name = "${var.prefix}_gold" }
resource "docker_volume" "features" { name = "${var.prefix}_features" }
resource "docker_volume" "models"   { name = "${var.prefix}_models" }

# Construye la imagen leyendo el Dockerfile del directorio actual
resource "docker_image" "app" {
  # Imagen base del pipeline ML. Tag parametrizable.
  name = "titanic-pipeline:${var.image_tag}"

  build {
    context    = "./dockerbuild"  # raíz del módulo (.)
    dockerfile = "./Dockerfile"      # ruta relativa al context
    # Opcionales útiles:
    # target      = "builder"
    # no_cache    = true
    # build_arg   = { NODE_ENV = "production" }
    # label       = { "org.opencontainers.image.source" = "https://..." }
  }

  # Si usas etiquetas adicionales
  # triggers = { always = timestamp() } # fuerza rebuild en cada apply (opcional)
}

# Opcional: ejecutar un contenedor con esa imagen
resource "docker_container" "app" {
  # Contenedor simple (baseline) - mantiene el ejemplo original.
  name  = "${var.prefix}-base-help"
  image = docker_image.app.image_id
  command = ["--help"]
  networks_advanced { name = docker_network.analytics.name }
  restart = "no"
}

###########################################################
# Contenedores Lógicos de Ingeniería de Datos (Ejemplos)   #
###########################################################
# NOTA: Estos contenedores usan comandos placeholder (echo/sleep)
# para ilustrar el flujo. En un escenario real se sustituirían
# por scripts Python / CLI que hagan ETL, limpieza y feature engineering.

# 1) Raw -> Silver (limpieza básica)
resource "docker_container" "etl_raw_to_silver" {
  name  = "${var.prefix}-etl-raw-silver-${var.run_id}"
  image = docker_image.app.image_id
  command = ["sh", "-c", "echo 'Iniciando ETL Raw->Silver'; sleep 2; echo 'Limpieza simulada';"]
  volumes {
    volume_name    = docker_volume.raw.name
    container_path = "/data/raw"
  }
  volumes {
    volume_name    = docker_volume.silver.name
    container_path = "/data/silver"
  }
  networks_advanced { name = docker_network.analytics.name }
  restart = "no"
}

# 2) Silver -> Gold (unificación / agregaciones)
resource "docker_container" "etl_silver_to_gold" {
  name  = "${var.prefix}-etl-silver-gold-${var.run_id}"
  image = docker_image.app.image_id
  command = ["sh", "-c", "echo 'Transformando Silver->Gold'; sleep 2; echo 'Features intermedias';"]
  depends_on = [docker_container.etl_raw_to_silver]
  volumes {
    volume_name    = docker_volume.silver.name
    container_path = "/data/silver"
  }
  volumes {
    volume_name    = docker_volume.gold.name
    container_path = "/data/gold"
  }
  networks_advanced { name = docker_network.analytics.name }
  restart = "no"
}

# 3) Gold -> Features (selección / encoding persistido)
resource "docker_container" "feature_engineering" {
  name  = "${var.prefix}-features-${var.run_id}"
  image = docker_image.app.image_id
  command = ["sh", "-c", "echo 'Generando features'; sleep 2; echo 'Features listas';"]
  depends_on = [docker_container.etl_silver_to_gold]
  volumes {
    volume_name    = docker_volume.gold.name
    container_path = "/data/gold"
  }
  volumes {
    volume_name    = docker_volume.features.name
    container_path = "/data/features"
  }
  networks_advanced { name = docker_network.analytics.name }
  restart = "no"
}

###########################################################
# Contenedor de Ciencia de Datos (Entrenamiento)           #
###########################################################
resource "docker_container" "model_training" {
  name  = "${var.prefix}-train-${var.run_id}"
  image = docker_image.app.image_id
  # En un flujo real, el CSV de features estaría en /data/features
  # Aquí usamos el CLI existente para entrenar; reemplaza 'features.csv'
  # con el archivo real que se genere en la etapa previa.
  command = [
    "titanic-pipeline",
    "train",
    "--csv", "/data/features/features.csv",
    "--model-out", "/models/titanic_model.joblib"
  ]
  depends_on = [docker_container.feature_engineering]
  volumes {
    volume_name    = docker_volume.features.name
    container_path = "/data/features"
  }
  volumes {
    volume_name    = docker_volume.models.name
    container_path = "/models"
  }
  networks_advanced { name = docker_network.analytics.name }
  restart = "no"
}

#########################
# Outputs informativos  #
#########################
output "network_name" { value = docker_network.analytics.name }
output "volumes" {
  value = {
    raw      = docker_volume.raw.name
    silver   = docker_volume.silver.name
    gold     = docker_volume.gold.name
    features = docker_volume.features.name
    models   = docker_volume.models.name
  }
}
output "image_name" { value = docker_image.app.name }
output "training_container" { value = docker_container.model_training.name }
