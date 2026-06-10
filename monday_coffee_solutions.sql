-- MONDAY COFFEE DATA ANALYSIS
SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM sales;
SELECT * FROM products;

-- 1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT city_name,
ROUND((population * 0.25)/1000000,2) as coffee_consumers,
city_rank From city
ORDER BY 2 DESC;

-- 2.Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT *, 
EXTRACT(YEAR FROM sale_date) as year,
EXTRACT(QUARTER FROM sale_date) as qtr
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023
AND EXTRACT(QUARTER FROM sale_date) = 4

SELECT 
SUM(t)
EXTRACT(YEAR FROM sale_date) as year,
EXTRACT(QUARTER FROM sale_date) as qtr
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2023
AND EXTRACT(QUARTER FROM sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;


-- 3.Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT
p.product_name,
COUNT(s.sale_id)as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- 4.Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT
ci.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(
      SUM(s.total):: numeric/
	  COUNT(DISTINCT s.customer_id)
	  ,2) as avg_sale_pr_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- 5.City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
WITH city_table as
(SELECT city_name,
ROUND((population * 0.25)/1000000,2) as coffee_consumers,
city_rank From city
),
customers_table
as
(SELECT
ci.city_name,
COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1)
SELECT customers_table.city_name,
city_table.coffee_consumers as  coffee_consumer_in_millions,
customers_table.unique_cx
FROM city_table
JOIN
customers_table 
ON city_table.city_name = customers_table.city_name;

-- 6.Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
(SELECT 
ci.city_name,
p.product_name,
COUNT(s.sale_id) as total_orders,
DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2) as t1
WHERE RANK >=3;

-- 7.Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT
ci.city_name,
COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN customers as c
ON ci.city_id = c.city_id
JOIN sales as s
ON c.customer_id = s.customer_id
where 
s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1
ORDER BY 2 DESC;

-- 8.Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer
WITH city_table AS
(SELECT
ci.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(
      SUM(s.total):: numeric/
	  COUNT(DISTINCT s.customer_id)
	  ,2) as avg_sale_pr_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent AS
(SELECT city_name, estimated_rent From city)
SELECT
cr.city_name,
cr.estimated_rent,
ct.total_cx,
ct.avg_sale_pr_cx,
ROUND(cr.estimated_rent::numeric/ct.total_cx::numeric,2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name;

-- 9.Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH 
monthly_sales
AS
(SELECT
ci.city_name,
EXTRACT(MONTH FROM sale_date) as month,
EXTRACT(YEAR FROM sale_date) as YEAR,
SUM(s.total) as total_sale
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3
),
growth_ratio AS 
(SELECT
city_name, month, year,
total_sale as cr_month_sale,
LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
FROM monthly_sales)
SELECT
city_name,
month, year, cr_month_sale, last_month_sale,
ROUND((cr_month_sale-last_month_sale)::numeric/ last_month_sale::numeric * 100,2) as growth_ratio
from growth_ratio
WHERE last_month_sale IS NOT NULL

-- 10.Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table AS
(
    SELECT
        ci.city_name,
        SUM(s.total) as total_revenue,
        COUNT(DISTINCT s.customer_id) as total_cx,
        ROUND((SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric), 2) as avg_sale_pr_cx
    FROM sales as s
    JOIN customers as c ON s.customer_id = c.customer_id
    JOIN city as ci ON ci.city_id = c.city_id
    GROUP BY 1
    ORDER BY 2 DESC
),
city_rent AS
(
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25 / 1000000)::numeric, 3) as estimated_coffee_consumer_in_millions
    FROM city  
)
SELECT
    cr.city_name,
    ct.total_revenue,  
    cr.estimated_rent as total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions, 
    ct.avg_sale_pr_cx,
    ROUND((cr.estimated_rent::numeric / ct.total_cx::numeric), 2) as avg_rent_per_cx 
FROM city_rent as cr
JOIN city_table as ct ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

/*
RECOMMENDATIONS 
City 1: Pune
1.Avg rent per cx is very less
2.highest Total revenue 
3.Average sale per customer is also high.

City 2: Delhi
1. Highest estimated coffee consumer which is 7.7M
2. Highest total customer which is 68
3. Average rate per customer 330

City 3: Jaipur 
1. Highest customer number which is 69
2. Average rent per customer is 156
3. Average sale per customer is 11.6K










