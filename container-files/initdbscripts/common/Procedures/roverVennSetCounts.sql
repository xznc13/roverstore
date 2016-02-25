DELIMITER $$
DROP PROCEDURE IF EXISTS roverVennSetCounts;
CREATE PROCEDURE roverVennSetCounts(IN in_core_system text)
BEGIN
-- -----------------------------------------------------------------------------------------------------
-- (C) Red Hound Limited 2015
-- -----------------------------------------------------------------------------------------------------
--
-- Title	ROVER - Venn record set counts for all systems
--
-- DB:		MARIADB
--
-- Purpose	Retrieve the number of rows in each Venn recordset for systems that are switched on
--
-- Version	V0.2 - move to prepared statements
--			V0.1 - Initial draft
--
-- -----------------------------------------------------------------------------------------------------

-- -----------------------------------------------------
-- Logging variables
-- -----------------------------------------------------
DECLARE v_logging_process TEXT DEFAULT 'roverVennSetCounts';

-- -----------------------------------------------------
-- Declare statements
-- -----------------------------------------------------
DECLARE v_core_system text;
DECLARE v_core_prod_table text;
DECLARE v_core_uat_table text;
DECLARE v_sql_command text;
DECLARE v_sql_union text;
DECLARE v_all_or_one text;
DECLARE v_process_date date;

-- -----------------------------------------------------
-- Handlers
-- -----------------------------------------------------
DECLARE EXIT HANDLER FOR SQLEXCEPTIOn
BEGIN
GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);

if @full_error is NULl then
  set @full_error = 'It has not been possible to retrieve the SQL error';
end if;

call roverErrorHandler(v_logging_process, @full_error);
END;

-- -----------------------------------------------------
-- End of declares
-- -----------------------------------------------------

CALL roverLogging(4, v_logging_process,'UI','Starting...');

-- -----------------------------------------------------
-- Pull the process date
-- -----------------------------------------------------
SET v_sql_command = concat('SELECT engine_all_or_one, process_date FROM control into @_all_or_one, @_process_date');
SET @s = v_sql_command;
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
set v_all_or_one = @_all_or_one;
set v_process_date = @_process_date;

-- -----------------------------------------------------
-- Set the process_date
-- -----------------------------------------------------
if upper(v_all_or_one) = 'ALL' then
  set v_process_date = '0000-00-00';
end if;

-- -----------------------------------------------------
-- Build the and execute the SQL
-- -----------------------------------------------------
SET v_sql_command = '';

-- -----------------------------------------------------
-- Build and execute the SQL
-- -----------------------------------------------------
set v_sql_command = '';
set v_sql_command = concat(v_sql_command,'select  ');
set v_sql_command = concat(v_sql_command,'  core_system as ''System''');
set v_sql_command = concat(v_sql_command,' ,prod_dups as ''PROD Duplicates''');
set v_sql_command = concat(v_sql_command,' ,prod_unique as ''PROD''');
set v_sql_command = concat(v_sql_command,' ,prod_only as ''PROD Only''');
set v_sql_command = concat(v_sql_command,' ,in_both as ''BOTH''');
set v_sql_command = concat(v_sql_command,' ,uat_only as ''UAT Only''');
set v_sql_command = concat(v_sql_command,' ,uat_unique as ''UAT''');
set v_sql_command = concat(v_sql_command,' ,uat_dups as ''UAT Duplicates''');
set v_sql_command = concat(v_sql_command,' from dashboard_counts tbl1');
set v_sql_command = concat(v_sql_command,' where tbl1.date_time = (select max(tbl2.date_time)');
set v_sql_command = concat(v_sql_command,'                           from dashboard_counts tbl2');
set v_sql_command = concat(v_sql_command,'                           WHERE tbl1.core_system = tbl2.core_system limit 1)');
set v_sql_command = concat(v_sql_command,'  AND tbl1.process_date = ''',v_process_date,'''');
set v_sql_command = concat(v_sql_command,'  AND tbl1.core_system = ''',in_core_system,'''');
set v_sql_command = concat(v_sql_command,' order by tbl1.core_system, tbl1.date_time desc;');

CALL roverLogging(4, v_logging_process,'UI',REPLACE(v_sql_command,char(39),"''"));


CALL roverLogging(4, v_logging_process,'UI',REPLACE(v_sql_command,char(39),"''"));

SET @s = v_sql_command;
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

    
-- -----------------------------------------------------------------------------------------------------
CALL roverLogging(4,v_logging_process,'UI','End');
end $$
DELIMITER ;
-- -----------------------------------------------------------------------------------------------------
