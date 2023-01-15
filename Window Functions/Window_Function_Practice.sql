SELECT * FROM Current_Personnel
SELECT * FROM Departments


CREATE VIEW windowpractice AS
(
SELECT 
	e.emp_no as emp_id, 
	e.first_name as emp_name,
	d.dept_name, 
	cp.current_salary as salary
FROM 
	Employees e
JOIN Current_Personnel cp ON e.sid_Employee = cp.sid_Department
JOIN Departments d ON cp.sid_Department = d.sid_Department
)

SELECT * FROM windowpractice

SELECT dept_name, max(salary) as max_salary
FROM windowpractice
GROUP BY dept_name

SELECT
	w.*,
	max(salary) over(partition by dept_name) as max_salary
FROM 
	windowpractice w


-- row_number, rank, dense_rank, lead, lag

SELECT w.*,
	row_number() over (partition by dept_name ORDER BY salary DESC) as rn
FROM windowpractice w;

--Fetch the first 2 employees from each department to join the company

SELECT * FROM (
SELECT w.*,
	row_number() over (partition by dept_name ORDER BY emp_id) as rn
FROM windowpractice w) x
WHERE x.rn < 3;

--Fetch top 3 employees in each department earning the max salary

SELECT * FROM (
	SELECT 
		w.*,
		rank() over(partition by dept_name order by salary desc) as rnk
	FROM windowpractice w ) x
WHERE x.rnk < 4;


SELECT 
	w.*,
	rank() over(partition by dept_name order by salary desc) as rnk,
	dense_rank() over(partition by dept_name order by salary desc) as dense_rnk,
	row_number() over (partition by dept_name ORDER BY salary DESC) as rn
FROM 
	windowpractice w


-- Fetch a query to display if the salary of an employee is higher, lower, or equal to the previous employee
SELECT w.*,
	lag(salary) over (partition by dept_name order by emp_id) as prev_emp_salary,
	lead(salary) over (partition by dept_name order by emp_id) as next_emp_salary
FROM
	windowpractice w


SELECT w.*,
	lag(salary) over (partition by dept_name order by emp_id) as prev_emp_salary,
	CASE 
		WHEN w.salary > lag(salary) over (partition by dept_name order by emp_id) then 'Higher than Previous Employee'
		WHEN w.salary < lag(salary) over (partition by dept_name order by emp_id) then 'Lower than Previous Employee'
		WHEN w.salary = lag(salary) over (partition by dept_name order by emp_id) then 'Same as Previous Employee'
	END sal_range
FROM
	windowpractice w