import pandas as pd
import pickle
from sklearn.linear_model import LogisticRegression
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import LabelEncoder

CSV_PATH = "ipc_sections.csv"
MODEL_PATH = "fir_model.pkl"


def train():
    df = pd.read_csv(CSV_PATH)
    df = df[["Description", "Offense", "Section"]].dropna()
    df.columns = ["text", "offense", "section"]

    # Normalize section labels
    df["section"] = df["section"].str.strip().str.lower().str.replace(" ", "_")

    print(f"[INFO] Loaded {len(df)} IPC sections")

    # Combined text: offense (short) + description (detailed)
    df["combined"] = df["offense"].fillna("") + " " + df["text"].fillna("")

    X = df["combined"].tolist()
    y = df["section"].tolist()

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        max_features=15000,
        sublinear_tf=True,
        min_df=1,
    )
    X_vec = vectorizer.fit_transform(X)

    # Since each section has 1-2 samples, train on full data (retrieval mode)
    model = LogisticRegression(
        max_iter=2000,
        C=1.0,
        solver="lbfgs",
    )
    model.fit(X_vec, y_enc)

    print(f"[INFO] Model trained on {len(X)} samples covering {len(le.classes_)} IPC sections")

    with open(MODEL_PATH, "wb") as f:
        pickle.dump({"model": model, "vectorizer": vectorizer, "label_encoder": le}, f)

    print(f"[INFO] Model saved to '{MODEL_PATH}'")

    # Quick sanity check
    test_cases = [
        ("murder killed stabbed", "ipc_302"),
        ("theft stolen pickpocket", "ipc_379"),
        ("rape sexual assault", "ipc_376"),
        ("cheating fraud deceived", "ipc_420"),
        ("dowry harassment cruelty husband", "ipc_498a"),
    ]
    print("\n[SANITY CHECK]")
    for text, expected in test_cases:
        vec = vectorizer.transform([text])
        proba = model.predict_proba(vec)[0]
        top3_idx = proba.argsort()[::-1][:3]
        top3 = [(le.inverse_transform([i])[0], round(proba[i]*100, 1)) for i in top3_idx]
        hit = any(expected in s for s, _ in top3)
        status = "OK" if hit else "MISS"
        print(f"  [{status}] '{text}' -> top3: {top3}")


if __name__ == "__main__":
    train()
