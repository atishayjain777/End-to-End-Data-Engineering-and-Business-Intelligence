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
