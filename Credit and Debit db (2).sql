-- Create schema (database)
CREATE SCHEMA IF NOT EXISTS banking_dw;
USE banking_dw;

-- Drop if exists and recreate
DROP TABLE IF EXISTS bank_transactions;
CREATE TABLE bank_transactions (
    customer_id         CHAR(36)        NOT NULL,
    customer_name       VARCHAR(100)    NOT NULL,
    account_number      BIGINT          NOT NULL,
    transaction_date    DATE            NOT NULL,
    transaction_type    ENUM('Credit','Debit') NOT NULL,
    amount              DECIMAL(12,2)   NOT NULL,
    balance             DECIMAL(14,2),
    description         VARCHAR(150),
    branch              VARCHAR(80),
    transaction_method  VARCHAR(50),
    currency            VARCHAR(10),
    bank_name           VARCHAR(80),
    id                  BIGINT AUTO_INCREMENT,
    PRIMARY KEY (id)
);
DESCRIBE bank_transactions;
SELECT COUNT(*) FROM bank_transactions;
SELECT * FROM bank_transactions LIMIT 10;
SELECT COUNT(*) FROM bank_transactions;
SHOW VARIABLES LIKE 'secure_file_priv';
LOAD DATA INFILE 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads'
INTO TABLE bank_transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE '"Z:\Data Analyst\Project - Internship\credit_debit_db.csv"'
INTO TABLE bank_transactions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
USE banking_dw;
SELECT COUNT(*) FROM bank_transactions;
SELECT * FROM bank_transactions LIMIT 20;
-- Q1- Top 10 customers by TOTAL DEBIT in a year
SELECT
customer_id, customer_name, account_number,
SUM(CASE WHEN transaction_type='Debit' THEN amount ELSE 0 END) AS total_debit
FROM bank_transactions
WHERE YEAR(transaction_date)=2024
GROUP BY customer_id, customer_name, account_number
ORDER BY total_debit DESC
LIMIT 10;

-- Q2- Average transaction amount by Bank and Type
SELECT bank_name,transaction_type,
COUNT(*) AS txn_count,
AVG(amount) AS avg_amount,
SUM(amount) AS total_amount
FROM bank_transactions
GROUP BY bank_name, transaction_type
ORDER BY bank_name, transaction_type;

-- Q-3 Monthly transaction Trend by Branch for a given year
SELECT branch,
DATE_FORMAT(transaction_date, '%Y-%m') AS yyyymm,
COUNT(*) AS txn_count,
SUM(amount) AS total_amount
FROM bank_transactions
WHERE YEAR(transaction_date)=2024
GROUP BY branch, DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY branch, yyyymm;

-- Q-4 Most used Transaction Method overall and per bank
-- Overall
SELECT transaction_method, COUNT(*) AS usage_count
FROM bank_transactions
GROUP BY transaction_method
ORDER BY usage_count DESC;
-- By Bank
SELECT bank_name, transaction_method, COUNT(*) AS usage_count
FROM bank_transactions
GROUP BY bank_name, transaction_method
ORDER BY bank_name, usage_count DESC;


-- Q5. Highest Single Credit per customer in a date range
SELECT t.customer_id, t.customer_name, t.account_number,
MAX(CASE WHEN t.transaction_type='Credit' THEN t.amount ELSE NULL END) AS max_credit
FROM bank_transactions t
WHERE t.transaction_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY t.customer_id, t.customer_name, t.account_number
ORDER BY max_credit DESC;

-- Q6. Customers with Highest Ending Balance (latest balance by account)
WITH latest_row AS (
SELECT
id, account_number,
ROW_NUMBER() OVER (PARTITION BY account_number ORDER BY transaction_date DESC, id DESC) AS rn
FROM bank_transactions
)
SELECT b.customer_id, b.customer_name, b.account_number, b.balance AS latest_balance,
b.transaction_date AS as_of_date
FROM bank_transactions b
JOIN latest_row lr ON lr.id=b.id AND lr.rn=1
ORDER BY latest_balance DESC
LIMIT 20;

-- Q7. TOP SPENDING CATEGORIES (Descriptions) for DEBIT
SELECT description,
COUNT(*) AS txn_count,
SUM(amount) AS total_debit
FROM bank_transactions
WHERE transaction_type='Debit'
GROUP BY description
ORDER BY total_debit DESC
LIMIT 15;

-- Q8. Distribution: Transactions and Unique Customers per BANK
SELECT bank_name,
COUNT(*) AS txn_count,
COUNT(DISTINCT customer_id) AS unique_customers
FROM bank_transactions
GROUP BY bank_name
ORDER BY txn_count DESC;

-- Q9. Peak Transaction Day (max count and value
SELECT transaction_date,
COUNT(*) AS txn_count,
SUM(amount) AS total_amount
FROM bank_transactions
GROUP BY transaction_date
ORDER BY txn_count DESC, total_amount DESC
LIMIT 1;

-- Transaction Audit trigger
DROP TABLE IF EXISTS audit_log;
SHOW GRANTS FOR CURRENT_USER();
USE banking_dw;

CREATE TABLE audit_log (
  audit_id        BIGINT AUTO_INCREMENT PRIMARY KEY,
  inserted_id     BIGINT NOT NULL,
  account_number  VARCHAR(50),
  transaction_type VARCHAR(50),
  amount          DECIMAL(18,2),
  inserted_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  inserted_by     VARCHAR(100)
) ENGINE=InnoDB;

SELECT * FROM audit_log ORDER BY audit_id DESC LIMIT 5;


