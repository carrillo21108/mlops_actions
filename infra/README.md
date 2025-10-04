# Infraestructura Terraform (Docker + MLOps)

Este directorio contiene una implementación mínima de la arquitectura descrita en `docs/taller_terraform_ml.md` para separar responsabilidades de datos y entrenamiento.

## Contenido
- `versions.tf`: Definición de provider Docker y versión de Terraform.
- `variables.tf`: Variables principales (tag, run_id, prefix, etc.).
- `main.tf`: Orquesta los módulos `data_layer` y `ml_training`.
- `outputs.tf`: Exposición de artefactos clave (imagen, contenedor, volúmenes).
- `modules/data_layer`: Crea volúmenes y red compartida.
- `modules/ml_training`: Construye imagen y lanza contenedor de entrenamiento.

## Requisitos Previos
1. Docker en ejecución (daemon activo)
2. Terraform >= 1.5
3. Código Python y `Dockerfile` disponibles en la carpeta raíz (un nivel arriba de `infra/`).

## Uso Rápido
```powershell
cd infra
terraform init
terraform plan -var "image_tag=dev" -var "run_id=local1"
terraform apply -auto-approve -var "image_tag=dev" -var "run_id=local1"
```

Ver contenedor:
```powershell
docker ps -a | Select-String "train"
```

Logs:
```powershell
docker logs dev-train-local1
```

Destruir:
```powershell
terraform destroy -auto-approve
```

## Personalización
- Cambiar `prefix` para aislar ambientes (`-var "prefix=stg"`).
- Agregar variables de entorno extra: `-var 'env_extra={"MLFLOW_TRACKING_URI"="http://mlflow:5000"}'`.
- Modificar comando de entrenamiento en `variables.tf` (`train_command`).

## Extensiones Futuras
- Backend remoto (S3/Azure/GCS) activando el bloque `backend` en `versions.tf`.
- Módulo de serving para inferencias.
- Integración con un workflow de CI/CD (GitHub Actions) para validar y aplicar cambios.

---
Fin.
