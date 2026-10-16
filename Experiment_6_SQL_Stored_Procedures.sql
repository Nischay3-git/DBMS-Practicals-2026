-- EXPERIMENT 6
-- AIM: Create a stored procedure transfer_employee(emp_id, new_dept_id) with
-- validation/error handling, and triggers for salary validation and audit logging.
--
-- PREREQUISITE:
-- Run Experiment 3 first to create/populate EmployeeManagement.
-- MySQL 8.0+ recommended.
--
-- NOTE:
-- This script uses a test employee with emp_id = 131. It inserts that employee
-- with a valid salary before running update/audit tests.

USE EmployeeManagement;

-- 1. STORED PROCEDURE: transfer_employee
DROP PROCEDURE IF EXISTS transfer_employee;

DELIMITER //

CREATE PROCEDURE transfer_employee(
    IN p_emp_id INT,
    IN p_new_dept_id INT
)
BEGIN
    DECLARE v_employee_count INT DEFAULT 0;
    DECLARE v_department_count INT DEFAULT 0;
    DECLARE v_current_dept INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error occurred. Transaction rolled back.' AS message;
    END;

    START TRANSACTION;

    SELECT COUNT(*)
    INTO v_employee_count
    FROM Employee
    WHERE emp_id = p_emp_id;

    IF v_employee_count = 0 THEN
        ROLLBACK;
        SELECT 'Error: Employee does not exist.' AS message;
    ELSE
        SELECT COUNT(*)
        INTO v_department_count
        FROM Department
        WHERE dept_id = p_new_dept_id;

        IF v_department_count = 0 THEN
            ROLLBACK;
            SELECT 'Error: Department does not exist.' AS message;
        ELSE
            SELECT dept_id
            INTO v_current_dept
            FROM Employee
            WHERE emp_id = p_emp_id;

            IF v_current_dept = p_new_dept_id THEN
                ROLLBACK;
                SELECT 'Error: Employee is already in this department.' AS message;
            ELSE
                UPDATE Employee
                SET dept_id = p_new_dept_id
                WHERE emp_id = p_emp_id;

                COMMIT;
                SELECT 'Employee transferred successfully.' AS message;
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- 2. TEST THE STORED PROCEDURE
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee AS e
JOIN Department AS d ON e.dept_id = d.dept_id
WHERE e.emp_id = 101;

-- Transfer employee 101 to department 3
CALL transfer_employee(101, 3);

-- Verify updated department
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name
FROM Employee AS e
JOIN Department AS d ON e.dept_id = d.dept_id
WHERE e.emp_id = 101;

-- Edge case: employee does not exist
CALL transfer_employee(999, 3);

-- Edge case: department does not exist
CALL transfer_employee(101, 99);

-- Edge case: employee is already in the requested department.
-- Run after the successful transfer above.
CALL transfer_employee(101, 3);

-- 3. SALARY VALIDATION TRIGGER (INSERT)
DROP TRIGGER IF EXISTS validate_employee_salary;

DELIMITER //

CREATE TRIGGER validate_employee_salary
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary < 15000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary cannot be NULL and must be at least 15000';
    END IF;
END //

DELIMITER ;

-- Test invalid salary. This INSERT is expected to fail; run it separately
-- if your SQL client stops executing the script after an error.
-- INSERT INTO Employee (emp_id, emp_name, gender, salary, hire_date, dept_id)
-- VALUES (131, 'Test Employee', 'M', 10000, '2026-09-25', 1);

-- 4. INSERT A VALID TEST EMPLOYEE
-- Remove any leftover test row first (safe if it does not exist).
DELETE FROM Employee WHERE emp_id = 131;

INSERT INTO Employee (emp_id, emp_name, gender, salary, hire_date, dept_id)
VALUES (131, 'Test Employee', 'M', 30000, '2026-09-25', 1);

SELECT emp_id, emp_name, salary
FROM Employee
WHERE emp_id = 131;

-- 5. SALARY VALIDATION TRIGGER (UPDATE)
DROP TRIGGER IF EXISTS validate_employee_salary_update;

DELIMITER //

CREATE TRIGGER validate_employee_salary_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary < 15000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary cannot be NULL and must be at least 15000';
    END IF;
END //

DELIMITER ;

-- Test invalid salary update. This statement is expected to fail.
-- Uncomment and run separately to observe the trigger error.
-- UPDATE Employee SET salary = 5000 WHERE emp_id = 131;

-- Verify the salary remains valid
SELECT emp_id, emp_name, salary
FROM Employee
WHERE emp_id = 131;

-- 6. CREATE AUDIT TABLE
CREATE TABLE IF NOT EXISTS Salary_Audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(30)
);

-- 7. AUDIT LOGGING TRIGGER
DROP TRIGGER IF EXISTS salary_audit_trigger;

DELIMITER //

CREATE TRIGGER salary_audit_trigger
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NOT (OLD.salary <=> NEW.salary) THEN
        INSERT INTO Salary_Audit (
            emp_id,
            old_salary,
            new_salary,
            action
        )
        VALUES (
            NEW.emp_id,
            OLD.salary,
            NEW.salary,
            'SALARY UPDATED'
        );
    END IF;
END //

DELIMITER ;

-- 8. TEST AUDIT TRIGGER
UPDATE Employee
SET salary = 35000
WHERE emp_id = 131;

SELECT *
FROM Salary_Audit
WHERE emp_id = 131
ORDER BY audit_id;

-- 9. TEST MULTIPLE SALARY CHANGES
UPDATE Employee SET salary = 40000 WHERE emp_id = 131;
UPDATE Employee SET salary = 45000 WHERE emp_id = 131;

SELECT
    audit_id,
    emp_id,
    old_salary,
    new_salary,
    action
FROM Salary_Audit
WHERE emp_id = 131
ORDER BY audit_id;

-- 10. EDGE CASE: SALARY UNCHANGED (should not create a new audit row)
UPDATE Employee
SET salary = 45000
WHERE emp_id = 131;

SELECT
    audit_id,
    emp_id,
    old_salary,
    new_salary,
    action
FROM Salary_Audit
WHERE emp_id = 131
ORDER BY audit_id;

-- 11. CHECK ALL TRIGGERS AND THE STORED PROCEDURE
SHOW TRIGGERS;

SHOW PROCEDURE STATUS
WHERE Db = DATABASE();
