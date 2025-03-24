SELECT * FROM dim_customer;
SELECT * FROM dim_product;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;


-- 1. Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 

SELECT DISTINCT market 
FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020, unique_products_2021, percentage_chg 

WITH cte AS (
SELECT COUNT(DISTINCT CASE
		                  WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
	   COUNT(DISTINCT CASE
						  WHEN fiscal_year = 2021 THEN product_code END) AS unique_product_2021
FROM fact_sales_monthly)
SELECT *, ROUND((unique_product_2021-unique_products_2020)*100/unique_products_2020,1) AS percentage_chg
FROM cte;

/* 3.  Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts.
       The final output contains 2 fields, 
                                   segment 
								   product_count */
                                   
SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


/* 4.  Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, 
									segment 
									product_count_2020 
									product_count_2021 
									difference */
								
WITH cte AS (                                
SELECT p.segment, COUNT(DISTINCT CASE
		                           WHEN s.fiscal_year = 2020 THEN s.product_code END) AS products_count_2020,
				  COUNT(DISTINCT CASE
						           WHEN s.fiscal_year = 2021 THEN s.product_code END) AS product_count_2021
FROM fact_sales_monthly s 
JOIN dim_product p 
ON p.product_code = s.product_code
GROUP BY p.segment)

SELECT *, product_count_2021-products_count_2020 AS difference
FROM cte
ORDER BY difference DESC;

/* 5.   Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, 
										product_code 
										product 
										manufacturing_cost */
                                        
SELECT m.product_code, product, ROUND(manufacturing_cost,2) AS manufacturing_cost
FROM dim_product p 
JOIN fact_manufacturing_cost m 
ON m.product_code = p.product_code
WHERE manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost) OR
	  manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

/* 6. Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  
    for the  fiscal  year 2021  and in the Indian  market. The final output contains these fields, 
								customer_code 
								customer 
								average_discount_percentage */
                                
SELECT pre.customer_code, c.customer, AVG(pre.pre_invoice_discount_pct) AS average_discount_percentage
FROM dim_customer c 
JOIN fact_pre_invoice_deductions pre 
ON pre.customer_code = c.customer_code
WHERE pre.fiscal_year = 2021 AND c.market = "India"
GROUP BY c.customer, pre.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* 7. Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month  .
   This analysis helps to  get an idea of low and high-performing months and take strategic decisions. 
   The final report contains these columns: 
											Month 
											Year 
											Gross sales Amount */
                                            
SELECT s.date AS month, s.fiscal_year AS year, ROUND(SUM(s.sold_quantity*g.gross_price),1) AS gross_sales_amount
FROM dim_customer c
JOIN fact_sales_monthly s 
ON s.customer_code = c.customer_code
JOIN fact_gross_price g 
ON g.product_code = s.product_code AND g.fiscal_year = s.fiscal_year
WHERE c.customer = "Atliq Exclusive"
GROUP BY s.date, s.fiscal_year
ORDER BY s.date ASC;


/* 8.  In which quarter of 2020, got the maximum total_sold_quantity? 
       The final output contains these fields sorted by the total_sold_quantity, 
										Quarter 
										total_sold_quantity */
                                        
SELECT CASE
			WHEN MONTH(date) IN (9, 10, 11) THEN "Q1"
            WHEN MONTH(date) IN (12, 1, 2) THEN "Q2"
            WHEN MONTH(date) IN (3, 4, 5) THEN "Q3"
            ELSE "Q4"
	   END AS quarter, SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly s 
WHERE s.fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 
      and the percentage of contribution?  The final output  contains these fields, 
										channel 
										gross_sales_mln 
										percentage */
		
WITH cte AS (
SELECT c.channel,s.fiscal_year, ROUND(SUM(s.sold_quantity*g.gross_price)/1000000, 1) AS gross_sales_mln
FROM dim_customer c
JOIN fact_sales_monthly s
ON s.customer_code = c.customer_code 
JOIN fact_gross_price g 
ON g.product_code = s.product_code AND g.fiscal_year = s.fiscal_year
GROUP BY c.channel, s.fiscal_year)

SELECT channel, gross_sales_mln, ROUND(((gross_sales_mln)/(SELECT SUM(gross_sales_mln) FROM cte WHERE fiscal_year = 2021))*100,1) AS pct
FROM cte
WHERE fiscal_year = 2021
ORDER BY gross_sales_mln DESC;


/* 10.  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
        The final output contains these fields, 
									division 
									product_code 
									product 
									total_sold_quantity 
									rank_order */
 
WITH cte AS (                                   
SELECT p.division, p.product_code, p.product, SUM(s.sold_quantity) AS total_sold_quantity
FROM dim_product p
JOIN fact_sales_monthly s
ON s.product_code = p.product_code
WHERE fiscal_year = 2021
GROUP BY p.division, p.product_code, p.product),
cte1 AS (
SELECT *, RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rnk
FROM cte)
SELECT * 
FROM cte1
WHERE rnk < 4;

                                
