import argparse
import sys
import pandas as pd
import joblib
from pathlib import Path

from .pipeline import build_pipeline, train_pipeline, predict_pipeline


def cmd_train(args: argparse.Namespace) -> int:
    pipeline = train_pipeline(args.csv)
    model_out = Path(args.model_out)
    model_out.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(pipeline, model_out)
    print(f"Modelo guardado en: {model_out}")
    return 0


def cmd_predict(args: argparse.Namespace) -> int:
    model = joblib.load(args.model)
    df = pd.read_csv(args.input)

    # Asegurar columnas requeridas
    required_cols = ['Age', 'Fare', 'SibSp', 'Parch', 'Pclass', 'Sex', 'Embarked']
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise SystemExit(f"Faltan columnas requeridas en input: {missing}")

    X = df[required_cols]
    preds = predict_pipeline(model, X)

    out_df = pd.DataFrame({'prediction': preds})
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_df.to_csv(out_path, index=False)
    print(f"Predicciones guardadas en: {out_path}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="titanic-pipeline", description="Pipeline Titanic - train/predict")
    sub = p.add_subparsers(dest="command", required=True)

    p_train = sub.add_parser("train", help="Entrenar modelo desde CSV")
    p_train.add_argument("--csv", required=True, help="Ruta o URL al CSV de entrenamiento")
    p_train.add_argument("--model-out", required=True, help="Ruta de salida del modelo (.joblib)")
    p_train.set_defaults(func=cmd_train)

    p_pred = sub.add_parser("predict", help="Predecir usando un modelo guardado")
    p_pred.add_argument("--model", required=True, help="Ruta del modelo (.joblib)")
    p_pred.add_argument("--input", required=True, help="CSV con columnas requeridas")
    p_pred.add_argument("--output", required=True, help="Ruta del CSV de salida")
    p_pred.set_defaults(func=cmd_predict)

    return p


def main(argv=None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
