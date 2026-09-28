# E-Commerce Business Intelligence & Customer Analytics
# Python data loading and cleaning
# Dataset: Brazilian Olist E-Commerce

import pandas as pd
from pathlib import Path

# ---------------------------------------------------------
# 1. Project paths
# ---------------------------------------------------------

BASE_PATH = Path(r"C:\dell\Ecommerce Business Intelligence")
RAW_PATH = BASE_PATH / "data" / "raw"
PROCESSED_PATH = BASE_PATH / "data" / "processed"

PROCESSED_PATH.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------
# 2. Load all Olist datasets
# ---------------------------------------------------------

customers = pd.read_csv(RAW_PATH / "olist_customers_dataset.csv")
geolocation = pd.read_csv(RAW_PATH / "olist_geolocation_dataset.csv")
order_items = pd.read_csv(RAW_PATH / "olist_order_items_dataset.csv")
payments = pd.read_csv(RAW_PATH / "olist_order_payments_dataset.csv")
reviews = pd.read_csv(RAW_PATH / "olist_order_reviews_dataset.csv")
orders = pd.read_csv(RAW_PATH / "olist_orders_dataset.csv")
products = pd.read_csv(RAW_PATH / "olist_products_dataset.csv")
sellers = pd.read_csv(RAW_PATH / "olist_sellers_dataset.csv")
category_translation = pd.read_csv(
    RAW_PATH / "product_category_name_translation.csv"
)

# Check original row counts
datasets = {
    "customers": customers,
    "geolocation": geolocation,
    "order_items": order_items,
    "payments": payments,
    "reviews": reviews,
    "orders": orders,
    "products": products,
    "sellers": sellers,
    "category_translation": category_translation
}

for name, df in datasets.items():
    print(f"{name}: {df.shape}")

# ---------------------------------------------------------
# 3. Clean column names
# ---------------------------------------------------------

def clean_column_names(df):
    df = df.copy()
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
    )
    return df

customers = clean_column_names(customers)
geolocation = clean_column_names(geolocation)
order_items = clean_column_names(order_items)
payments = clean_column_names(payments)
reviews = clean_column_names(reviews)
orders = clean_column_names(orders)
products = clean_column_names(products)
sellers = clean_column_names(sellers)
category_translation = clean_column_names(category_translation)

# ---------------------------------------------------------
# 4. Convert order date columns to datetime
# ---------------------------------------------------------

date_columns = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

for col in date_columns:
    orders[col] = pd.to_datetime(orders[col], errors="coerce")

# ---------------------------------------------------------
# 5. Create delivery metrics
# ---------------------------------------------------------

orders["delivery_days"] = (
    orders["order_delivered_customer_date"]
    - orders["order_purchase_timestamp"]
).dt.total_seconds() / (24 * 60 * 60)

orders["delivery_delay_days"] = (
    orders["order_delivered_customer_date"]
    - orders["order_estimated_delivery_date"]
).dt.total_seconds() / (24 * 60 * 60)

def delivery_performance(days):
    if pd.isna(days):
        return "Not Delivered"
    elif days < 0:
        return "Early"
    elif days == 0:
        return "On Time"
    else:
        return "Late"

orders["delivery_performance"] = (
    orders["delivery_delay_days"].apply(delivery_performance)
)

# ---------------------------------------------------------
# 6. Create purchase-date features
# ---------------------------------------------------------

orders["purchase_year"] = orders["order_purchase_timestamp"].dt.year
orders["purchase_month"] = orders["order_purchase_timestamp"].dt.month
orders["purchase_month_name"] = (
    orders["order_purchase_timestamp"].dt.month_name()
)
orders["purchase_day"] = orders["order_purchase_timestamp"].dt.day
orders["purchase_weekday"] = (
    orders["order_purchase_timestamp"].dt.day_name()
)
orders["order_date"] = (
    orders["order_purchase_timestamp"].dt.date
)

# ---------------------------------------------------------
# 7. Create clean copies
# ---------------------------------------------------------

customers_clean = customers.copy()
geolocation_clean = geolocation.copy()
order_items_clean = order_items.copy()
payments_clean = payments.copy()
reviews_clean = reviews.copy()
orders_clean = orders.copy()
products_clean = products.copy()
sellers_clean = sellers.copy()
category_translation_clean = category_translation.copy()

# ---------------------------------------------------------
# 8. Basic missing-value checks
# ---------------------------------------------------------

print("\nMissing values:")
for name, df in {
    "customers": customers_clean,
    "geolocation": geolocation_clean,
    "order_items": order_items_clean,
    "payments": payments_clean,
    "reviews": reviews_clean,
    "orders": orders_clean,
    "products": products_clean,
    "sellers": sellers_clean,
    "category_translation": category_translation_clean
}.items():
    print(f"\n{name}")
    print(df.isna().sum())

# ---------------------------------------------------------
# 9. Basic duplicate checks
# ---------------------------------------------------------

print("\nDuplicate rows:")
for name, df in {
    "customers": customers_clean,
    "geolocation": geolocation_clean,
    "order_items": order_items_clean,
    "payments": payments_clean,
    "reviews": reviews_clean,
    "orders": orders_clean,
    "products": products_clean,
    "sellers": sellers_clean,
    "category_translation": category_translation_clean
}.items():
    print(f"{name}: {df.duplicated().sum()}")

# ---------------------------------------------------------
# 10. Basic data validation
# ---------------------------------------------------------

print("\nFinal dataset shapes:")

clean_datasets = {
    "customers": customers_clean,
    "geolocation": geolocation_clean,
    "order_items": order_items_clean,
    "payments": payments_clean,
    "reviews": reviews_clean,
    "orders": orders_clean,
    "products": products_clean,
    "sellers": sellers_clean,
    "category_translation": category_translation_clean
}

for name, df in clean_datasets.items():
    print(f"{name}: {df.shape}")

# ---------------------------------------------------------
# 11. Save processed datasets
# ---------------------------------------------------------
# These are optional outputs for your portfolio.
# The raw CSV files remain unchanged.

for name, df in clean_datasets.items():
    df.to_csv(PROCESSED_PATH / f"{name}_clean.csv", index=False)

print("\nCleaned datasets saved to:")
print(PROCESSED_PATH)

print("\nPython data-cleaning workflow completed successfully.")
