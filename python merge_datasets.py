import pandas as pd
import os

dataframes = []

# load cleaned fir dataset
fir = pd.read_csv("cleaned_fir_dataset.csv")
dataframes.append(fir)

# load cleaned ipc dataset
ipc = pd.read_csv("cleaned_ipc_sections.csv")
dataframes.append(ipc)

# load cleaned case csv files
folder = "crime"

for file in os.listdir(folder):

    if file.startswith("cleaned_") and file.endswith(".csv"):

        path = os.path.join(folder, file)

        df = pd.read_csv(path)

        dataframes.append(df)

        print(file, "loaded")

# merge all datasets
merged_data = pd.concat(dataframes, ignore_index=True)

# save merged dataset
merged_data.to_csv("final_merged_dataset.csv", index=False)

print("All datasets merged successfully!")