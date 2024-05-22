-- Ejemplo 1

use Students

SELECT c.DepartmentCode, c.CourseNumber, c.CourseTitle, c.Credits, ce.Grade
FROM	CourseEnrollments			ce
		inner join	CourseOfferings co	ON co.CourseOfferingId	=	ce.CourseOfferingId
		inner join	Courses			c	ON	c.DepartmentCode	=	co.DepartmentCode	
										AND co.CourseNumber		=	c.CourseNumber
WHERE	ce.StudentId = 29717


SET STATISTICS IO ON
SET STATISTICS TIME ON


USE [Students]
GO
CREATE NONCLUSTERED INDEX IX_CouseEnrollements_StudentID
ON [dbo].[CourseEnrollments] ([StudentId])

GO

-- Ejemplo 2: Buscamos los cursos que no tienen ningun inscripto

SELECT	co.*
FROM	CourseOfferings		co
		LEFT JOIN CourseEnrollments ce ON co.CourseOfferingId=ce.CourseOfferingId
WHERE	co.TermCode = 'SP2016'	
		AND		ce.CourseOfferingId IS NULL

-- Index creation
USE [Students]
GO
CREATE NONCLUSTERED INDEX IX_CourseEnrollements_CourseOfferingId
ON [dbo].[CourseEnrollments] ([CourseOfferingId])

GO

DROP INDEX IX_CourseEnrollements_CourseOfferingId ON [dbo].[CourseEnrollments]

-- Alternative query
SELECT	co.*
FROM	CourseOfferings		co
WHERE	co.TermCode = 'SP2016'	
		AND	NOT EXISTS (SELECT	*
						FROM	CourseEnrollments ce 
						WHERE	ce.CourseOfferingId = co.CourseOfferingId
						)

SELECT	co.*
FROM	CourseOfferings		co
WHERE	NOT EXISTS (SELECT	1
						FROM	CourseEnrollments ce 
						WHERE	ce.CourseOfferingId = co.CourseOfferingId
						)
		AND co.TermCode = 'SP2016'	
		


-- Parte 2:

CREATE INDEX	 IX_Applicants_FirstNameLastName	
				ON	Applicants(FirstName, LastName, State);

SELECT	*
FROM	Applicants	A
WHERE	LastName='Davis'
		AND	State = 'CO';

--> SCAN es decir que el indice nos sirve de muy poco, ya que el indice esta ordenado
--		por FirstName

DROP	INDEX	IX_Applicants_FirstNameLastName		ON	Applicants	

CREATE INDEX	 IX_Applicants_FirstNameLastName	
				ON	Applicants(LastName, FirstName, State);

SELECT	*
FROM	Applicants	A
WHERE	LastName='Davis'
		AND	State = 'CO';

-- > Seek eso quiere decir que estamos usando la estructura del indice y no solo sus hojas

-- Selectividad de los �ndices:

-- Caso 1
DROP	INDEX	IX_Applicants_FirstNameLastName		ON	Applicants	

CREATE INDEX	 IX_Students_FirstNameLastName	
				ON	Students(LastName, FirstName);

SELECT	*
FROM	Students	S
WHERE	LastName='Baker'
		AND	FirstName = 'Charles';

		-- Caso 2
DROP	INDEX	IX_Students_FirstNameLastName		ON	Students	

CREATE INDEX	 IX_Students_State
				ON	Students(State);

SELECT	*
FROM	Students	S
WHERE	State='WI'
		AND	City = 'Appleton';

		-- > En este caso, el nro de coincidencias por hoja del indice es tan alta
		--	que conviene escalear los bloques que acceder individualmente a buscar cada entrada
		--	que cumple la condici�n

		--	Es posible forzar a SQL a usar el �ndice, si nos creemos que sabemos m�s que el optimizador
		--	y que nuestro indice es super util:

			SELECT	*
			FROM	Students S	WITH (Index (IX_Students_State))
			WHERE	State	=	'WI'
					AND	City = 'Appleton';
		 
		 -- La soluci�n es crear un �ndice con mejor selectividad. Tal vez ni State ni City sean muy selectivas
		 --	de por si, pero en conjunto si lo son.

CREATE INDEX	 IX_Students_StateCity
				ON	Students(State,City);

SELECT	*
FROM	Students	S
WHERE	State='WI'
		AND	City = 'Appleton';


-- Consultas con Funciones

CREATE INDEX	IX_APPLICANTS_EMAIL
				ON	Applicants(Email);

SELECT	*
FROM	Applicants A
WHERE	SUBSTRING(Email, 0, CHARINDEX('@',email,0)) = 'LouiseJSmith';

--> Lo que vemos en este caso es que el �ndice no puede usarse ya que la condici�n se debe
-- calcular entrada a entrada. Entonces solo podemos hacer el scan

-- Y... c�mo salvamos esto? Lo que hay que hacer es darle algo al DBMS sobre lo cual crear una columna
-- indexable util para la consulta. Esta columna va a ser una columna calculada

ALTER TABLE Applicants ADD EmailLocalPart AS SUBSTRING(Email, 0, CHARINDEX('@',email,0));

CREATE INDEX	IX_APPLICANTS_EMAILLOCAL
				ON	Applicants(EmailLocalPart);

SELECT	*
FROM	Applicants A
WHERE	SUBSTRING(Email, 0, CHARINDEX('@',email,0)) = 'LouiseJSmith';

--> y ahora tenemos un index seek, es decir, que nuestro proceso fue correcto

-- Include Columns and Covering index

-- A veces es conveniente construir un �ndice sobre un atributo pero incluir otras columnas en las hojas
-- El objetivo? Realizar la busqueda sobre el atributo indexado, pero no acceder a memoria para buscar los otros
--	Se denomina Covering index si SQL puede encontrar toda la info que necesita en el �ndice. Sin necesitar acceder a la tabla
-- i.e, nos ahorramos realizar el posterior Key-Lookup Table
DROP	INDEX	IX_STUDENTS_EMAIL		ON	Students	

CREATE INDEX	IX_STUDENTS_EMAIL
				ON	students(Email)
				INCLUDE (FirstName,LastName);

SELECT	FirstName,LastName,Email
FROM	Students	S
WHERE	email='PaulDWilliams@gustr.com'

-- pero...

SELECT	FirstName,LastName,Email, City
FROM	Students	S
WHERE	email='PaulDWilliams@gustr.com'
-- ya no es suficiente la info en las hojas del arbol, as� que tengo que acceder a la tabla en memoria

-- Notar que si hacemos un Update o modificamos las entradas en la tabla, necesariamente tendremos que
-- actualizar el �ndice, de otro modo, la informaci�n que devolvemos ser� erronea.

-- Siempre Conviene Indexar?
-- La clave es que los indices necesitan: espacio en memoria para existir y procesamiento para su mantenimiento.
-- Si tenemos muchos indices, el costo de mantenimiento de la DB crece.

-- Dynamic Management Views: Son vistas que nos dan informaci�n sobre la performance de la base de datos.
--							Es una buena pr�ctica eliminar aquellos indices que sean muy poco utilizados

--							La idea seria generar una vista que permita evaluar la cantidad de veces que es consultado
--							Un indice en comparaci�n con el nro de veces que es actualizado.

SELECT
	OBJECT_NAME(s.object_id) AS TableName,
		i.name AS IndexName,
		i.type_desc AS IndexType,
		user_seeks + user_scans + user_lookups AS TotalUsage,
		user_seeks,
		user_scans,
		user_lookups,
		user_updates
	FROM	sys.dm_db_index_usage_stats s
	RIGHT OUTER JOIN sys.indexes i	ON s.[object_id] = i.[object_id]
									AND	s.index_id = i.index_id
	WHERE	s.database_id = DB_ID()
			AND	i.name IS NOT NULL
			AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped')=0
	ORDER BY s.object_id, s.index_id

/*					
Query1: utiliza dm_exec_sessions para informanos:
	*sobre los clientes que están conectados a nuestra DB
	*el estado: activos, inactivos, etc
	*Nos permite saber si alguna de las sesiones está consumiendo demasiados recursos
*/

-- Finding Connection to Your Database
-- ------------------------------------------------------------------------------------------------
SELECT
    database_id,    -- SQL Server 2012 and after only
    session_id,
    status,
    login_time,
    cpu_time,
    memory_usage,
    reads,
    writes,
    logical_reads,
    host_name,
    program_name,
    host_process_id,
    client_interface_name,
    login_name as database_login_name,
    last_request_start_time
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
ORDER BY cpu_time DESC;


-- Count of Connections by Login Name/Process (i.e. how many connections does an app have open)
-- ------------------------------------------------------------------------------------------------
SELECT
    login_name,
    host_name,
    host_process_id,
    COUNT(1) As LoginCount
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
GROUP BY
    login_name,
    host_name,
    host_process_id;

/*
Query2: Averiguar qué operaciones se están ejecutando en un momento dado. Esto nos permite identificar qué sentencia puede estar haciendo al sistema lento en un momento dado.
Esta consulta hace:
	*TRae las sesiones y las request de cada una
	*Luego, nos trae el plan de ejecuciòn para esta request
	*Y nos indica si está siendo blockeada por otra sentencia en ejecución
Y nos muestra:
	*información sobre el estado de la sentencia
	*Si pertenece a un stored procedure
	*informaciòn sobre el cliente de la consulta
	*información sobre el tiempo y actividad en la sentencia
	*información sobre la sentencia que la está blockeando si existiera
*/

-- Finding statements running in the database right now (including if a statement is blocked by another)
-- -----------------------------------------------------------------------------------------------
SELECT
        [DatabaseName] = db_name(rq.database_id),
        s.session_id, 
        rq.status,
        [SqlStatement] = SUBSTRING (qt.text,rq.statement_start_offset/2,
            (CASE WHEN rq.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX),
            qt.text)) * 2 ELSE rq.statement_end_offset END - rq.statement_start_offset)/2),        
        [ClientHost] = s.host_name,
        [ClientProgram] = s.program_name, 
        [ClientProcessId] = s.host_process_id, 
        [SqlLoginUser] = s.login_name,
        [DurationInSeconds] = datediff(s,rq.start_time,getdate()),
        rq.start_time,
        rq.cpu_time,
        rq.logical_reads,
        rq.writes,
        [ParentStatement] = qt.text,
        p.query_plan,
        rq.wait_type,
        [BlockingSessionId] = bs.session_id,
        [BlockingHostname] = bs.host_name,
        [BlockingProgram] = bs.program_name,
        [BlockingClientProcessId] = bs.host_process_id,
        [BlockingSql] = SUBSTRING (bt.text, brq.statement_start_offset/2,
            (CASE WHEN brq.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX),
            bt.text)) * 2 ELSE brq.statement_end_offset END - brq.statement_start_offset)/2)
    FROM sys.dm_exec_sessions s
    INNER JOIN sys.dm_exec_requests rq
        ON s.session_id = rq.session_id
    CROSS APPLY sys.dm_exec_sql_text(rq.sql_handle) as qt
    OUTER APPLY sys.dm_exec_query_plan(rq.plan_handle) p
    LEFT OUTER JOIN sys.dm_exec_sessions bs
        ON rq.blocking_session_id = bs.session_id
    LEFT OUTER JOIN sys.dm_exec_requests brq
        ON rq.blocking_session_id = brq.session_id
    OUTER APPLY sys.dm_exec_sql_text(brq.sql_handle) as bt
    WHERE s.is_user_process =1
        AND s.session_id <> @@spid
 AND rq.database_id = DB_ID()  -- Comment out to look at all databases
    ORDER BY rq.start_time ASC;


/*
Query 3: encontrar sentencias eficientes y sentencias poco eficientes
		traemos las estadísticas de las queries y las juntamos con sus textos y planes de ejecución asociados
Traemos la info sobre:
	*la sentencia específica
	*sus estadísticas de consumo de recursos
	*Ordenamos la información según estemos buscando sentencias eficientes o que generen bottlenecks
*/

-- Finding the most expensive statements in your database
-- ------------------------------------------------------------------------------------------------
SELECT TOP 20    
        DatabaseName = DB_NAME(CONVERT(int, epa.value)), 
        [Execution count] = qs.execution_count,
        [CpuPerExecution] = total_worker_time / qs.execution_count ,
        [TotalCPU] = total_worker_time,
        [IOPerExecution] = (total_logical_reads + total_logical_writes) / qs.execution_count ,
        [TotalIO] = (total_logical_reads + total_logical_writes) ,
        [AverageElapsedTime] = total_elapsed_time / qs.execution_count,
        [AverageTimeBlocked] = (total_elapsed_time - total_worker_time) / qs.execution_count,
     [AverageRowsReturned] = total_rows / qs.execution_count,    
     [Query Text] = SUBSTRING(qt.text,qs.statement_start_offset/2 +1, 
            (CASE WHEN qs.statement_end_offset = -1 
                THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2 
                ELSE qs.statement_end_offset end - qs.statement_start_offset)
            /2),
        [Parent Query] = qt.text,
        [Execution Plan] = p.query_plan,
     [Creation Time] = qs.creation_time,
     [Last Execution Time] = qs.last_execution_time   
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
    OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) p
    OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa
    WHERE epa.attribute = 'dbid'
        AND epa.value = db_id()
    ORDER BY [AverageElapsedTime] DESC; --Other column aliases can be used-- Finding the most expensive statements in your database
-- ------------------------------------------------------------------------------------------------
SELECT TOP 20    
        DatabaseName = DB_NAME(CONVERT(int, epa.value)), 
        [Execution count] = qs.execution_count,
        [CpuPerExecution] = total_worker_time / qs.execution_count ,
        [TotalCPU] = total_worker_time,
        [IOPerExecution] = (total_logical_reads + total_logical_writes) / qs.execution_count ,
        [TotalIO] = (total_logical_reads + total_logical_writes) ,
        [AverageElapsedTime] = total_elapsed_time / qs.execution_count,
        [AverageTimeBlocked] = (total_elapsed_time - total_worker_time) / qs.execution_count,
     [AverageRowsReturned] = total_rows / qs.execution_count,    
     [Query Text] = SUBSTRING(qt.text,qs.statement_start_offset/2 +1, 
            (CASE WHEN qs.statement_end_offset = -1 
                THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2 
                ELSE qs.statement_end_offset end - qs.statement_start_offset)
            /2),
        [Parent Query] = qt.text,
        [Execution Plan] = p.query_plan,
     [Creation Time] = qs.creation_time,
     [Last Execution Time] = qs.last_execution_time   
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
    OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) p
    OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa
    WHERE epa.attribute = 'dbid'
        AND epa.value = db_id()
    ORDER BY [AverageElapsedTime] DESC; --Other column aliases can be used



/*
Query 5: 
Obteniendo sugerencias de índices de las estadísticas de SQL.
Vimos que al ejecutar consultas, si SQL server consideraba que existían índices que podrían optimizar la consulta, nos lo sugería. 
Esto no solo ocurre al realizar una única consulta, sino que podemos obtener sugerencias de SQL desde sus estadísiticas.
Literalmente, del funcionamiento de la DB nos genera un listado de “index faltantes”

Esta vista nos marca:
	*Atributos que vamos a evaluar por igualdad y por rango
	*columnas a incluir en las hojas
	*las veces que podríamos haberlo usado para generar index seek and index scans
	*El estimado % de optimización que se percibe al generar el índice

Pero recuerden que no es optimo generar todos lo índices, ya que es tendencia de SQL buscar un índice para optimizar toda Query ejecutada.
Y si creamos todos estos índices sin pararnos a analizarlos, seguramente llegaríamos a un estado de sobre-indexación de la DB.
*/

-- Looking for Missing Indexes
-- ------------------------------------------------------------------------------------------------
SELECT     
    TableName = d.statement,
    d.equality_columns, 
    d.inequality_columns,
    d.included_columns, 
    s.user_scans,
    s.user_seeks,
    s.avg_total_user_cost,
    s.avg_user_impact,
    AverageCostSavings = ROUND(s.avg_total_user_cost * (s.avg_user_impact/100.0), 3),
    TotalCostSavings = ROUND(s.avg_total_user_cost * (s.avg_user_impact/100.0) * (s.user_seeks + s.user_scans),3)
FROM sys.dm_db_missing_index_groups g
INNER JOIN sys.dm_db_missing_index_group_stats s
    ON s.group_handle = g.index_group_handle
INNER JOIN sys.dm_db_missing_index_details d
    ON d.index_handle = g.index_handle
WHERE d.database_id = db_id()
ORDER BY TableName, TotalCostSavings DESC;


/*
Query 6: 
Identificar índices que no se usan
Vease, índices que se actualizan mucho más de las veces que se utilizan. 
En general esto puede ocurrir porque las columnas/atributos escogidos no son de utilidad para sentencias o porque no son suficientemente selectivos como para usarlos en lugar de un scan.
*/

-- Getting Stats on What Indexes are Used and What Indexes are Not
-- ------------------------------------------------------------------------------------------------
SELECT
    [DatabaseName] = DB_Name(db_id()),
    [TableName] = OBJECT_NAME(i.object_id),
    [IndexName] = i.name, 
    [IndexType] = i.type_desc,
    [TotalUsage] = IsNull(user_seeks, 0) + IsNull(user_scans, 0) + IsNull(user_lookups, 0),
    [UserSeeks] = IsNull(user_seeks, 0),
    [UserScans] = IsNull(user_scans, 0), 
    [UserLookups] = IsNull(user_lookups, 0),
    [UserUpdates] = IsNull(user_updates, 0)
FROM sys.indexes i 
INNER JOIN sys.objects o
    ON i.object_id = o.object_id
LEFT OUTER JOIN sys.dm_db_index_usage_stats s
    ON s.object_id = i.object_id
    AND s.index_id = i.index_id
WHERE 
    (OBJECTPROPERTY(i.object_id, 'IsMsShipped') = 0)
ORDER BY [TableName], [IndexName];



/*
Parte 4: Buenas prácticas

Parameterized SQL: cuando mandamos sentencias a ejecutar en SQL desde una app en C#, C++, python, Java, etc, lo mejor es generarlo en forma parametrizada declarando las variables como inputs (usando @). De esta forma SQL puede optimizarla y guardar un plan de ejecución para la misma, si se vuelve a ejecutar. 
Tener en cuenta que es muy similar a la sintaxis de generar la query en forma de string pero tiene beneficios a nivel de performance.

En entornos multi usuario, esto puede llegar a representar que consultas que llegan desde app se ejecuten hasta 10 veces más rápido.

Parameterized SQL vs Stored procedures: Básicamente, la performance es la misma. PERO hay ventajas en el uso de Stored procedures, tales como:
	*Mayor seguridad en el manejo de los datos
	*Control de actualizaciones en la DB

Commit impact on performance: En general, las sentencias vienen con auto-commit por defecto. Pero esto trae ciertos problemas:
	*Demasiados write en log
	*Imposibilidad de correr scripts en forma eficaz. Ya que de haberse ocurrido una carga incompleta previamente, la misma generará errores debido al intento de duplicar data existente.

*/
