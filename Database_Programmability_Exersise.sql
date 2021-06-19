-- 1
DELIMITER //
CREATE PROCEDURE usp_get_employees_salary_above_35000()
BEGIN
SELECT `first_name`, `last_name` FROM `employees`
WHERE `salary`>35000
ORDER BY `first_name`,`last_name`, `employee_id`;
END //
DELIMITER ; 

-- 2
DELIMITER //
CREATE PROCEDURE usp_get_employees_salary_above(above_salary DECIMAL(20,4))
BEGIN
SELECT `first_name`, `last_name` FROM `employees`
WHERE `salary`>= `above_salary`
ORDER BY `first_name`,`last_name`, `employee_id`;
END //
DELIMITER ; 

CALL usp_get_employees_salary_above(125000);

-- 3
DELIMITER //
CREATE PROCEDURE usp_get_towns_starting_with(symbol VARCHAR(20))
BEGIN
SELECT `name` FROM `towns`
WHERE LEFT (`name`, length(symbol)) = `symbol`
ORDER BY `name`;
END //
DELIMITER ; 

CALL usp_get_towns_starting_with('be');

-- 4
DELIMITER //
CREATE PROCEDURE usp_get_employees_from_town(town VARCHAR(50))
BEGIN
SELECT `first_name`, `last_name` FROM `employees` AS e
JOIN `addresses` AS a USING(`address_id`)
JOIN `towns` AS t USING(`town_id`)
WHERE t.`name` = `town`
ORDER BY `first_name`,`last_name`, `employee_id`;
END //
DELIMITER ; 

CALL usp_get_employees_from_town('Sofia');

-- 5
DELIMITER //
CREATE FUNCTION ufn_get_salary_level(salary DECIMAL(19,4))
RETURNS VARCHAR(10) DETERMINISTIC
BEGIN
DECLARE `salary_level` VARCHAR(10);

IF (salary < 30000)
   THEN SET `salary_level` := 'Low';
 ELSEIF (salary <= 50000)
   THEN SET `salary_level` := 'Average';
ELSE
   SET `salary_level` := 'High';
   
END IF;
RETURN `salary_level`;
END //
DELIMITER ; 

SELECT ufn_get_salary_level(50001);

-- 6
DELIMITER //
CREATE PROCEDURE usp_get_employees_by_salary_level(salary_level VARCHAR(10))
BEGIN
SELECT e.`first_name`, e.`last_name` FROM employees AS e
WHERE salary_level = ( SELECT ufn_get_salary_level(e.`salary`))
ORDER BY `first_name` DESC, `last_name` DESC;
END //
DELIMITER ; 

CALL usp_get_employees_by_salary_level('High');

-- 7
DELIMITER //
CREATE FUNCTION ufn_is_word_comprised(set_of_letters VARCHAR(50), word VARCHAR(50))
RETURNS BIT DETERMINISTIC
BEGIN
RETURN (SELECT word REGEXP(CONCAT('^[',set_of_letters,']+$')));
END //
DELIMITER ;

SELECT ufn_is_word_comprised('oistmiahf','halves');

-- 8
DELIMITER //
CREATE PROCEDURE usp_get_holders_full_name()
BEGIN
SELECT CONCAT(`first_name`, ' ', `last_name`) AS 'full_name'
FROM `account_holders`
ORDER BY `full_name`, `id`;
END //
DELIMITER ; 

CALL usp_get_holders_full_name();

-- 9
DELIMITER //
CREATE PROCEDURE usp_get_holders_with_balance_higher_than(amount DECIMAL(19,2))
BEGIN
SELECT e.`first_name`, e.`last_name`
FROM `account_holders` AS e
JOIN `accounts` AS a ON e.`id` = a.`account_holder_id`
WHERE (SELECT SUM(a.`balance`)  GROUP BY a.`account_holder_id`) > amount
GROUP BY e.`id`
ORDER BY `account_holder_id`, `first_name`, `last_name`;
END //
DELIMITER ; 

CALL usp_get_holders_with_balance_higher_than(7000);

-- 10
DELIMITER //
CREATE FUNCTION `ufn_calculate_future_value`(`sum` DECIMAL(19, 4), `interest` DOUBLE, `years` INT)
RETURNS DECIMAL(19, 4)  
DETERMINISTIC   
BEGIN 
	RETURN `sum` * POW(1 + `interest`, `years`);
END //
DELIMITER ;

SELECT ufn_calculate_future_value(1000,0.5,5);

-- 11

DELIMITER //
CREATE PROCEDURE usp_calculate_future_value_for_account(acc_id INT, interest DECIMAL(19,4))
  BEGIN
  SELECT a.`id`, ah.`first_name`, ah.`last_name`, a.`balance` AS 'current_balance', 
   ufn_calculate_future_value (a.`balance`, `interest`, 5) AS 'balance_in_5_years'
   FROM `accounts` AS a
   JOIN `account_holders` AS ah
   ON a.`account_holder_id` = ah.`id`
   WHERE a.`id` = acc_id;
END//
DELIMITER ;

CALL usp_calculate_future_value_for_account(1, 0.1);

-- 12
DELIMITER //
CREATE PROCEDURE usp_deposit_money(account_id INT , money_amount DECIMAL(19,4))
BEGIN
IF money_amount > 0  
THEN UPDATE `accounts` AS a SET `balance` = `balance` + `money_amount` 
WHERE a.`id` = account_id;
END IF;
END //
DELIMITER ;
CALL usp_deposit_money(1, 0.44);

-- 13
DELIMITER //
CREATE PROCEDURE usp_withdraw_money(account_id INT , money_amount DECIMAL(19,4))
BEGIN
IF money_amount > 0  
AND ((SELECT `balance` FROM `accounts` AS a WHERE a.`id` = account_id)>= money_amount)
THEN UPDATE `accounts` AS a SET `balance` = `balance` - `money_amount` 
WHERE a.`id` = account_id;
END IF;
END //
DELIMITER ;
CALL usp_withdraw_money(1, 0.44);

-- 14
DELIMITER //
CREATE PROCEDURE usp_transfer_money(
    from_account_id INT, to_account_id INT, money_amount DECIMAL(19, 4))
BEGIN
    IF money_amount > 0 
        AND from_account_id <> to_account_id 
        AND (SELECT a.`id` 
            FROM `accounts` AS a 
            WHERE a.`id` = to_account_id) IS NOT NULL
        AND (SELECT a.`id` 
            FROM `accounts` AS a 
            WHERE a.`id` = from_account_id) IS NOT NULL
        AND (SELECT a.`balance` 
            FROM `accounts` AS a 
            WHERE a.`id` = from_account_id) >= money_amount
    THEN
        START TRANSACTION;
 
        UPDATE `accounts` AS a 
        SET 
            a.`balance` = a.`balance` + money_amount
        WHERE
            a.id = to_account_id;
 
        UPDATE `accounts` AS a 
        SET 
            a.`balance` = a.`balance` - money_amount
        WHERE
            a.`id` = from_account_id;
 
        IF (SELECT a.`balance` 
            FROM `accounts` AS a 
            WHERE a.id = from_account_id) < 0
            THEN ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    END IF;
END //
DELIMITER ;
 
CALL usp_transfer_money(1, 2, 10);
CALL usp_transfer_money(2, 1, 10);
 
SELECT 
    a.id AS 'account_id', a.account_holder_id, a.balance
FROM
    `accounts` AS a
WHERE
    a.id IN (1 , 2);


