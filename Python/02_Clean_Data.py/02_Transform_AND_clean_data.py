import numpy as np
import pandas as pd

def clean_data(df):
    df.columns = df.columns.str.strip()

    df.rename(columns={
        "Postal Code": "Postal_Code",
        "Product_ ID": "Product_ID",
        "Sub-Category": "Sub_Category",
        "Product_ Name": "Product_Name",
        "Shipping Cost": "Shipping_Cost"
    }, inplace=True)

    df["Order_Date"] = pd.to_datetime(df["Order_Date"], errors="coerce")
    df["Ship_Date"] = pd.to_datetime(df["Ship_Date"], errors="coerce")

    df = df.replace({np.nan: None})

    return df