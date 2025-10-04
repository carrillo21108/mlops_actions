# Taller: Terraform, Docker y Arquitectura de Datos/MLOps (Caso Titanic)

## Objetivos
1. Comprender los conceptos clave del lenguaje de Terraform y su relación con infraestructura declarativa.
2. Identificar y usar los recursos del *Docker Provider* en Terraform.
3. Diseñar una arquitectura que separe responsabilidades de Ingeniería de Datos y Ciencia de Datos.
4. Aplicar esa arquitectura al pipeline Titanic que existe en este repositorio (`src/ml_pipeline_titanic`).
5. Preparar bases para extender a CI/CD, versionado de modelos y despliegue.

## Prerrequisitos
- Terraform ≥ 1.5 instalado.
- Docker Desktop funcionando (daemon activo).
- Git configurado.
- Python 3.12 (coherente con `pyproject.toml`).

## 1. Terraform + Docker: Secciones Clave de la Documentación

| Tema | Documento / Recurso | Uso Principal |
|------|---------------------|---------------|
| Provider Docker | `registry.terraform.io/providers/kreuzwerker/docker` | Declarar conexión local o remota al daemon Docker. |
| `docker_image` (resource) | `/resources/image` | Construir o descargar imágenes. Permite build context y etiquetado. |
| `docker_container` (resource) | `/resources/container` | Crear contenedores, definir redes, variables de entorno, puertos. |
| `docker_network` (resource) | `/resources/network` | Aislar tráfico entre componentes (ej. data-engineering vs data-science). |
| `docker_volume` (resource) | `/resources/volume` | Persistencia para capas raw/silver/gold, feature store, artefactos. |
| `docker_registry_image` (data) | `/data-sources/registry_image` | Leer metadatos de imagen existente en un registry. |
| Autenticación | Config en `provider` | Manejar credenciales si se usa registry privado. |
| Variables / Outputs | Terraform Language | Parametrizar nombres, tags, rutas y exponer endpoints. |
| Backends Remotos | Terraform Language (`backend` block) | Guardar state en S3/Azure/GCS para trabajo colaborativo. |
| Módulos | Terraform Language (Modules) | Reutilizar patrones: un módulo para “data_layer”, otro para “ml_training”. |

### Ejemplo mínimo Provider Docker
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}
```

### Construir imagen del pipeline Titanic
```hcl
resource "docker_image" "titanic" {
  name = "titanic-pipeline:${var.image_tag}"
  build {
    context    = "${path.root}"
    dockerfile = "Dockerfile"
  }
}
```

### Ejecutar contenedor batch (ej. entrenamiento)
```hcl
resource "docker_container" "train" {
  name  = "titanic-train-${var.run_id}"
  image = docker_image.titanic.name
  env = [
    "MODE=train",
    "EXPERIMENT_NAME=titanic_baseline"
  ]
  command = ["python", "-m", "ml_pipeline_titanic.cli", "train"]
  volumes { host_path = docker_volume.features.mountpoint container_path = "/app/data/features" }
  networks_advanced { name = docker_network.analytics.name }
  restart = "no"
}
```

## 2. Separación Ingeniería de Datos vs Ciencia de Datos

| Dominio | Responsabilidad | Artefactos | Recursos Terraform sugeridos |
|---------|-----------------|-----------|------------------------------|
| Ingeniería de Datos | Ingesta, limpieza, normalización, publicación de tablas / features | Volúmenes raw, silver, gold; jobs de preparación | `docker_container` (batch ETL), `docker_volume`, `docker_network` |
| Ciencia de Datos | Exploración, entrenamiento, validación, empaquetado de modelo | Código Python, datasets transformados, modelos serializados | `docker_image`, `docker_container`, `docker_volume` (features, models) |
| Infra MLOps | Versionado, orquestación, state y registro | Terraform state, pipelines CI, (futuro: Model Registry) | Backend remoto, módulos, variables/outputs |

## 3. Capas de Datos Propuestas
1. Raw (Landing): datos ingestados sin transformar.
2. Silver (Clean/Conformed): datos limpios y unidos.
3. Gold (Features / Aggregations): features listos para entrenamiento.
4. Feature Store (persistencia reutilizable; puede ser el mismo gold al inicio).
5. Model Artifacts: modelos entrenados (ej. `model.pkl`).

Mapeo inicial usando volúmenes Docker:
```hcl
resource "docker_volume" "raw"      { name = "dv_raw" }
resource "docker_volume" "silver"   { name = "dv_silver" }
resource "docker_volume" "gold"     { name = "dv_gold" }
resource "docker_volume" "features" { name = "dv_features" }
resource "docker_volume" "models"   { name = "dv_models" }
```

## 4. Arquitectura (ASCII)
```
                +-----------------------------+
                |        Terraform (IaC)      |
                |  - módulos docker           |
                |  - state remoto (futuro)    |
                +--------------+--------------+
                               |
                 (docker provider resources)
                               |
     +------------------ docker_network: analytics ------------------+
     |                                                              |
+-----------+        +----------------+        +----------------+   |
| Ingest/ETL|  -->   |  Transform     |  -->   |  Feature Build |   |
| Container |        |  Container(s)  |        |  Container     |   |
+-----+-----+        +-------+--------+        +--------+-------+   |
      |                        |                        |           |
  raw vol                  silver vol                gold/features  |
      |                        |                        |           |
      +------------+-----------+                        |           |
                   |                                    v           |
                   |                             +-------------+    |
                   |                             |  Train /    |    |
                   |                             |  Evaluate   |    |
                   |                             +------+------+    |
                   |                                    |           |
                   |                              models volume     |
                   |                                    |           |
                   |                             (future serving)   |
                   +------------------------------------------------+
```

## 5. Organización de Código Terraform (Sugerida)
```
infra/
  main.tf
  variables.tf
  outputs.tf
  versions.tf
  modules/
    data_layer/
      volumes.tf
      network.tf
      etl_containers.tf
    ml_training/
      image.tf
      train_container.tf
    shared/
      logging.tf (futuro)
```

### Ejemplo `modules/data_layer/volumes.tf`
```hcl
resource "docker_volume" "raw"      { name = var.prefix != "" ? "${var.prefix}_raw" : "raw" }
resource "docker_volume" "silver"   { name = var.prefix != "" ? "${var.prefix}_silver" : "silver" }
resource "docker_volume" "gold"     { name = var.prefix != "" ? "${var.prefix}_gold" : "gold" }
output "raw_volume"    { value = docker_volume.raw.name }
output "silver_volume" { value = docker_volume.silver.name }
output "gold_volume"   { value = docker_volume.gold.name }
```

### Ejemplo `modules/ml_training/image.tf`
```hcl
resource "docker_image" "pipeline" {
  name = "${var.image_repo}:${var.image_tag}"
  build {
    context    = var.root_path
    dockerfile = "Dockerfile"
  }
}
output "image_name" { value = docker_image.pipeline.name }
```

## 6. Variables Clave
| Variable | Uso | Ejemplo |
|----------|-----|---------|
| `image_tag` | Versionar imagen según commit | `git rev-parse --short HEAD` |
| `run_id` | Diferenciar ejecuciones batch | `timestamp()` generado externo |
| `prefix` | Namespacing por ambiente | `dev`, `stg`, `prod` |
| `image_repo` | Nombre base de la imagen | `titanic-pipeline` |

## 7. Ejecución Local (Flujo Manual)
1. Crear carpeta `infra/` y colocar archivos Terraform.
2. `terraform init`
3. `terraform plan -var="image_tag=dev" -var="run_id=local1"`
4. `terraform apply -auto-approve -var="image_tag=dev" -var="run_id=local1"`
5. Ver contenedores: `docker ps -a`.
6. Logs del entrenamiento: `docker logs <nombre>`.
7. Destruir: `terraform destroy`.

## 8. Integración con CI/CD (Futuro)
- Workflow GitHub Actions:
  - Paso 1: Lint (pre-commit / flake8 / ruff) del código Python.
  - Paso 2: Construir imagen Docker y hacer `docker push` (si se define registry).
  - Paso 3: `terraform fmt -check && terraform validate`.
  - Paso 4: `terraform plan` (con backend remoto) y revisión manual.
  - Paso 5: `terraform apply` automatizado en rama principal o con environment protection.

## 9. Buenas Prácticas
- Mantener build determinístico (pin de versiones en `pyproject.toml` / `requirements.txt`).
- Usar etiquetas semánticas (`v1.2.0`) + corto de commit para reproducibilidad.
- Backend remoto (S3 + DynamoDB lock / Azure Storage / GCS) en cuanto haya >1 colaborador.
- Separar estados: `infra-data` y `infra-ml` si crece la complejidad.
- Módulos versionados (tag del repositorio o registry de módulos privado/publico).
- Validación de drift: `terraform plan` programado (cron) y alerta en caso de cambios no aplicados.

## 10. Ejercicios Prácticos
### Ejercicio 1: Provider y Volúmenes
Crear `infra/main.tf` con provider docker y tres volúmenes (`raw`, `silver`, `gold`). Aplicar y verificar en `docker volume ls`.

### Ejercicio 2: Imagen del Pipeline
Agregar `docker_image` que construye usando el `Dockerfile` actual. Parametrizar `image_tag`.

### Ejercicio 3: Contenedor de Entrenamiento
Crear `docker_container` que ejecute `python -m ml_pipeline_titanic.cli train` y monte `gold` como `/app/data/features` y `models` como `/app/models`.

### Ejercicio 4: Red Privada
Definir un `docker_network` y asociar tanto contenedor ETL (dummy) como el de entrenamiento para aislarlos.

### Ejercicio 5: Módulos
Extraer volúmenes y red a un módulo `data_layer`. Referenciarlo desde `main.tf`.

### Ejercicio 6: Versionado de Imágenes
Automatizar `image_tag` leyendo un valor exportado externamente (por ahora pasar como variable de CLI). Probar cambiando el tag y verificando múltiples imágenes.

### Ejercicio 7 (Opcional): Backend Remoto
Configurar backend S3 (o equivalente) y migrar el state. Confirmar con `terraform state list` que permanece íntegro.

### Ejercicio 8 (Opcional): Validación de Drift
Eliminar manualmente un volumen y correr `terraform plan` para observar el cambio que propone.

## 11. Roadmap de Extensión
- Orquestación: introducir Airflow / Prefect en nuevos contenedores.
- Feature Store gestionado (Feast) montado sobre `dv_features`.
- Model Registry (MLflow) en su propio módulo y contenedor.
- Serving: contenedor FastAPI para inferencias con modelo de `dv_models`.
- Observabilidad: logs centralizados + métricas (Prometheus + Grafana) vía módulos adicionales.

## 12. Resumen
Esta guía conecta la definición declarativa de infraestructura (Terraform) con la separación clara de dominios (Data Engineering vs Data Science) usando Docker como capa de ejecución aislada. Comenzamos con recursos locales y un state simple, pero la estructura modular propuesta habilita escalar a entornos colaborativos, multi-ambiente y con gobernanza de modelos.

---
Fin del taller.
