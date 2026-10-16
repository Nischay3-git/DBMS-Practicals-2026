-- EXPERIMENT 4
-- AIM: To perform and analyze SQL queries using INNER JOIN, LEFT JOIN, SELF JOIN,
-- 3-way JOIN, correlated subqueries, EXISTS, simulated INTERSECT and EXCEPT
-- operations on the Employee-Department-Project database, and compare execution
-- plans using EXPLAIN.
--
-- PREREQUISITE:
-- Run Experiment_3_Employee_Management.sql first to create and populate the
-- EmployeeManagement database and its tables.

USE EmployeeManagement;

-- 1. INNER JOIN: Display employees with their department names
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee AS e
INNER JOIN Department AS d
    ON e.dept_id = d.dept_id;

-- 2. LEFT JOIN: Display all departments and their employees, if any
SELECT
    d.dept_id,
    d.dept_name,
    e.emp_name
FROM Department AS d
LEFT JOIN Employee AS e
    ON d.dept_id = e.dept_id;

-- 3. SELF JOIN: Display pairs of employees working in the same department
SELECT
    e1.emp_name AS Employee1,
    e2.emp_name AS Employee2,
    e1.dept_id
FROM Employee AS e1
JOIN Employee AS e2
    ON e1.dept_id = e2.dept_id
   AND e1.emp_id < e2.emp_id;

-- 4. THREE-WAY JOIN: Display employee, department and project names
-- This uses Employee, Department, Employee_Project and Project.
SELECT
    e.emp_name,
    d.dept_name,
    p.project_name
FROM Employee AS e
JOIN Department AS d
    ON e.dept_id = d.dept_id
JOIN Employee_Project AS ep
    ON e.emp_id = ep.emp_id
JOIN Project AS p
    ON ep.project_id = p.project_id;

-- 5. JOIN QUERY AS SHOWN IN THE EXPERIMENT:
-- Display employee name, department name and salary for each project
-- belonging to the employee's department.
SELECT
    e.emp_name,
    d.dept_name,
    e.salary
FROM Employee AS e
JOIN Department AS d
    ON e.dept_id = d.dept_id
JOIN Project AS p
    ON d.dept_id = p.dept_id;

-- 6. CORRELATED SUBQUERY: Employees earning more than their department average
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    e.dept_id
FROM Employee AS e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee AS e2
    WHERE e2.dept_id = e.dept_id
);

-- 7. EXISTS: Employees assigned to at least one project
SELECT
    e.emp_id,
    e.emp_name
FROM Employee AS e
WHERE EXISTS (
    SELECT 1
    FROM Employee_Project AS ep
    WHERE ep.emp_id = e.emp_id
);

-- 8. SIMULATED INTERSECT:
-- Employees in department 1 who are assigned to project 201
SELECT
    e.emp_id,
    e.emp_name
FROM Employee AS e
WHERE e.dept_id = 1
  AND EXISTS (
      SELECT 1
      FROM Employee_Project AS ep
      WHERE ep.emp_id = e.emp_id
        AND ep.project_id = 201
  );

-- 9. SIMULATED EXCEPT:
-- Employees in department 1 who are NOT assigned to project 201
SELECT
    e.emp_id,
    e.emp_name
FROM Employee AS e
WHERE e.dept_id = 1
  AND NOT EXISTS (
      SELECT 1
      FROM Employee_Project AS ep
      WHERE ep.emp_id = e.emp_id
        AND ep.project_id = 201
  );

-- 10. EXECUTION PLAN: INNER JOIN
EXPLAIN
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee AS e
INNER JOIN Department AS d
    ON e.dept_id = d.dept_id;

-- 11. EXECUTION PLAN: LEFT JOIN
EXPLAIN
SELECT
    d.dept_name,
    e.emp_name
FROM Department AS d
LEFT JOIN Employee AS e
    ON d.dept_id = e.dept_id;

-- 12. EXECUTION PLAN: CORRELATED SUBQUERY
EXPLAIN
SELECT
    e.emp_name,
    e.salary
FROM Employee AS e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee AS e2
    WHERE e2.dept_id = e.dept_id
);

-- 13. EXECUTION PLAN: EXISTS
EXPLAIN
SELECT
    e.emp_id,
    e.emp_name
FROM Employee AS e
WHERE EXISTS (
    SELECT 1
    FROM Employee_Project AS ep
    WHERE ep.emp_id = e.emp_id
);
