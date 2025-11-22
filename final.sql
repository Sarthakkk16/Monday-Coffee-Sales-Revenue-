SELECT
	*
FROM
	CITY;

SELECT
	*
FROM
	PRODUCTS;

SELECT
	*
FROM
	CUSTOMERS;

SELECT
	*
FROM
	SALES;

-- Data Analysis

SELECT
	COUNT(*)
FROM
	CITY;

SELECT
	COUNT(*)
FROM
	CUSTOMERS;

SELECT
	COUNT(*)
FROM
	SALES;

SELECT
	COUNT(*)
FROM
	PRODUCTS;

-- Reports & Data Analysis

-- Q1 Coffee Customer Count
-- How many people in exch city are estimated to consume coffee, given that 25% of the population does?

SELECT
	CITY_NAME,
	ROUND((POPULATION * 0.25) / 1000000, 2) AS COFFEE_CONSUMERS,
	CITY_RANK
FROM
	CITY
ORDER BY
	2 DESC;

-- Q2 Total Revenue from coffee sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT
	SUM(TOTAL) AS TOTAL_REVENUE
FROM
	SALES
WHERE
	EXTRACT(
		YEAR
		FROM
			SALE_DATE
	) = 2023
	AND EXTRACT(
		QUARTER
		FROM
			SALE_DATE
	) = 4;

SELECT
	CI.CITY_NAME,
	SUM(S.TOTAL) AS TOTAL_REVENUE
FROM
	SALES AS S
	JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
	JOIN CITY AS CI ON CI.CITY_ID = C.CITY_ID
WHERE
	EXTRACT(
		YEAR
		FROM
			SALE_DATE
	) = 2023
	AND EXTRACT(
		QUARTER
		FROM
			SALE_DATE
	) = 4
GROUP BY
	1
ORDER BY
	TOTAL_REVENUE DESC
LIMIT
	5;

-- Q3 Sales count for each product
-- How many units of each coffee product have been sold?

select * from products;

select * from sales;

SELECT
	P.PRODUCT_NAME,
	COUNT(S.SALE_ID) AS TOTAL_ORDERS
FROM
	PRODUCTS AS P
	LEFT JOIN SALES AS S ON S.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
	1
ORDER BY
	2 DESC
LIMIT
	10;

-- Q4 Avg sales amount per city
-- what is the avg sales amount per customer in each city?

select * from sales;
select * from city;

select avg(s.total) as avg_sales,
ci.city_name
from sales s
join customers c on c.customer_id = s.customer_id
join city ci on ci.city_id = c.city_id
group by 2
order by 1 desc;

SELECT
	CI.CITY_NAME,
	SUM(S.TOTAL) AS TOTAL_REVENUE,
	COUNT(DISTINCT S.CUSTOMER_ID) AS TOTAL_CX,
	ROUND(
		SUM(S.TOTAL)::NUMERIC / COUNT(DISTINCT S.CUSTOMER_ID)::NUMERIC,
		2
	) AS AVG_SALES
FROM
	SALES AS S
	JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
	JOIN CITY AS CI ON CI.CITY_ID = C.CITY_ID
GROUP BY
	1
ORDER BY
	2 DESC;


-- Q5 City Population and coffee consumers
-- Provide a list of cities along with thier population and 
-- estimated coffee consumers.

select * from city;
select * from customers;


with city_table as
(SELECT
	CITY_NAME,
	ROUND((POPULATION * 0.25) / 100000, 2) AS COFFEE_CONSUMER
FROM
	CITY),  customer_table 
as
(SELECT
	CI.CITY_NAME,
	COUNT(DISTINCT C.CUSTOMER_ID) AS UNIQUE_CX
FROM
	SALES AS S
	JOIN CUSTOMERS AS C ON C.CUSTOMER_ID = S.CUSTOMER_ID
	JOIN CITY AS CI ON CI.CITY_ID = C.CITY_ID
GROUP BY
	1) 
select 
	customer_table.city_name,
	city_table.coffee_consumer as coffee_consumer_in_million,
	customer_table.unique_cx
from city_table 
join 
customer_table
on city_table.city_name = customer_table.city_name;

-- Q6 Top selling products by city
-- What are the top 3 selling products in each city based on sales volume ?

SELECT * FROM 
(SELECT
	CI.CITY_NAME,
	P.PRODUCT_NAME,
	COUNT(S.SALE_ID) AS TOTAL_ORDERS,
	dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rank
FROM
	SALES AS S
	JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
	JOIN CUSTOMERS AS C ON C.CUSTOMER_ID = S.CUSTOMER_ID
	JOIN CITY AS CI ON CI.CITY_ID = C.CITY_ID
GROUP BY
	1,
	2
-- ORDER BY
-- 	1,
-- 	3 DESC;
) AS T1 
WHERE RANK <=3;

-- Q7 Customer segmentation by city
-- How many unique customers are there in each city who have purchased cofee products


select * from products;

SELECT
	CI.CITY_NAME,
	COUNT(DISTINCT C.CUSTOMER_ID) AS UNIQUE_CUSTOMERS
FROM
	CITY AS CI
	LEFT JOIN CUSTOMERS AS C ON C.CITY_ID = CI.CITY_ID
	JOIN SALES AS S ON S.CUSTOMER_ID = C.CUSTOMER_ID
WHERE
	S.PRODUCT_ID IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1

-- Q8 Average sales vs rent
-- Find each city and their average sale per customer and avg rent per customer

WITH
	CITY_TABLE AS (
		SELECT
			CI.CITY_NAME,
			COUNT(DISTINCT S.CUSTOMER_ID) AS TOTAL_CX,
			ROUND(
				SUM(S.TOTAL)::NUMERIC / COUNT(DISTINCT S.CUSTOMER_ID)::NUMERIC,
				2
			) AS AVG_SALE_PR_CX
		FROM
			SALES AS S
			JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
			JOIN CITY AS CI ON CI.CITY_ID = C.CITY_ID
		GROUP BY
			1
		ORDER BY
			2 DESC
	),
	CITY_RENT AS (
		SELECT
			CITY_NAME,
			ESTIMATED_RENT
		FROM
			CITY
	)
SELECT
	CR.CITY_NAME,
	CR.ESTIMATED_RENT,
	CT.TOTAL_CX,
	CT.AVG_SALE_PR_CX,
	ROUND((CR.ESTIMATED_RENT::NUMERIC/CT.TOTAL_CX::NUMERIC),2) AS AVG_RENT_PR_CX
FROM
	CITY_RENT AS CR
	JOIN CITY_TABLE AS CT ON CR.CITY_NAME = CT.CITY_NAME
ORDER BY 4 DESC;


-- Q9 Monthly sales Growth 
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
-- by each city 

WITH
monthly_sales
AS
(
	SELECT 
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
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio
FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	

-- Q10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


with city_table
as 
(
	select 
		ci.city_name,
		sum(s.total)as total_revenue,
		count(distinct s.customer_id) as total_cx,
		round(
				sum(s.total)::numeric/
					count(distinct s.customer_id)::numeric
				,2) as avg_sale_pr_cx
	from sales as s
	join customers as c
	on s.customer_id = c.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1
	order by 2 desc		
),
city_rent
as
(	
	select 
		city_name,
		estimated_rent,
		round(population*0.25/1000000,2) as est_coffee_consumer
	from city
)
select 
	cr.city_name,
	est_coffee_consumer,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	round(
			cr.estimated_rent::numeric/
			ct.total_cx::numeric
			,2) as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 4 desc
