# Reliance Digital Retail Sales Analytics (MySQL)

End-to-end SQL project: cleaning, validating and analysing a messy laptop-sales dataset from a Reliance Digital-style retail business.

**Dataset:** synthetic retail dataset provided by the Learner Infinity Community. 203,200 raw rows and 57 columns, cleaned down to 200,000 orders.
**Tools:** MySQL 8, MySQL Workbench
**Status:** cleaning, data model, validation and analysis queries done. Power BI dashboard in progress.

---

## Business problem

Management wants reliable numbers on sales, stores, products, payments and delivery. The raw export cannot be trusted: dates come in many formats, prices and discounts are impossible, the same store or product appears with conflicting details, and orders are duplicated. This project turns that raw table into clean, validated tables that can be reported on.

## What I did

1. Loaded all columns as text into a raw table and kept it untouched. All work was done on copies.
2. Removed personal fields (phone, email, address) before analysis.
3. Cleaned text, numbers, dates and labels.
4. Fixed impossible values and conflicting records.
5. Removed duplicates.
6. Split the data into **Customer, Product, Store and Order** tables with primary keys.
7. Built reporting views that join the four tables.
8. Validated the result and wrote analysis queries.

## Data problems found and how I handled them

| Problem | Example | Handling |
|---|---|---|
| Dates in 8 different text formats | `26.02.2026`, `26-02-2026`, `26 February 2026`, `23-Aug-25`, dates with times | Parsed every format into one `DATE` column |
| Impossible values | Discounts of 150% and 999%, 450-day deliveries, unit price above MRP, 999 and 500 placeholders, 55-inch laptop screens | Replaced or nulled using documented rules (see below) |
| Conflicting details for the same ID | One store with several states, one product with several processors, one customer with several ages | Majority-vote logic using `ROW_NUMBER()` window functions |
| Duplicate records | Exact duplicate rows, repeated customers, products, stores and orders | Kept one record per key, lowest source ID first |
| Amounts that did not add up | Invoice not equal to taxable amount plus GST, EMI total far from invoice value | Recalculated derived amounts and repaired EMI tenure and monthly amount |
| Inconsistent labels | `M`/`F`, `MP`/`Madhya Pradesh`, misspelt customer segments, many payment-method spellings | Standardised to one value each |
| Symbols and spacing in numeric fields | Currency symbols, stray leading dots, extra spaces | Stripped and converted to proper data types |

## Cleaning rules and assumptions

These are judgement calls, listed so they can be reviewed.

- IDs are upper-cased and trimmed. Empty strings become `NULL`.
- Unit price above MRP is set to MRP. A unit price of 999 (placeholder) is set to MRP.
- A quantity of 500 (placeholder) is replaced with the lowest other quantity in the same order. A quantity of 0 is set to 1.
- Discount percentages above 100 are recalculated from the discount amount, or set to 50 where that is not possible.
- GST is standardised to 18%.
- Derived amounts are rebuilt from the base fields:
  - Discount amount = quantity × unit price × discount %
  - Taxable amount = quantity × unit price − discount amount
  - GST amount = taxable amount × GST %
  - Invoice amount = taxable amount + GST amount
- Delivery days of 450 are set to `NULL`. Delivery date is rebuilt as order date + delivery days. For delivered in-store orders, delivery date equals order date.
- Orders that were cancelled and returned but never delivered are labelled `PREDELIVERY CANCELLATION`.
- Customer ages of 15 or below, or above 70, are treated as invalid and filled from the customer's other records or the average age.
- Duplicate orders keep one row per `OrderID`, with status priority RETURNED, CANCELLED, DELIVERED, then PREDELIVERED.

## Validation

- **Column profiling:** NULLs, blanks, untrimmed text, invalid numbers, distinct counts, minimum and maximum for every column.
- **Cross-column rules:** unit price not above MRP, taxable, GST and invoice amounts consistent, delivery date not before order date, EMI tenure and amount consistent with the invoice.
- **ID mapping checks:** each store, product and customer ID maps to exactly one name.
- **Join reconciliation:** row counts and total revenue compared before and after joining the dimension tables.

## Analysis queries

Revenue and order KPIs, trends by financial year, quarter and month, brand, series and model performance, geography (region, state, city, store), channel, payment method and EMI, discount bands, customer segment and age group, order status, and delivery performance.

## Key findings

<!-- Replace this section with 3 findings from your analysis queries, or delete it before publishing. -->
- TODO: finding 1
- TODO: finding 2
- TODO: finding 3

## Repository structure

```
Reliance-Digital-Retail-Sales-Analytics/
├── README.md
├── sql/
│   ├── 01_base_cleaning.sql
│   ├── 02_customer_cleaning.sql
│   ├── 03_product_cleaning.sql
│   ├── 04_store_cleaning.sql
│   ├── 05_order_cleaning.sql
│   ├── 06_data_types_and_keys.sql
│   └── 07_quality_checks_and_analysis.sql
└── screenshots/
```

The scripts are listed in the order I ran them. The raw dataset is not included.

## Data and confidentiality

The dataset is synthetic and comes from the Learner Infinity Community. No real customer data is used. The raw file is not published here.

## Contact

Anubhuti Jain · [LinkedIn](https://www.linkedin.com/in/anubhuti-j-3238a1220/)
