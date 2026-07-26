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

# ---------------- CLEAN COLUMNS ----------------
df.columns = df.columns.str.strip()

df.rename(columns={
    "Postal Code": "Postal_Code",
    "Product_ ID": "Product_ID",
    "Sub-Category": "Sub_Category",
    "Product_ Name": "Product_Name",
    "Shipping Cost": "Shipping_Cost"
}, inplace=True)

# ---------------- DATE FIX ----------------
df["Order_Date"] = pd.to_datetime(df["Order_Date"], errors="coerce")
df["Ship_Date"] = pd.to_datetime(df["Ship_Date"], errors="coerce")

# ---------------- NaN → NULL ----------------
df = df.replace({np.nan: None})

# ---------------- INSERT QUERY ----------------
insert_query = """
INSERT INTO raw_orders (
Row_ID, Order_ID, Order_Date, Ship_Date, Ship_Mode,
Customer_ID, Customer_Name, Segment,
City, State, Country, Postal_Code,
Market, Region, Product_ID, Category,
Sub_Category, Product_Name, Sales,
Quantity, Discount, Profit, Shipping_Cost
)
VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
"""

# ---------------- CHUNK INSERT ----------------
BATCH_SIZE = 1000
total = 0

print("🚀 Inserting data in batches...")

for i in range(0, len(df), BATCH_SIZE):
    batch = df.iloc[i:i+BATCH_SIZE].values.tolist()
    cursor.executemany(insert_query, batch)
    total += len(batch)
    print(f"Inserted {total} rows")

cursor.close()
conn.close()

print("✅ DONE! TOTAL ROWS INSERTED:", total)
