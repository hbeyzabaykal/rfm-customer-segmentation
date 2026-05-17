-- Step 1: Append all the monthly sales tables together.

-- ** sales202512 isimli tabloda upload aşamasından sonra olması gereken 5 kolon yerine ekstra 3 kolon daha oluşuyor. Bunun için 
-- SELECT *.... şeklinde yazmak yerine spesifik olarak kolon isimleri belirtilmiştir.


CREATE OR REPLACE TABLE `rfm-223.sales.sales_2025` AS
SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202501`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202502`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202503`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202504`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202505`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202506`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202507`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202508`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202509`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202510`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202511`
UNION ALL SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue FROM `rfm-223.sales.sales202512`;


-- Step 2: calculate recency, frequency, monetary, r, f, m ranks
-- Combine view and CTE


CREATE OR REPLACE VIEW `rfm-223.sales.rfm_metrics`
AS 
WITH current_date AS (
  SELECT DATE('2026-04-29') AS analysis_date  -- today's date
),
rfm AS (
  SELECT 
  CustomerID,
  MAX(OrderDate) AS latest_order_date,
  date_diff((SELECT analysis_date FROM current_date), MAX(OrderDate), DAY) AS recency,
  COUNT(*) AS frequency,
  SUM(OrderValue) AS monetary
  FROM `rfm-223.sales.sales_2025` 
  GROUP BY CustomerID
  )
SELECT
 rfm.*,
 ROW_NUMBER() OVER(ORDER BY recency ASC) AS r_rank,
 ROW_NUMBER() OVER(ORDER BY rfm.frequency DESC) AS f_rank,
 ROW_NUMBER() OVER(ORDER BY rfm.monetary DESC) AS m_rank
FROM rfm; 


-- Step 3: Assigning Deciles (10:Best, 1:Worst)

CREATE OR REPLACE VIEW `rfm-223.sales.rfm_scores`
AS 
  SELECT 
  *,
  NTILE(10) OVER(ORDER BY r_rank DESC) AS r_score,
  NTILE(10) OVER(ORDER BY f_rank DESC) AS f_score,
  NTILE(10) OVER(ORDER BY m_rank DESC) AS m_score
FROM `rfm-223.sales.rfm_metrics`;


-- Step 4: Total Score


CREATE OR REPLACE VIEW `rfm-223.sales.rfm_total_scores`
AS 
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  (r_score+f_score+m_score) AS rfm_total_score
FROM `rfm-223.sales.rfm_scores`
ORDER BY rfm_total_score DESC; 


-- Step 5:BI ready rfm segments table


CREATE OR REPLACE TABLE `rfm-223.sales.rfm_segments_final`
AS
SELECT
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  rfm_total_score,
  CASE
    WHEN rfm_total_score >= 28 THEN 'Champions' -- 28-30 inclusive
    WHEN rfm_total_score >= 24 THEN 'Loyal VIPs'
    WHEN rfm_total_score >= 20 THEN 'Potantial Loyalties'
    WHEN rfm_total_score >= 16 THEN 'Promising'
    WHEN rfm_total_score >= 12 THEN 'Engaged'
    WHEN rfm_total_score >= 8 THEN 'Requires Attention'
    WHEN rfm_total_score >= 4 THEN 'At Risk'
    ELSE 'Lost/Inactive '
    END AS rfm_segment
FROM `rfm-223.sales.rfm_total_scores`
ORDER BY rfm_total_score DESC;



















































