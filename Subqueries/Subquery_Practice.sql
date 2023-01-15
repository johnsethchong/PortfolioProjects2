----SUBQUERIES----


----Find the employees whose salary is more than the average salary earned by all employees----
-- 1) find the avg salary
SELECT AVG(salary) FROM employee
-- 2) filter employees based on the above avg salary
SELECT *
FROM employee e
WHERE salary > (SELECT AVG(salary) FROM employee)
ORDER BY e.salary DESC;

----SCALAR SUBQUERIES - returns exactly 1 row and 1 column ----
----Find the employees who earn more than the average salary earned by all employees----
SELECT *
FROM employee e
WHERE salary > (SELECT AVG(salary) FROM employee)
ORDER BY e.salary DESC;

SELECT e.*, ROUND(avg_sal.sal,2) AS avg_salary
FROM employee e
join (SELECT AVG(salary) sal FROM employee) avg_sal
	ON e.salary > avg_sal.sal;


----CORRELATED SUBQUERY - A subquery related to the Outer query ----
----Find the employees in each department who earn more than the average salary in that department---=
--1) Find the avg salary per department
SELECT AVG(salary) 
FROM employee 
GROUP BY dept_name
--2) Filter data from employee tables based on avg salary from above result.
SELECT *
FROM employee e
WHERE salary > (SELECT avg(salary) FROM employee e2 WHERE e2.dept_name=e.dept_name)
ORDER BY dept_name, salary

----Find department who do not have any employees----
SELECT *
FROM department d
WHERE NOT EXISTS (SELECT 1 FROM employee e WHERE e.dept_name = d.dept_name)

----NESTED SUBQUERY----
----Find stores whose sales where better than the average sales accross all stores 
--1) Find the sales for each store
SELECT store_name, SUM(price) as total_sales 
FROM sales 
GROUP BY store_name

--2) Average sales for all stores
SELECT avg(total_sales)
FROM (
	SELECT store_name, SUM(price) as total_sales
	FROM sales
	GROUP BY store_name) sales

--3) Compare 2 with 1

SELECT *
FROM (
	SELECT store_name, SUM(price) as total_sales
	FROM sales
	GROUP BY store_name) sales
JOIN
(SELECT avg(total_sales) as sales
FROM (
	SELECT store_name, SUM(price) as total_sales
	FROM sales
	GROUP BY store_name
)x) avg_sales
	on sales.total_sales > avg_sales.sales;

----Simplify same code using WITH clause/CTE----
WITH salesCTE as

	(SELECT store_name, SUM(price) as total_sales
	FROM sales
	GROUP BY store_name)

SELECT *
FROM salesCTE
JOIN
(SELECT avg(total_sales) as sales
FROM salesCTE ) avg_sales
	on salesCTE.total_sales > avg_sales.sales;


----Using a subquery in SELECT clause----
--Fetch all employee details and add remarks to those employees who earn more than the average pay--
SELECT *,
(CASE 
	WHEN salary > (SELECT AVG(salary) FROM employee) THEN 'Higher Than Average'
	WHEN salary < (SELECT AVG(salary) FROM employee) THEN 'Lower Than Average'
	ELSE 'Average'
			END) AS remarks
FROM employee;

--Better alternate approach--
SELECT *,
(CASE 
	WHEN salary > avg_sal.sal THEN 'Higher Than Average'
	WHEN salary < avg_sal.sal THEN 'Lower Than Average'
	ELSE 'Average'
			END) AS remarks
FROM employee
CROSS join(SELECT AVG(salary) sal FROM employee) avg_sal;


----HAVING CLAUSE - Find the stores who have sold more units than the average units sold by all stores----
SELECT store_name, SUM(quantity)
FROM sales
GROUP BY store_name
HAVING sum(quantity) > (SELECT AVG(quantity) FROM sales)



----INSERT----
SELECT * FROM employee_history

INSERT INTO employee_history
SELECT e.emp_id, e.emp_name, d.dept_name, e.salary, d.location
FROM employee e
JOIN department d ON d.dept_name = e.dept_name
WHERE NOT EXISTS (SELECT 1 FROM employee_history eh WHERE eh.emp_id = e.emp_id);


----UPDATE----
--Give 10% increment to all employees in Bangalore location based on the maximum salary earned in each dept----
UPDATE employee
SET salary = (SELECT MAX(salary) + (MAX(salary) * 0.1) 
				FROM employee_history eh 
				WHERE eh.dept_name = employee.dept_name)
WHERE employee.dept_name IN (SELECT dept_name 
								FROM department 
								WHERE location = 'Bangalore')
AND employee.emp_id IN (SELECT emp_id FROM employee_history);


----DELETE----
DELETE FROM department
WHERE dept_name in (SELECT dept_name
					FROM department d
					WHERE NOT EXISTS (SELECT 1 FROM employee e WHERE e.dept_name = d.dept_name)
					);
