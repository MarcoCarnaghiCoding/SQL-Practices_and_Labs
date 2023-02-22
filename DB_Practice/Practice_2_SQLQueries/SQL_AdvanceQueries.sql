--
--					Complex Queries
--

-- Using the following schema

-- Employee(idEmployee,name,street,city)
-- Works(idEmployee,idCompany,salary)
-- Company(idCompany,name,city)
-- Boss(idEmployee,idBoss)

-- a) 	Find the names of all the employees working for "Bank B".

SELECT E.name
FROM Company EM, Works T, Employee E
WHERE EM.name = 'BANK B'
	AND T.idCompany = EM.idCompany
	AND t.IDEmployee = E.IDEmployee

-- b) 	List the names of the employees working for "Bank B" 
--		who earn more than $100,000.

SELECT *
FROM Company EM, Works T, Employee E
WHERE EM.name = 'BANK B'
	AND T.idCompany = EM.idCompany
	AND t.IDEmployee = E.IDEmployee
	AND T.salary > 100000

--b) alternative
SELECT *
FROM Employee E
WHERE E.IDEmployee IN (SELECT T.IDEmployee
						FROM Company EM, Works T
						WHERE T.IDCompany = EM.IDCompany
							AND EM.name = 'BANK B'
							AND T.salary > 100000)

-- c) 	List the names of all employees who live in the same city
-- 		as the company they work for.

SELECT E.name
FROM Company EM, Works T, Employee E
WHERE EM.city = E.city
	AND T.IDEmployee = E.IDEmployee
	AND T.IDCompany = EM.IDCompany

-- d) List the names of all the employees who live on the same street
-- and in the same city as their bosses.

SELECT E1.name
FROM Employee E1, Employee E2, Boss J
WHERE E1.city = E2.city
	AND E1.street = E2.street
	AND J.IDEmployee = E1.IDEmployee
	AND J.IDBoss = E2.IDEMEPLEADO


-- e) List the names of the employees who do not work for "Bank B".

SELECT *
FROM Company EM, Works T, Employee E
WHERE EM.name <> 'BANK B'
	AND T.idCompany = EM.idCompany
	AND t.IDEmployee = E.IDEmployee

--En caso que se admita tener 2 o m�s empleos y uno pueda ser BANK B

SELECT * 
FROM Employee E
WHERE IDEmployee NOT IN (SELECT T.IDEmployee
						FROM Company EM, Works T
						WHERE EM.name = 'BANK B'
							AND T.IDCompany = EM.IDCompany)

-- f) List the ids of employees who earn more than any employee of "Bank G".

SELECT E.name
FROM Employee E, Works T
WHERE E.IDEmployee = T.IDEmployee
	AND T.salary > ALL (SELECT	T2.salary
						FROM	Works T2, Company EM
						WHERE	EM.name = 'BANK G'
								AND EM.IDCompany = T.IDCompany)

-- Considering that some employees may have more than one job

WITH salary_TOTAL_Employee AS (	SELECT	IDEmployee, SUM(salary) AS salary_TOTAL
								FROM	Works
								GROUP BY IDEmployee)

SELECT	E.name
FROM	Employee E, salary_TOTAL_Employee STE
WHERE	E.IDEmployee = STE.IDEmployee
		AND STE.salary-TOTAL > ALL (	SELECT	STE.salary-TOTAL
										FROM	salary_TOTAL_Employee STE, Works T, Company EM
										WHERE	EM.name = 'BANK G'
												AND EM.IDCompany = T.IDCompany
												AND STE.IDEmployee = T.IDEmployee)


-- g) 	Find the names of all the companies that are located
-- 		in the same cities where there are branches of "Bank G".

SELECT * 
FROM Company EM
WHERE EM.city IN (	SELECT	EM2.city
						FROM	Company EM2
						WHERE	EM2.name = 'BANK G')

-- Using empty condition

SELECT *
FROM Company EM
WHERE	NOT EXISTS	(		(	-- Cities with BANK G branches
								SELECT	EM2.city 
								FROM	Company EM2
								WHERE	EM.name = 'BANK G'
							)

						EXCEPT
							(	--Cities with branches from the company of the outer table
								SELECT	EM3.city  
								FROM	Company EM3
								WHERE	EM3.name = EM.name
							)
					)

--	we seek to cancel the cityes sets of one company with another,
-- so that NOT EXISTS = TRUE.


-- 9)

-- a)	List all employees who earn more than the average salary 
--		OF your company's employees.

SELECT	*
FROM	Employee E, Works T
WHERE	E.IDEmployee = T.IDEmployee
		AND T.salary > (	SELECT	AVG(salary)
							FROM	Works T2
							WHERE	T2.IDCompany = T.IDCompany)

-- b)	List the company or companies with the highest number of employees.

SELECT EM.name
FROM Company EM, Works T
WHERE T.IDCompany = EM.IDCompany
GROUP BY EM.IDCompany
HAVING COUNT(T.IDMEPLEADO) >= ALL	(	SELECT	COUNT(T2.IDEmployee)
										FROM	Works T2
										GROUP BY	T2.IDCompany)

-- c)	 List the company or companies with the lowest average salary.

SELECT	EM.name, AVG(T.salary)
FROM	Company EM, Works T
WHERE	EM.IDCompany = T.IDCompany
GROUP BY	T.IDCompany
HAVING		AVG(T.salary) <= ALL	(	SELECT	AVG(T2.salary)
										FROM	Works T2
										GROUP BY	T2.IDCompany)


-- d)	List the company or companies whose employees earn on average
-- 		more than the average salary of the employees of "Bank B".

SELECT	EM.name
FROM	Company EM, Works T
WHERE	EM.IDCompany = T.IDCompany
GROUP BY	T.IDCompany
HAVING		AVG(T.salary)	>	(	SELECT	AVG(T2.salary)	
									FROM	WorksR T2, Company EM2
									WHERE	EM2.name = 'BANK B'
											AND EM2.IDCompany = T2.IDCompany
									GROUP BY	T2.IDCompany)

-- e)	Increase all salaries of "Bank B" by 10%.

UPDATE	T
SET		T.salary = T.salary * 1.1
FROM	Company EM, Works T
WHERE	EM.name = 'BANK B'
		AND T.IDCompany = EM.IDEMEPRESA

-- f)	Increase by 10% the salaries of the bosses of "Bank B".

UPDATE	T
SET		T.salary = T.salary * 1.1
FROM	Boss J, Works T, Company EM
WHERE	T.IDCompany = EM.IDCompany
		AND EM.name = 'BANK B'
		AND T.IDEmployee IN	(	SELECT	IDBoss
								FROM	BossS)

-- g)	 Eliminate all the tuples of the relation Works corresponding
-- 		to the employees of "Bank G".

DELETE FROM		Works
FROM			Works T, Company EM
WHERE			T.IDCompany = EM.IDCompany
				AND EM.name = 'BANK G'

-- h)	Define a view that contains id-boss and the average salary of
--  	all employees that work for that boss.

CREATE VIEW salaryEmployeeS AS
SELECT J.IDBossS, AVG(T.salary)
FROM Boss J, Works T
WHERE T.IDEmployee = J.IDEmployee
GROUP BY J.IDBoss


-- 12)

/*
Considere el siguiente esquema de base de datos y resuelva las consultas en SQL:


	Client (Client, direction, balance)
	orders (n_orders, Client, ítem, quantity)
	supplier (supplier, ítem, price)
*/


--a) List all customers indicating the total quantities ordered by them.

SELECT		C.name, SUM(quantityES)
FROM		Client C, orders OP
WHERE		C.name = OP.Client -- O Client INNER JOIN orders ON C.Client = OP.Client
GROUP BY	OP.Client

-- b) List the suppliers for whose items you have orders for more than 2,000 units in total.

SELECT		P.supplier, P.ITEM, SUM(quantity)
FROM		supplier P, orders OP
WHERE		P.ITEM = OP.ITEM
GROUP BY	P.supplier, P.ITEM
HAVING		SUM(OP.quantity) > 2000

-- c) List the customers who ordered more than 15 lamps.

SELECT		C.name, SUM(quantity)
FROM		Client INNER JOIN orders OP ON C.Client = OP.Client
WHERE		OP.ITEM = 'LAMPARA'
GROUP BY	OP.Client
HAVING		SUM(quantity) > 15

-- d)	 List customers whose total number of units ordered is above
-- 		the overall average number of units ordered for all customers.

SELECT C.name, SUM(quantity)
FROM Client C INNER JOIN orders OP ON C.Client = OP.Client
GROUP BY C.name
HAVING SUM(quantity)	>	(	SELECT	AVG(quantity)
								FROM	orders OP2
								GROUP BY	OP2.Client	
								)

-- e) 	Update by 15% the number of items ordered in the orders
--  	of those customers whose balance is greater than 10,000.

UPDATE OP
SET OP.quantity = OP.quantity *1.15
FROM orders OP INNER JOIN Client C ON C.Client=OP.Client
WHERE C.balance > 10000

-- 13)
/*
Given the following prescription database,

		Elaborate (laboratory, drug)
		Produce (laboratory, pharma)
		Sells (pharmacy, pharma, price)
		Compound-for (pharma, drug)
		Prescription (Prescription-id, date, doctor, patient)
		Prescription-pharma (Prescription-id, pharma)

*/


--C
-- 	List the pharmacies that sell all drugs that were prescribed 
-- 	more than 5 times after January 01

SELECT	RF.pharma
FROM	Prescription_pharma RF INNER JOIN Prescription R ON RF.pharma = R.pharma
WHERE	R.date > '2020-01-01'
GROUP BY pharma
HAVING		COUNT(RF.PrescriptionID) > 5

--pharmacyS
-- 		VERIFY THAT THE DRUG IS FROM THE GROUP AND THEN THAT THE
-- 		NUMBER OF TOTAL PRESCRIPTIONS EQUALS THE TOTAL pharma IN THAT GROUP.
SELECT		V.pharmacy
FROM		Sells V
WHERE		V.pharma	IN (	SELECT	RF.pharma
								FROM	Prescription_pharma RF INNER JOIN Prescription R ON RF.pharma = R.pharma
								WHERE	R.date > '2020-01-01'
								GROUP BY pharma
								HAVING		COUNT(RF.PrescriptionID) > 5
							)
GROUP BY	V.pharmacy
HAVING		COUNT(V.pharma) = (SELECT	COUNT(RF.PrescriptionID)
								FROM	Prescription_pharma RF INNER JOIN Prescription R ON RF.pharma = R.pharma
								WHERE	R.date > '2020-01-01'
								GROUP BY pharma
								HAVING		COUNT(RF.PrescriptionID) > 5) 


--d)
-- List the drugs whose average prices are higher than those
-- of all drugs prescribed by the most prescribing doctors. 

-- D1) Most prescribing doctors

/*
SELECT R2.doctor
FROM Prescription R2
GROUP BY R2.doctor
HAVING	COUNT(*) = (SELECT		MAX( COUNT(*))
					FROM		Prescription R
					GROUP BY	R.doctor)

*/

-- D2) Average prices of prescribed Pharmas
/*
SELECT	AVG ( V.price ) 
FROM	Sells V, Prescription-pharma RF, Prescription R  --V.pharma --= RF.pharma
WHERE	V.pharma = RF.pharma
		AND RF.PrescriptionID = R.PrescriptionID
		AND R.doctor IN ( -- doctorS DE D1)
GROUP BY V.pharma
*/
-- D3)pharmas with higher price than the average from D2
/*
SELECT		V2.pharma
FROM		Sells V2
GROUP BY	V2.pharma
HAVING		AVG(price) > ALL (--priceS DE D2)
*/
-- End Result

SELECT		V2.pharma
FROM		Sells V2
GROUP BY	V2.pharma
HAVING		AVG(price) > ALL (	SELECT	AVG ( V.price ) 
								FROM	Sells V, Prescription_pharma RF, Prescription R 
								WHERE	V.pharma = RF.pharma
										AND RF.PrescriptionID = R.PrescriptionID
										AND R.doctor IN (	SELECT		R2.doctor
															FROM		Prescription R2
															GROUP BY	R2.doctor
															HAVING		COUNT(*) = (SELECT		MAX( COUNT(*))
																					FROM		Prescription R3
																					GROUP BY	R3.doctor)
														)
								GROUP BY V.pharma
								
							)