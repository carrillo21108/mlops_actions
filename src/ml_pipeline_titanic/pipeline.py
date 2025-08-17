import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.ensemble import RandomForestClassifier

def build_pipeline():
    """Crea y devuelve la pipeline sin entrenar."""
    variables_numericas = ['Age', 'Fare', 'SibSp', 'Parch', 'Pclass']
    variables_categoricas = ['Sex', 'Embarked']

    numerical_transformer = Pipeline(steps=[
        ('scaler', StandardScaler())
    ])

    categorical_transformer = Pipeline(steps=[
        ('onehot', OneHotEncoder(handle_unknown='ignore'))
    ])

    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numerical_transformer, variables_numericas),
            ('cat', categorical_transformer, variables_categoricas)
        ]
    )

    pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('classifier', RandomForestClassifier(n_estimators=100, random_state=42))
    ])
    return pipeline

def train_pipeline(csv_url):
    """Extrae datos, entrena la pipeline y devuelve el modelo entrenado."""
    df = pd.read_csv(csv_url)
    df = df.dropna(thresh=len(df.columns) - 2)

    X = df[['Age', 'Fare', 'Sex', 'Embarked']]
    y = df['Survived']

    X_train, _, y_train, _ = train_test_split(X, y, test_size=0.2, random_state=42)

    pipeline = build_pipeline()
    pipeline.fit(X_train, y_train)
    return pipeline

def predict_pipeline(pipeline, X_new):
    """Realiza predicciones con la pipeline ya entrenada."""
    return pipeline.predict(X_new)

__all__ = ["build_pipeline", "train_pipeline", "predict_pipeline"]
