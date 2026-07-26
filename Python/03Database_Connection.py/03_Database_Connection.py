import pandas as pd
import mysql.connector
import numpy as np

# ---------------- CONFIG ----------------
csv_path = r"C:/data/Global_Superstore.csv"

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password=" password",      # ✔ 
    database="global_estore_raw",
    autocommit=True
)

cursor = conn.cursor()

# ---------------- LOAD CSV ----------------
print("📥 Reading CSV...")
df = pd.read_csv(csv_path)
print("Rows in CSV:", len(df))
