--Inspect data
SELECT * FROM sales_data_sample

--Check unique values of each column
SELECT DISTINCT status FROM sales_data_sample  -- Good for visualization
SELECT DISTINCT year_id FROM sales_data_sample
SELECT DISTINCT productline FROM sales_data_sample  -- Good for visualization
SELECT DISTINCT country FROM sales_data_sample  -- Good for visualization
SELECT DISTINCT dealsize FROM sales_data_sample  -- Good for visualization
SELECT DISTINCT territory FROM sales_data_sample -- Good for visualization

---Analysis---

--Group Sales by Product
SELECT productline, FORMAT(SUM(sales),'c2') as Revenue
FROM sales_data_sample
GROUP BY productline
ORDER BY 2 DESC

--Group Sales by Year
SELECT year_id, FORMAT(SUM(sales),'c2') as Revenue
FROM sales_data_sample
GROUP BY year_id
ORDER BY 2 DESC

--Group Sales by Deal Size
SELECT DEALSIZE, FORMAT(SUM(sales),'c2') as Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC


--What was the best month for sales in a specific year and how much was earned? (November)
SELECT 
	MONTH_ID, 
	FORMAT(SUM(sales),'c2') as Revenue, 
	COUNT(ordernumber) as Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2004  --Change year to view other years
GROUP BY MONTH_ID
ORDER BY SUM(sales) DESC

-- November is the best month. What products do they sell in November?
SELECT 
	MONTH_ID, 
	PRODUCTLINE, 
	FORMAT(SUM(sales),'c2') as Revenue, 
	COUNT(ordernumber) as Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY SUM(sales) DESC

-- Who is the best customer using RFM analysis? Recency, Frequency, Monetary
DROP TABLE IF EXISTS #rfm;
WITH rfm as
(
	SELECT 
		CUSTOMERNAME, 
		SUM(sales) as NetSales, 
		AVG(sales) as AvgSales,
		COUNT(ordernumber) as Frequency,
		MAX(orderdate) as LastOrderDate,
		(select MAX(orderdate) FROM sales_data_sample) as MaxOrderDate,
		DATEDIFF(DD, MAX(orderdate), (select MAX(orderdate) FROM sales_data_sample)) as Recency
	FROM sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_calc as
(

	SELECT 
		r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) as rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) as rfm_frequency,
		NTILE(4) OVER (ORDER BY NetSales) as rfm_monetary
	FROM rfm r
)
SELECT 
	c.*, 
	(rfm_recency + rfm_frequency + rfm_monetary) as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as VARCHAR) + cast(rfm_monetary as VARCHAR) as rfm_cell_string
INTO #rfm
FROM rfm_calc c


SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customer'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144,221) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331, 412) then 'new customer'
		when rfm_cell_string in (222, 223, 233, 322, 421, 232, 423, 234) then 'potential churner'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
FROM #rfm


--What products are sold together?
-- SELECT * FROM sales_data_sample WHERE ORDERNUMBER = 10411
SELECT DISTINCT ordernumber, STUFF(						-- Remove initial comma 

	(SELECT ',' + PRODUCTCODE
	FROM sales_data_sample p
	WHERE ordernumber IN
	(
		SELECT ordernumber
		FROM (
			SELECT ordernumber, count(*) rn		--Create subquery to count the number of items per order
			FROM sales_data_sample
			WHERE status = 'Shipped'
			GROUP BY ordernumber
		) m  -- must give script a name
		WHERE rn > 1							-- Create another subquery where there are mulitple items in an order
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))
		, 1, 1, '') as ProductCodes

FROM sales_data_sample s
ORDER BY 2 DESC

--Which city has the highest number of sales in USA?
SELECT city, format(SUM(sales),'C2') as Revenue
FROM sales_data_sample
WHERE country = 'USA'
GROUP BY city
ORDER BY 2 

--What is the best product in the US?
SELECT country, year_id, productline, FORMAT(SUM(sales),'C') as Revenue
FROM sales_data_sample
WHERE country = 'USA'
GROUP BY country, year_id, productline
ORDER BY SUM(sales) DESC

SELECT country, year_id, productline, FORMAT(SUM(sales),'C') as Revenue
FROM sales_data_sample
WHERE country = 'USA'
GROUP BY country, year_id, productline
ORDER BY 4 DESC
