
-----------------------------------------------------------------
-- Concurrency and Recoverability
-----------------------------------------------------------------
-- NOTES:
-- The practice is performed on a SQL SERVER server, although it can be performed on a MySQL server.
-- To perform the practice you must have a SQL client, for example: https://www.heidisql.com/downloads/releases/HeidiSQL_10.1_32_Portable.zip


-- Create a database and table for testing the isolation levels
USE master


 
IF EXISTS ( SELECT 1
FROM sys.databases
WHERE name = 'IsolationDB_alumno1' )
DROP DATABASE IsolationDB_alumno1 ;


CREATE DATABASE IsolationDB_alumno1 ;


USE IsolationDB_alumno1 ;


-- 0c) From the HeidiSQL client instance generate the schemas and load the data. 
-- NOTE: To execute a code selection use Ctrl+F9.
-- At the bottom, this client shows the queries executed for each action.
-- Note that when for example updating the available databases (F5), the client
-- performs a query to a catalog view (sys.databases) to obtain this information.
-- Another example is if the student displays the information of one of 
-- the generated schemas (e.g. dbo.OFFICES). Similar to the previous case, the client generates a series of queries to obtain the necessary information, in this case about INFORMATION_SCHEMA of the engine.

USE IsolationDB_alumno1 ;
DELETE tblInventory

CREATE TABLE tblInventory
(
id_value INT PRIMARY KEY ,
Product VARCHAR(20),
ItemsInStock INT
) ;


INSERT INTO tblInventory
VALUES ( 1, 'Notebook', 50 ) ;
INSERT INTO tblInventory
VALUES ( 2, 'iPad', 10  ) ;
INSERT INTO tblInventory
VALUES ( 3, 'iPhone', 5  ) ;
INSERT INTO tblInventory
VALUES ( 4, 'Printer', 20 ) ;
INSERT INTO tblInventory
VALUES ( 5, 'Headset', 50  ) ;

------------------------------------------------------------------------
-- 1) Implicit and Explicit Transactions.
------------------------------------------------------------------------
-- 1a) Insert a new item in the tblInventory table. What is an implicit transaction?

-- 1b) Verify that the tuple was inserted correctly from the other client.

-- 1c) Update the ItemsInStock attribute by 400.

-- 1d) Execute the following instructions.


-- CONNECTION 1:

USE IsolationDB_alumno1;
SELECT * FROM tblInventory WHERE Product = 'Notebook'

BEGIN TRANSACTION
UPDATE tblInventory SET ItemsInStock = 100 WHERE Product = 'Notebook'

SELECT * FROM tblInventory WHERE Product = 'Notebook'

-- CONNECTION 2:
USE IsolationDB_alumno1;

SELECT * FROM tblInventory WHERE Product = 'Notebook'

-- Were the queries executed successfully? Why?
-- What is an explicit transaction?

-- In CONNECTION 1, undo the transaction. 
--  What about CONNECTION 2? 
--  What is the final value of the item?ROLLBACK TRANSACTION

------------------------------------------------------------------------
-- 2) Niveles de aislaci�n y problemas de concurrencia.
------------------------------------------------------------------------
--  Dirty read example
------------------------------------------------------------------------	
-- Step 1:
-- Start a transaction but don't commit it
USE IsolationDB_alumno1 ;

BEGIN TRAN
UPDATE tblInventory
SET ItemsInStock = 10 ;
--<EXECUTE>

-- Step 2:
-- Start a new connection and change your isolation level
USE IsolationDB_alumno1 ;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
SELECT *
FROM tblInventory ;
--<EXECUTE>

-- Step 3:
-- Return to the connection from Step 1 and issue a ROLLBACK
ROLLBACK TRANSACTION ;
--<EXECUTE>

-- Step 4:
-- Rerun the SELECT statement in the connection from Step 2
SELECT *
FROM tblInventory ;
-- <EXECUTE>


-- Check how the READ COMMITTED isolation level solves the problem.
--  What is the associated consequence?
------------------------------------------------------------------------
--  Non repeatable reads example
------------------------------------------------------------------------
-- Step 1:
-- Read data in the default isolation level
USE IsolationDB_alumno1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED ;
BEGIN TRAN
SELECT AVG(ItemsInStock)
FROM tblInventory ;
--<EXECUTE>

-- Step 2:
-- In a new connection, update the table:
USE IsolationDB_alumno1 ;
UPDATE tblInventory
SET ItemsInStock = 500
WHERE id_value = 5 ;
--<EXECUTE>

-- Step 3:
--  back to the first connection and
-- run the same SELECT statement:
SELECT AVG(ItemsInStock)
FROM tblInventory ;
--<EXECUTE>

-- Step 4:
-- issue a ROLLBACK
ROLLBACK TRANSACTION ;
--<EXECUTE>

-- Notice how the first transaction read two different values before it ended. 
--How is this possible?
------------------------------------------------------------------------
--  Repeatable reads example
------------------------------------------------------------------------
-- Step 1:
-- Read data in the Repeatable Read isolation level
USE IsolationDB_alumno1 ;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
BEGIN TRAN
SELECT AVG(ItemsInStock)
FROM tblInventory ;
--<EXECUTE>

-- Step 2:
-- In the second connection, update the table:
USE IsolationDB_alumno1 ;
UPDATE tblInventory
SET ItemsInStock = 5000
WHERE id_value = 2 ;
--<EXECUTE>

-- You should notice that the UPDATE process blocks,
-- and returns no data or messages

-- Step 3:
--  back to the first connection and
-- run the same SELECT statement:
SELECT AVG(ItemsInStock)
FROM tblInventory ;
--<EXECUTE>

-- Step 4:
-- issue a ROLLBACK
ROLLBACK TRANSACTION ;
--<EXECUTE>

-- Does it solve the problem of Repeatable reads?

------------------------------------------------------------------------
--  Phantom Read Example 
------------------------------------------------------------------------
-- Close all connections and open two new ones
-- Step 1:
USE IsolationDB_alumno1 ;
--SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRAN
SELECT *
FROM tblInventory
WHERE id_value BETWEEN 2 AND 7
--<EXECUTE>

DELETE
FROM tblInventory
WHERE id_value = 6


-- Step 2:
-- In the second connection, insert new data
USE IsolationDB_alumno1 ;
INSERT INTO tblInventory
VALUES ( 6, 'Router', 50  ) ;
--<EXECUTE>

-- Step 3:
--  back to the first connection and rerun the SELECT
SELECT *
FROM tblInventory
WHERE id_value BETWEEN 2 AND 7 ;
--<EXECUTE>-- Notice one additional row

-- Step 4:
-- issue a ROLLBACK
ROLLBACK TRANSACTION ;
--<EXECUTE>

--How to avoid the Phantom Reads problem?

------------------------------------------------------------------------
--  Lost update example
------------------------------------------------------------------------
Update tblInventory set ItemsInStock = 10 where id_value=1
Select * from tblInventory where id_value=1		

-- Transaction 1:
Set Transaction Isolation Level Read Committed		-- default isolation level
--SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
USE IsolationDB_alumno1 ;
Begin TRAN
Declare @ItemsInStock int 

Select @ItemsInStock = ItemsInStock 
from tblInventory where id_value=1

-- Transaction takes 30 seconds
Waitfor Delay '00:00:30'
Set @ItemsInStock = @ItemsInStock - 1

Update tblInventory 
Set ItemsInStock = @ItemsInStock where id_value=1

Print @ItemsInStock
Commit Transaction

Select * from tblInventory where id_value=1	

-- Transaction 2:
Set Transaction Isolation Level Read Committed	
USE IsolationDB_alumno1 ;
Begin TRAN
Declare @ItemsInStock int

Select @ItemsInStock = ItemsInStock 
from tblInventory where id_value=1

-- Transaction takes 1 second
Waitfor Delay '00:00:1'
Set @ItemsInStock = @ItemsInStock - 2

Update tblInventory 
Set ItemsInStock = @ItemsInStock where id_value=1

Print @ItemsInStock
Commit Transaction

Select * from tblInventory where id_value=1	


-- What about the update of the second transaction?

------------------------------------------------------------------------
-- 3) LOCKS 
------------------------------------------------------------------------
-- 3a) Create the view to see the locks information.

IF EXISTS
  (SELECT 1
   FROM sys.views
   WHERE name = 'DBlocks' )
DROP VIEW DBlocks ;


CREATE VIEW DBlocks AS
SELECT request_session_id AS spid,
       DB_NAME(resource_database_id) AS dbname,
       CASE
           WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id)
           WHEN resource_associated_entity_id = 0 THEN 'n/a'
           ELSE OBJECT_NAME(p.object_id)
       END AS entity_name,
       index_id,
       resource_type AS RESOURCE,
       resource_description AS description,
       request_mode AS MODE,
       request_status AS status
FROM sys.dm_tran_locks t
LEFT JOIN sys.partitions p ON p.partition_id = t.resource_associated_entity_id
WHERE resource_database_id = DB_ID()
  AND resource_type <> 'DATABASE' 




-- The following are different cases of isolation, analyze the blocked resources in each case.

------------------------------------------------------------------------
-- Example 1: SELECT with READ COMMITTED isolation level
------------------------------------------------------------------------
USE AdventureWorks2012 ;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED ;

BEGIN TRAN
SELECT *
FROM Production.Product
WHERE Name = 'Reflector' ;

SELECT *
FROM DBlocks
WHERE spid = @@spid ;

COMMIT TRAN

------------------------------------------------------------------------
-- Example 2: SELECT with REPEATABLE READ isolation level
------------------------------------------------------------------------
USE AdventureWorks2012 ;


SET TRANSACTION ISOLATION LEVEL REPEATABLE READ ;

BEGIN TRAN
SELECT *
FROM Production.Product
WHERE Name LIKE 'Racing Socks%' ;

SELECT *
FROM DBlocks
WHERE spid = @@spid
  AND entity_name = 'Product' 
ORDER BY index_id;

COMMIT TRAN


------------------------------------------------------------------------
-- Example 3: SELECT with SERIALIZABLE isolation level
------------------------------------------------------------------------
USE AdventureWorks2012 ;


SET TRANSACTION ISOLATION LEVEL SERIALIZABLE ;

BEGIN TRAN
SELECT *
FROM Production.Product
WHERE Name LIKE 'Racing Socks%' ;

SELECT *
FROM DBlocks
WHERE spid = @@spid
  AND entity_name = 'Product'
ORDER BY index_id;

COMMIT TRAN


------------------------------------------------------------------------
-- Example 4: Update with READ COMMITTED isolation level
------------------------------------------------------------------------
USE AdventureWorks2012 ;


SET TRANSACTION ISOLATION LEVEL READ COMMITTED ;

BEGIN TRAN
UPDATE Production.Product
SET ListPrice = ListPrice * 0.6
WHERE Name LIKE 'Racing Socks%' ;

SELECT *
FROM DBlocks
WHERE spid = @@spid
  AND entity_name = 'Product'
ORDER BY index_id;

COMMIT TRAN



------------------------------------------------------------------------
-- Extras
------------------------------------------------------------------------
-- fn_dblog https://logicalread.com/sql-server-dbcc-log-command-tl01/
-- https://rusanu.com/2014/03/10/how-to-read-and-interpret-the-sql-server-log/
-- NOTA: LSN = log sequence number

SELECT name, physical_name, size 'size in 8-KB pages', max_size
FROM sys.master_files
WHERE database_id = (SELECT DB_ID());


select [Current LSN],
       [Operation],
       [Transaction Name],
       [Transaction ID],
       [Transaction SID],
       [SPID],
       [Begin Time]
FROM   fn_dblog(null,null)
WHERE [SPID] = 52
ORDER BY [Current LSN]

select *
FROM   fn_dblog(null,null)



