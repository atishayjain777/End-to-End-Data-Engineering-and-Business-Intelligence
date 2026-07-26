import pandas as pd

csv_path = r"C:/data/Global_Superstore.csv"

df = pd.read_csv(csv_path)
print("Rows:", len(df))