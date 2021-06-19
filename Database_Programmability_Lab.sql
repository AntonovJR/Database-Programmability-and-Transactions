-- 1
DELIMITER //
CREATE FUNCTION ufn_count_employees_by_town(town_name VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN
DECLARE `emp_count` INT;
SET `emp_count` := (SELECT COUNT(*) FROM `employees`
JOIN `addresses` USING(`address_id`)
JOIN `towns` AS t USING(`town_id`)
WHERE t.`name` = `town_name`);
RETURN `emp_count`;
END //
DELIMITER ; 

SELECT ufn_count_employees_by_town('Sofia');

-- 2

DELIMITER //
CREATE PROCEDURE usp_raise_salaries(department_name VARCHAR(50))
BEGIN
UPDATE `employees` 
JOIN `departments` AS d USING(`department_id`)
SET `salary` = `salary` * 1.05
WHERE d.`name` = `department_name`; 
END //
DELIMITER ; 

CALL usp_raise_salaries('Engineering');

-- 3

DELIMITER //
CREATE PROCEDURE usp_raise_salary_by_id(id INT)
BEGIN
START TRANSACTION;
IF( 
(SELECT count(`employee_id`) FROM employees 
WHERE `employee_id` LIKE `id`)<>1) THEN
ROLLBACK;
ELSE
UPDATE `employees` SET `salary` = salary * 1.05
WHERE `employee_id` = `id`;
END IF;
END //
DELIMITER ; 

CALL usp_raise_salary_by_id(1);

-- 4
CREATE TABLE `deleted_employees`(
`employee_id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(20),
`last_name` VARCHAR(20),
`middle_name` VARCHAR(20),
`job_title` VARCHAR(50),
`department_id` INT,
`salary` DOUBLE
);
DELIMITER //
CREATE TRIGGER tr_deleted_employees
AFTER DELETE
ON `employees`
FOR EACH ROW
BEGIN

INSERT INTO `deleted_employees`(`first_name`, `last_name`,
`middle_name`,`job_title`,`department_id`,`salary`)

VALUES(OLD.`first_name`,OLD.`last_name`,OLD.`middle_name`,
OLD.`job_title`,OLD.`department_id`, OLD.`salary`);

END//
DELIMITER ;
DELETE FROM `employees` WHERE `employee_id` IN (1);
