# Bank Loan Data Analysis
Documentation of a comprehensive portfolio project that uses Python, SQL, and Tableau to interpret and visualize financial data.

---
## Table of Contents
1. [Project Overview](#project-overview)
2. [Dataset Summary](#dataset-summary)
3. [Data Cleaning in **Python**](#data-cleaning-in-python)
4. [Exploratory Data Analysis in **MySQL Workbench**](#exploratory-data-analysis-in-mysql-workbench)
5. [Visualizations in **Tableau Public**](#visualizations-in-tableau-public)
6. [Project Insight and Recommendations](#project-insight-and-recommendations)
7. [Conclusion](#conclusion)

---
## Project Overview


---
## Dataset Summary
The Kaggle dataset can be found [**here**](https://www.kaggle.com/datasets/zaurbegiev/my-dataset/data).

---
## Data Cleaning in Python
This dataset had some numerical errors and inconsistent strings, which were corrected during the cleaning process. In addition, two new columns were feature engineered to show the impact of a customer's credit score range and debt-to-income ratio on their bank loan status.

### 1. Some values in the **`credit_score`** column have an extra "0" at the end of the number (ex: **`credit_score`** of **`729`** is mistakenly recorded as **`7290`**). Remove this extra "0" to ensure accurate data.
```python
# Fix values in credit_score column with an extra "0"
df["credit_score"] = df["credit_score"].apply(
    lambda x: x / 10 if pd.notnull(x) and x > 850 else x
)

# Make sure all credit_score values are between 300 and 850
print(df["credit_score"].describe())
```

### 2. Maintain consistency within **`purpose`** categories, to simplify querying and visualizations:
* **`moving`**, **`other`**, **`vacation`**, **`wedding`** → Title case
* **`major_purchase`**, **`small_business`**, **`renewable_energy`** → Title case, replace underscore with space
* **`Buy a Car`**, **`Buy House`**, **`Take a Trip`** → Simplify into one-word labels
```python
# Standardize categories
df["purpose"] = (
    df["purpose"]
    .str.strip()
    .str.replace("_", " ", regex=False)
    .str.title()
)

# Simplify categories
purpose_simplify = {
    "Buy A Car": "Car",
    "Buy House": "House",
    "Take A Trip": "Trip"
}

df["purpose"] = df["purpose"].replace(purpose_simplify)

# Inspect categories
print(df["purpose"].value_counts(dropna=False))
```

### 3. Feature engineer a new column that reads each value in the **`credit_score`** column and labels its FICO score category in a **`credit_score_range`** column, to enhance querying and visualizations:
* **Excellent:** 800 - 850
* **Very Good:** 740 - 799
* **Good:** 670 - 739
* **Fair:** 580 - 669
* **Poor:** 300 - 579
```python
# Define the FICO score ranges and its associated label
conditions = [
    df["credit_score"].between(800, 850),
    df["credit_score"].between(740, 799),
    df["credit_score"].between(670, 739),
    df["credit_score"].between(580, 669),
    df["credit_score"].between(300, 579)
]

labels = [
    "Excellent",
    "Very Good",
    "Good",
    "Fair",
    "Poor"
]

# Create the new credit_score_range column
credit_score_range = np.select(conditions, labels, default="")

# Insert credit_score_range column directly after credit_score column
credit_score_index = df.columns.get_loc("credit_score") + 1
df.insert(credit_score_index, "credit_score_range", credit_score_range)

# Inspect credit_score_range column
print(df["credit_score_range"].value_counts(dropna=False))
```

### 4. Feature engineer a new column that uses each value in the **`annual_income`** and **`monthly_debt`** columns to calculate the debt-to-income ratio, and store it in a **`dti`** column, to enhance querying and visualizations:
* **FORMULA:** Monthly Income = Annual Income / 12
* **FORMULA:** Debt-To-Income Ratio (DTI) = Monthly Debt / Monthly Income
```python
# Handle null values in annual_income and monthly_debt columns
df["annual_income"] = pd.to_numeric(df["annual_income"], errors="coerce")
df["monthly_debt"] = pd.to_numeric(df["monthly_debt"], errors="coerce")

# Calculate monthly_income
monthly_income = df["annual_income"] / 12

# Calculate debt-to-income ratio
dti = df["monthly_debt"] / monthly_income

# Handle infinite values (ex: annual_income = 0)
dti = dti.replace([np.inf, -np.inf], np.nan)

# Round the dti to the nearest hundredth
dti = dti.round(2)

# Insert dti column directly after monthly_debt column
monthly_debt_index = df.columns.get_loc("monthly_debt") + 1
df.insert(monthly_debt_index, "dti", dti)

# Inspect dti column
print(df["dti"].describe())
```

An in-depth [**Jupyter Notebook**](https://github.com/SunehraFarhana/Bank-Loan-Data-Analysis/blob/e31313e64fd8a140f01fbd20aa87f4103442902c/bank_loan_dataset_cleaning.ipynb) detailing every step of the data cleaning process is available in this repository.

---
## Exploratory Data Analysis in MySQL Workbench
These SQL queries revealed data trends and gave guidance for assembling visualizations.

### 1. What is the percentage of loans by loan status?
```sql
SELECT 
    loan_status,
    COUNT(*) AS total_loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_loans
FROM bank_loan_schema.bank_loan_dataset_cleaned
GROUP BY loan_status
ORDER BY percentage_of_loans DESC;
```
<img width="259" height="77" alt="bank_loan_sql_1" src="https://github.com/user-attachments/assets/58421cb4-4b66-4e09-9770-36616a5ef9a1" />

### 2. What is the average current loan amount, annual income, and monthly debt by loan status?
```sql
SELECT
    loan_status,
    ROUND(AVG(current_loan_amount), 2) AS avg_current_loan_amount,
	ROUND(AVG(annual_income), 2) AS avg_annual_income,
    ROUND(AVG(monthly_debt), 2) AS avg_monthly_debt
FROM bank_loan_schema.bank_loan_dataset_cleaned
GROUP BY loan_status
ORDER BY avg_current_loan_amount DESC;
```
<img width="440" height="76" alt="bank_loan_sql_2" src="https://github.com/user-attachments/assets/7ce5e0b5-4598-4569-8c47-25196aa438f8" />

### 3. What is the loan default rate by customer debt-to-income ratio? Which debt-to-income ratio has the highest default rate?
```sql
SELECT
    CASE
        WHEN dti < 0.2 THEN 'Low DTI'
        WHEN dti BETWEEN 0.2 AND 0.3 THEN 'Medium DTI'
        ELSE 'High DTI'
    END AS dti_bucket,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(CASE 
            WHEN loan_status IN ('Charged Off') THEN 1 
            ELSE 0 
        END) / COUNT(*), 2
    ) AS default_rate_percent
FROM bank_loan_schema.bank_loan_dataset_cleaned
WHERE annual_income IS NOT NULL
GROUP BY dti_bucket
ORDER BY default_rate_percent DESC;
```
<img width="259" height="90" alt="bank_loan_sql_3" src="https://github.com/user-attachments/assets/c5d8f0b8-9044-4934-8e65-abae02bf5e4b" />

### 4. What is the loan default rate by loan purpose? Which purpose has the highest default rate?
```sql
SELECT
    purpose,
    COUNT(*) AS total_loans,
    SUM(CASE 
        WHEN loan_status IN ('Charged Off') THEN 1 
        ELSE 0 
    END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE 
            WHEN loan_status IN ('Charged Off') THEN 1 
            ELSE 0 
        END) / COUNT(*), 2
    ) AS default_rate_percent
FROM bank_loan_schema.bank_loan_dataset_cleaned
GROUP BY purpose
ORDER BY default_rate_percent DESC;
```
<img width="384" height="271" alt="bank_loan_sql_4" src="https://github.com/user-attachments/assets/4fc54c64-0be7-444b-be8f-b82ef96f6e40" />

### 5. What is the impact of number of bankruptcies and tax_liens on loan default rate?
```sql
SELECT
    CASE
        WHEN bankruptcies = 0 THEN 'No Bankruptcies'
        WHEN bankruptcies BETWEEN 1 AND 3 THEN '1-3 Bankruptcies'
        WHEN bankruptcies >= 4 THEN '4+ Bankruptcies'
    END AS bankruptcy_range,
    CASE
        WHEN tax_liens = 0 THEN 'No Tax Liens'
        WHEN tax_liens BETWEEN 1 AND 3 THEN '1-3 Tax Liens'
        WHEN tax_liens >= 4 THEN '4+ Tax Liens'
    END AS tax_liens_range,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(CASE 
            WHEN loan_status IN ('Charged Off') THEN 1 
            ELSE 0 
        END) / COUNT(*), 2
    ) AS default_rate_percent
FROM bank_loan_schema.bank_loan_dataset_cleaned
GROUP BY bankruptcy_range, tax_liens_range;
```
<img width="386" height="180" alt="bank_loan_sql_5" src="https://github.com/user-attachments/assets/4a188c9a-0c63-442d-bd75-11da924df2f1" />

An in-depth [**SQL file**](https://github.com/SunehraFarhana/Bank-Loan-Data-Analysis/blob/e31313e64fd8a140f01fbd20aa87f4103442902c/bank_loan_queries.sql) detailing every step of the querying process is available in this repository.

---
## Visualizations in Tableau Public
The Tableau Public visualizations can be found [**here**](https://public.tableau.com/views/bank_loan_visualizations/Overview?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link).

<img width="1349" height="649" alt="bank_loan_visualizations_dashboard_overview" src="https://github.com/user-attachments/assets/7b141e75-c7e8-400f-ba57-f0d46da28ba5" />
<img width="1349" height="649" alt="bank_loan_visualizations_dashboard_risk_analysis" src="https://github.com/user-attachments/assets/1461b2a0-4e1c-43e9-bc62-f932a583b8ed" />

---
## Project Insight and Recommendations


---
## Conclusion

