-- 1. What is the percentage of loans by loan status?
SELECT 
    loan_status,
    COUNT(*) AS total_loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_loans
FROM bank_loan_schema.bank_loan_dataset_cleaned
GROUP BY loan_status
ORDER BY percentage_of_loans DESC;


-- 2. What is the percentage of loans by loan term?
SELECT 
    term,
    COUNT(*) AS total_loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_loans
FROM bank_loan_schema.bank_loan_dataset_cleaned
GROUP BY term
ORDER BY percentage_of_loans DESC;


-- 3. What is the average current loan amount, annual income, and monthly debt by loan status?
SELECT
    loan_status,
    ROUND(AVG(current_loan_amount), 2) AS avg_current_loan_amount,
	ROUND(AVG(annual_income), 2) AS avg_annual_income,
    ROUND(AVG(monthly_debt), 2) AS avg_monthly_debt
FROM bank_loan_schema.bank_loan_dataset_cleaned
GROUP BY loan_status
ORDER BY avg_current_loan_amount DESC;


-- 4. What is the loan default rate by customer debt-to-income ratio?
-- Which debt-to-income ratio has the highest default rate?
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


-- 5. What is the loan default rate by customer credit score range?
-- Which credit score range has the highest default rate?
SELECT
    credit_score_range,
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
GROUP BY credit_score_range
ORDER BY default_rate_percent DESC;


-- 6. What is the loan default rate by customer home ownership?
-- Which home ownership has the highest default rate?
SELECT
    home_ownership,
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
GROUP BY home_ownership
ORDER BY default_rate_percent DESC;


-- 7. What is the loan default rate by loan purpose?
-- Which purpose has the highest default rate?
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


-- 8. What is the loan default rate by customer years in current job?
-- Which years in current job has the highest default rate?
SELECT
    years_in_current_job,
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
GROUP BY years_in_current_job
ORDER BY default_rate_percent DESC;


-- 9. What is the impact of number of bankruptcies and tax_liens on loan default rate?
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