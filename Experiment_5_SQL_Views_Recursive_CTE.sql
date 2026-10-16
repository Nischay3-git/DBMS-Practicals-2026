-- EXPERIMENT 5
-- AIM: Create and manipulate SQL views for department salary summaries and
-- employee hierarchy, test view updatability, and use recursive CTEs to
-- display employee reporting chains.
--
-- PREREQUISITE:
-- Run Experiment 3 first to create/populate EmployeeManagement.
-- This script is written for MySQL 8.0+.

USE EmployeeManagement;

-- 1. DEPARTMENT SALARY SUMMARY VIEW
CREATE OR REPLACE VIEW Department_Salary_Summary AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS average_salary,
    MAX(e.salary) AS highest_salary,
    MIN(e.salary) AS lowest_salary
FROM Department AS d
LEFT JOIN Employee AS e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT *
FROM Department_Salary_Summary;

-- 2. QUERY THE VIEW: Departments with average salary above 75000
SELECT
    dept_name,
    average_salary
FROM Department_Salary_Summary
WHERE average_salary > 75000;

-- 3. EMPLOYEE HIERARCHY: Add manager_id column if it does not already exist.
-- Run this ALTER TABLE only once on a database that does not already have manager_id.
ALTER TABLE Employee
    ADD COLUMN manager_id INT NULL;

ALTER TABLE Employee
    ADD CONSTRAINT fk_employee_manager
    FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);

-- 4. SET UP EMPLOYEE REPORTING HIERARCHY
-- Top-level managers: IT 105, HR 112, Finance 114, Marketing 122, Research 125
UPDATE Employee
SET manager_id = NULL
WHERE emp_id IN (105, 112, 114, 122, 125);

-- IT department (dept_id = 1)
UPDATE Employee SET manager_id = 105 WHERE emp_id IN (103, 104);
UPDATE Employee SET manager_id = 103 WHERE emp_id IN (101, 102);
UPDATE Employee SET manager_id = 104 WHERE emp_id = 106;

-- HR department (dept_id = 2)
UPDATE Employee SET manager_id = 112 WHERE emp_id IN (107, 108);
UPDATE Employee SET manager_id = 107 WHERE emp_id = 109;
UPDATE Employee SET manager_id = 108 WHERE emp_id IN (110, 111);

-- Finance department (dept_id = 3)
UPDATE Employee SET manager_id = 114 WHERE emp_id IN (113, 115, 116, 117, 118);

-- Marketing department (dept_id = 4)
UPDATE Employee SET manager_id = 122 WHERE emp_id IN (119, 120, 121, 123, 124);

-- Research department (dept_id = 5)
UPDATE Employee SET manager_id = 125 WHERE emp_id IN (126, 127, 128);
UPDATE Employee SET manager_id = 126 WHERE emp_id = 129;
UPDATE Employee SET manager_id = 128 WHERE emp_id = 130;

-- 5. EMPLOYEE HIERARCHY VIEW
CREATE OR REPLACE VIEW Employee_Hierarchy AS
SELECT
    e.emp_id,
    e.emp_name AS employee_name,
    e.manager_id,
    m.emp_name AS manager_name,
    e.salary,
    e.dept_id
FROM Employee AS e
LEFT JOIN Employee AS m
    ON e.manager_id = m.emp_id;

SELECT *
FROM Employee_Hierarchy;

-- 6. TEST UPDATABILITY OF A SIMPLE VIEW
CREATE OR REPLACE VIEW Employee_Basic AS
SELECT
    emp_id,
    emp_name,
    salary,
    dept_id
FROM Employee;

SELECT *
FROM Employee_Basic
WHERE emp_id = 101;

-- 7. UPDATE THROUGH THE VIEW
UPDATE Employee_Basic
SET salary = 78000
WHERE emp_id = 101;

SELECT *
FROM Employee
WHERE emp_id = 101;

-- 8. TEST NON-UPDATABILITY OF AN AGGREGATE VIEW
-- This statement is expected to fail because the view contains aggregate
-- functions and GROUP BY. Uncomment and run it separately to observe the error.
-- UPDATE Department_Salary_Summary
-- SET average_salary = 80000
-- WHERE dept_id = 1;

-- 9. RECURSIVE CTE: Display reporting chains from top-level managers
WITH RECURSIVE EmployeeChain AS (
    -- Anchor member
    SELECT
        emp_id,
        emp_name,
        manager_id,
        0 AS level,
        CAST(emp_name AS CHAR(500)) AS reporting_chain
    FROM Employee
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        ec.level + 1,
        CONCAT(ec.reporting_chain, ' -> ', e.emp_name)
    FROM Employee AS e
    INNER JOIN EmployeeChain AS ec
        ON e.manager_id = ec.emp_id
)
SELECT
    emp_id,
    emp_name,
    manager_id,
    level,
    reporting_chain
FROM EmployeeChain
ORDER BY reporting_chain;

-- 10. RECURSIVE CTE FOR ONE EMPLOYEE: Show employee 101 and their manager chain
WITH RECURSIVE ReportingChain AS (
    SELECT
        emp_id,
        emp_name,
        manager_id,
        0 AS level
    FROM Employee
    WHERE emp_id = 101

    UNION ALL

    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        rc.level + 1
    FROM Employee AS e
    JOIN ReportingChain AS rc
        ON e.emp_id = rc.manager_id
)
SELECT
    emp_id,
    emp_name,
    manager_id,
    level
FROM ReportingChain;
