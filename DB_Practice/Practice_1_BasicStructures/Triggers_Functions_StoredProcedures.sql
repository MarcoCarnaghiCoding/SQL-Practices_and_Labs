/*

Procedural

Objective: to concentrate in well-defined blocks within the DBMS sequences of actions


To include Stored Procedurals, the language included several capabilities.
 For example:

 -Conditionals: if/then/else.
 -Loops: While/for
 -Variables
 -Functions or Procedures

*/

/*
-------------------------------------------
				STORED PROCEDURES
-------------------------------------------
Elements to be defined:
 	-Name of the STORED PROCEDURES
 	-Definition of input and output parameters
  	*input: defined for the execution of the Process
 		*output: important for the transfer of results
 		*both: to modify the value of a variable by the process -- *both: to modify the value of a variable by the process
 	-Definition of local variables
 	-Actions to be performed
*/

-- Alias declaration
Delimiter $$
CREATE PROCEDURE <NOMBRE_PROCEDURE>
	-- Input parameters
	@input1		tipo_de_dato1
	@input2		tipo_de_dato2
	@input3		tipo_de_dato3

AS
/* Variables declaration*/
DECLARE 
	@var1		tipo_de_dato_var1
	@var2		tipo_de_dato_var2
BEGIN
	/* Actions*/
	 <ACCIÓN1>
	 <ACCIÓN2>
	 <ACCIÓN3>
	/* Commit TRANSACTION*/ 
	COMMIT TRANS
END
DELIMITER ;

-- CALL A STORED PROCEDURE (SQL server)

-- Indicating the input parameters in order
EXEC <NOMBRE_PROCEDURE> valor_input1, valor_input2, valor_input3;

-- Explicitly indicating the input parameters by name
EXEC <NOMBRE_PROCEDURE> 
	@input1	=	value_input1
	@input2	=	value_input2
	@input3	=	value_input3


----------------------------------------------------
-- 			Example: 
----------------------------------------------------
-- Enter a new Customer with:
-- customer number= 2000
-- company: 'MercadoLibre
-- credit limit: 50000$ -- credit limit: 50000$ -- credit limit: 50000$ -- credit limit: 50000$ -- credit limit: 50000$
-- In charge of Ramon Avila (Employee #99) from the Buenos Aires office.
-- To do this you need to enter:
-- 1)Save the customer's data.
-- 2)Modify the limits of the sales representative.
-- 3)Modify the limits of the office.


--Without Stored PROCEDURE

INSERT INTO COSTUMERS (CUST_NUM, COMPANY, CUST_REP, CREDIT_LIMIT)
	VALUES (2000, 'MercadoLibre', 99, 50000.00)
	
UPDATE SALESREPS
	SET QUOTA = QUOTA + (50000.00 * 1.5)
	WHERE EMPL_NUM = 99;

UPDATE OFFICES
	SET TARGET = TARGET + (50000.00 * 1.5)
	WHERE CITY = 'Buenos Aires';

COMMIT;


-- Using Stored PROCEDURE

CREATE PROCEDURE ADD_CUSTOMER
	@C_NUM				INTEGER
	@CORP_NAME			VARCHAR(20)
	@CRED_LIMIT			DECIMAL(9,2)
--	@TARGET_CHANGE		DECIMAL(9,2)
	@C_SALESREP			INTEGER
	@C_OFFICE			VARCHAR(15)
AS

DECLARE
	@TARGET_CHANGE DECIMAL(9,2)
	
BEGIN	
	INSERT INTO COSTUMERS (CUST_NUM, COMPANY, CUST_REP, CREDIT_LIMIT)
		VALUES (@C_NUM, @CORP_NAME, @C_SALESREP, @CRED_LIMIT)
	
	SELECT @TARGET_CHANGE = 1.5 * @CRED_LIMIT
	
	UPDATE SALESREPS
		SET QUOTA = QUOTA + @TARGET_CHANGE
		WHERE EMPL_NUM = @C_SALESREP;

	UPDATE OFFICES
		SET TARGET = TARGET + @TARGET_CHANGE
		WHERE CITY = @C_OFFICE;

	COMMIT TRANS
END


--------------------------------------------------------------
-- 						ASSERTIONS
--------------------------------------------------------------

CREATE ASSERTION <Name_Assertion>
CHECK (<Condition>);

/*
CONCEPT
------------
--They are used to define general constraints.
-- But this could also be achieved with CHECK, what would be the difference?
	-- - CHECK should be used when the designer is sure that the restrictions 
		-- regarding tuples, domain and attributes can only be violated during an INSERT or UPDATE operation. 
		-- INSERT or UPDATE operation.

-- Assertion checks are performed when there are attempts to make changes to a given 
-- relationship(or table) are made.

-- NOTE: A basic way to define an ASSERTION is to define a condition that filters out
-- those tuples that violate the database constraint. If the set is empty
-- obtained, then the modification can be performed.
*/

/*
DEFERRABLE
------------------

-- Deferred: Deferring the verification of a condition refers to postponing it until the end of a transaction, rather than at the end of a transaction, rather than at the end of a transaction.
-- transaction, instead of at the end of each action (or statement).
-- In this way, if the constraint is not violated, the COMMIT of the transaction is done.
-- But if it is violated, a rolled back is done (the changes are rolled back and reversed).

-- Deferring the checks is necessary when several tables must be updated in the event of a change
-- to maintain the consistency of the database. If the state of the database were to be checked after
-- each update, the constraint would always be violated by intermediate states.

-- Thus an ASSERTION can be: DEFERRABLE or NOT DEFERRABLE.

-- The time of its verification can also change during an execution and its initial condition can be defined.
-- For this we use: INITIALLY IMMEDIATE / DEFERRED --> INITIAL
-- And, in case of being DEFERRABLE, we can change its execution with:
*/

SET CONSTRAINTS <NAME_ASSERTION> DEFERRED / IMMEDIATE

--------------------------------------------------------------
-- 						TRIGGERS
--------------------------------------------------------------


-- BUSINESS RULES
-- There are restrictions required by the customer that are specific to the organization. 
-- From its organizational rules or procedures.
-- The ways to implement these restrictions would be:
	-- - - In the applications that access the database: But this has several associated problems:
		-- *Increased effort: Each application that accesses the database must guarantee compliance
		-- of the constraints or rules.
		-- Lack of consistency: Different programmers will develop different programs that will apply table updates in different ways.
		-- updates to the tables in different ways.
		-- Difficulty of maintenance: When a change is made, it must be applied in all the application codes.
		-- Complexity: Given the large number of constraints required by a DB, a simple application can quickly become very complex. 
		-- Quickly become very complex.

	-- -Make the DB responsible for its own integrity --> TRIGGERS



-- CONCEPT
----------------------

-- A trigger is a special set of STORED PROCEDURES that are activated by a modification 
-- of the DB content.
-- That is, it is not triggered by a CALL or EXEC, but by INSERT, DELETE or UPDATE attempts.

CREATE TRIGGER <NAME_TRIGGER>	-- TRIGGER NAME
ON <TABLE_TARGET>				-- TARGET TABLE
FOR <INSERT_DELETE_UPDATE> 		-- TRIGGER ACTIONS 

AS 								--ACTIONS of the TRIGGER
	/*BODY*/
	(...);


-- SPECIAL TABLES
------------------

-- For the correct operation of the trigger, two tables are defined whose
-- column configuration is identical to that of the TARGET TABLE.

-- * DELETED
-- * INSERTED

-- The content of the tables changes according to the action that triggers the trigger:

-- DELETE: 
-- 		DELETED/ OLD contains the rows to be deleted.
-- 		INSERTED/NEW remains empty.
-- INSERT: 
-- 		INSERTED/NEW contains the rows to be inserted.
-- 		DELETE/OLD remains empty.
-- UPDATE: 
-- 		DELETED/OLD contains the rows to be deleted (the rows before the modification).
-- 		INSERTED/NEW contains the rows to be inserted (the rows after the modification).

-- ADVANTAGES AND DISADVANTAGES	
-- 		+ Works as a change/update auditor.
-- 		+ Cascading updates
-- 		+ Allows to encapsulate in a single code rules referring to the DB.

-- This way, the uniformity of the applications that access the DB is improved. 
-- It concentrates the modifications that need to be made in a single block.

-- 		- It increases the complexity of the DB set-up.
-- 		- It can increase the processing load and, therefore, the performance.
-- 		- Processing is no longer transparent (hidden functions).


--Example: 
----------------------
-- When a sale is made, the following must be done:
-- 1) The sales representative's sales must be increased by the agreed amount.
-- 2) The quantity in stock of the product must be decreased.

CREATE TRIGGER NEWORDER
ON ORDERS
FOR INSERT
AS
	UPDATE 		SALESREPS							-- Affected tables can differ from the Target Table
		SET		SALES = SALES + INSERTED.AMOUNT		-- INSERTED contains the new values
		FROM 	SALESREPS	, INSERTED
		WHERE 	SALESREPS.EMPL_NUM = INSERTED.REP 
		
	UPDATE 		PRODUCTS
		SET 	QTY_ON_HAND = QTY_ON_HAND	- INSERTED.QTY 
		FROM 	PRODUCTS, INSERTED
		WHERE 	PRODUCTS.MFR_ID = INSERTED.MFR
				AND
				PRODUCTS.PRODUCT_ID = INSERTED.PRODUCT
	