-- QUERY 1 --------------------------------------------------------------------------------------------------------------

USE gdb023;
-- CREATE VIEW AtliqExclusive_with_RegionAPAC AS
SELECT customer, market, region 
FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC'

-- QUERY 2 ---------------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW unique_product_percentage_chg AS
WITH unique_product AS
(
SELECT
	(SELECT count(DISTINCT(dp.product)) FROM dim_product dp JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code WHERE fgp.fiscal_year = 2020) AS unique_product_2020,
    (SELECT count(DISTINCT(dp.product)) FROM dim_product dp JOIN fact_gross_price fgp ON dp.product_code = fgp.product_code WHERE fgp.fiscal_year = 2021) AS unique_product_2021
FROM dim_product dp
JOIN fact_gross_price fgp
	ON dp.product_code = fgp.product_code
WHERE fgp.fiscal_year = 2020
GROUP BY fgp.fiscal_year
)
SELECT *, ((unique_product_2021 - unique_product_2020)/unique_product_2020) * 100 AS Percentage_chg
FROM unique_product

-- QUERY 3 ----------------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW unique_product_count AS unique_product_count
SELECT segment, count(DISTINCT(product)) AS product_count
FROM dim_product
GROUP BY 1
ORDER BY product_count DESC

-- QUERY 5 ---------------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW Max_Min_ManufacturingCost AS
SELECT dp.product_code, dp.product, fmc.manufacturing_cost
FROM dim_product dp
JOIN fact_manufacturing_cost fmc
	ON dp.product_code = fmc.product_code
WHERE fmc.manufacturing_cost IN ((select MAX(manufacturing_cost) from fact_manufacturing_cost) , (select MIN(manufacturing_cost) from fact_manufacturing_cost))

-- QUERY 6 ------------------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW TOP5_Average_Discount AS
SELECT dc.customer_code, dc.customer ,avg(pre_invoice_discount_pct) AS average_discount_percentage
FROM dim_customer dc
JOIN fact_pre_invoice_deductions fpid
	ON dc.customer_code = fpid.customer_code
WHERE fpid.fiscal_year = 2021 AND dc.market = 'INDIA'
GROUP BY dc.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5

-- QUERY 7 -------------------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW Gross_Sales_Amount_PerMonth AS
SELECT month(date) AS Month, YEAR(date) AS Year, (fsm.sold_quantity*fgp.gross_price) AS gross_sales_amount
FROM fact_sales_monthly fsm
 JOIN dim_customer dc ON fsm.customer_code =dc.customer_code
 JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY Month
ORDER BY Year

-- QUERY 8 ----------------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW Total_Sold_QuantityPer_Quater AS
SELECT quarter(date) AS Quarter, SUM(sold_quantity) AS Total_Sold_Quantity
FROM fact_sales_monthly
WHERE YEAR(date) = 2020
GROUP BY Quarter
ORDER BY Total_Sold_Quantity DESC

-- QUERY 9 ----------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW channel_gross_sales AS
WITH gross
AS
(
SELECT channel, (fsm.sold_quantity * fgp.gross_price)/1000000 AS gross_sales
FROM fact_sales_monthly fsm
JOIN dim_customer dc 
	ON  fsm.customer_code = dc.customer_code 
JOIN fact_gross_price fgp
	ON fsm.product_code = fgp.product_code
    
WHERE fsm.fiscal_year = 2021
),
gross2
AS
(
SELECT channel, ROUND(SUM(gross_sales),2) AS gross_sales_mn
FROM gross
GROUP BY channel
ORDER BY gross_sales_mn DESC
)
SELECT channel, gross_sales_mn, ROUND((gross_sales_mn)*100 / (SELECT SUM(gross_sales_mn) FROM gross2),2) AS percentage
FROM gross2

-- QUERY 10 -----------------------------------------------------------------------------------------------------------------

-- USE gdb023;
-- CREATE VIEW Top3_ProductBY_Division AS
SELECT * FROM
(
SELECT dp.division, dp.product_code, dp.product, SUM(fsm.sold_quantity) AS total_sold_quantity, row_number() OVER (partition BY dp.division) AS rank_order
FROM dim_product dp
JOIN fact_sales_monthly fsm ON dp.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY dp.product_code
ORDER BY dp.division, total_sold_quantity DESC
)RNK
WHERE rank_order <=3 


