---Create a view---

--1.) I want all the themes name
--2.) I want all assigned Parent themes name

--The S, T and P asssigned to the tables are called aliases and they make joining and selection of columns easier without typing the full name. So S means Sets table, T means Themes table and P her means Parent Theme

--The themes table have two ID columns (id and parent_id) and one Name column. However, the one name column can be used to determine what the theme name is and what the parent theme name is, depending on the joins made. 
--In the Sets table, there is only themes_id which matches id in the themes table. To know the theme for a given set, we join the themes_id from Sets table to the id in the themes table.

--Now, for a given theme in the themes table, there is also an assigned parent_theme. So I joined the themes table again but this time, not to the Sets table but to the themes table again on id and parent_id. This is because, we want to also know the Parent theme name assigned to a theme.

CREATE VIEW analytics_main as 
(
SELECT s.set_num, s.name as set_name, s.year, s.theme_id, cast(s.num_parts as numeric) as num_parts, t.name as theme_name, t.parent_id, p.name as parent_theme_name,
	CASE 
	WHEN s.year between 1901 and 2000 then '20th_Century'
	WHEN s.year between 2001 and 2100 then '21st_Century'
	END as century
FROM sets s
LEFT JOIN themes t on s.theme_id = t.id
LEFT JOIN themes p on t.parent_id = p.id
)

SELECT * FROM analytics_main

---1---
---What is the total number of parts per theme?---
SELECT theme_name, sum(num_parts) as total_num_parts
FROM analytics_main
--WHERE parent_theme_name IS NOT NULL
GROUP BY theme_name
ORDER BY 2 DESC

---2---
---What is the total number of parts per year?---
SELECT year, sum(num_parts) as total_num_parts
FROM analytics_main
--WHERE parent_theme_name IS NOT NULL
GROUP BY year
ORDER BY 2 DESC

---3---
---How many sets were created in each Century in the dataset?---
SELECT century, count(set_num) as total_set_num
FROM analytics_main
--WHERE parent_id IS NOT NULL
GROUP BY century


---4---
---What percentage of sets were released in the 21st Century were Trains themed? Use CTE and subqueries---
WITH CTE as 
(
	SELECT century, theme_name, count(set_num) as total_set_num
	FROM analytics_main
	WHERE century = '21st_Century'
	GROUP BY century, theme_name
)
SELECT SUM(total_set_num) as num_train_sets, sum(percentage) as train_set_percent
FROM
(
SELECT century, theme_name, total_set_num, sum(total_set_num) OVER() as total, cast(1.00*total_set_num/sum(total_set_num) OVER() as decimal(5,4)) * 100 as percentage
FROM CTE
)m
WHERE theme_name like '%train%' --sub in any set name--


---5---
---What is the most popular theme by year for sets released in 21st Century? Subquery required---
SELECT year, theme_name, total_set_num
FROM
(
	SELECT year, theme_name, count(set_num) as total_set_num, ROW_NUMBER() OVER (PARTITION BY year ORDER BY count(set_num) desc) rn
	FROM analytics_main
	WHERE century = '21st_century'
	GROUP BY year, theme_name
)m
WHERE rn = 1
ORDER BY year desc


---6---
---What is the most produced color of lego in terms of quantity of parts?---
SELECT color_name, sum(quantity) as quantity_of_parts
FROM 
(
	SELECT inv.color_id, inv.inventory_id, inv.part_num, cast(inv.quantity as numeric) as quantity, inv.is_spare, c.name as color_name, c.rgb, p.name as part_name, p.part_material, pc.name as category_name
	FROM inventory_parts inv
	INNER JOIN colors c ON inv.color_id = c.id
	INNER JOIN parts p ON inv.part_num = p.part_num
	INNER JOIN part_categories pc ON p.part_cat_id = pc.id
)main
GROUP BY color_name
ORDER BY 2 DESC