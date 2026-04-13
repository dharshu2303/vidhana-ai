from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd

data = pd.read_csv("final_merged_dataset.csv")

# FIX
data["text"] = data["text"].fillna("")
data["text"] = data["text"].astype(str)

X = data["text"]

vectorizer = TfidfVectorizer()
X_vector = vectorizer.fit_transform(X)

print("TF-IDF Done successfully")