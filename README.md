# mlops_actions

Pipeline de sklearn para Titanic con CLI y Docker.

## Uso local

Instala el paquete en editable y ejecuta el CLI:

```powershell
pip install -e .
titanic-pipeline --help
```

Entrenar un modelo:

```powershell
titanic-pipeline train --csv "ruta\al\titanic_train.csv" --model-out models\titanic_model.joblib
```

Predecir:

```powershell
titanic-pipeline predict --model models\titanic_model.joblib --input "ruta\a\nuevos_datos.csv" --output preds\predicciones.csv
```

Las columnas requeridas para entrenar/predecir son:
- Age, Fare, SibSp, Parch, Pclass, Sex, Embarked

## Docker

Construir la imagen:

```powershell
docker build -t titanic-pipeline:latest .
```

Ver ayuda del CLI dentro del contenedor:

```powershell
docker run --rm titanic-pipeline:latest --help
```

Entrenar dentro de Docker montando datos locales (PowerShell):

```powershell
$PWD = (Get-Location).Path
docker run --rm -v "$PWD\data":/data -v "$PWD\models":/models titanic-pipeline:latest `
	train --csv /data/titanic_train.csv --model-out /models/titanic_model.joblib
```

Predecir dentro de Docker:

```powershell
$PWD = (Get-Location).Path
docker run --rm -v "$PWD\data":/data -v "$PWD\models":/models -v "$PWD\preds":/preds titanic-pipeline:latest `
	predict --model /models/titanic_model.joblib --input /data/nuevos_datos.csv --output /preds/predicciones.csv
```

Notas:
- Ajusta las rutas a tus archivos locales. En Windows PowerShell usa rutas con backslash al lado del host, dentro del contenedor usa rutas POSIX (/data, /models, /preds).