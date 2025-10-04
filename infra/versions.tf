terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  # backend "s3" {}  # (Opcional) Configurar cuando se tenga un backend remoto
}

provider "docker" {}
