import pandas as pd
import os
import re

# text cleaning function
def clean_text(text):
    text = str(text).lower()
    text = re.sub(r'\d+', '', text)
    text = re.sub(r'[^\w\s]', '', text)
    return text


# function to clean a csv
def clean_csv(file_path):

    df = pd.read_csv(file_path)

    for column in df.columns:
        if df[column].dtype == "object":   # clean text columns only
            df[column] = df[column].apply(clean_text)

    new_name = "cleaned_" + os.path.basename(file_path)

    df.to_csv(new_name, index=False)

    print(file_path, "cleaned")


# clean individual csv files
clean_csv("fir_dataset.csv")
clean_csv("ipc_sections.csv")


# clean csv files inside folder
folder = "crime"

for file in os.listdir(folder):

    if file.endswith(".csv"):

        path = os.path.join(folder, file)

        clean_csv(path)

print("All datasets cleaned successfully")