import os
import pandas as pd

folder = "output_text"

data = []

for filename in os.listdir(folder):
    if filename.endswith(".txt"):

        filepath = os.path.join(folder, filename)

        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()

        data.append({
            "file_name": filename,
            "fir_text": text
        })

df = pd.DataFrame(data)

df.to_csv("fir_dataset.csv", index=False)

print("CSV dataset created!")