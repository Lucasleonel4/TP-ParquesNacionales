/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emmanuel Américo
*  - Ruiz Carletti, Emiliano
* Fecha: 23/06/2026
* Script: 110. Importacion de datos
* Descripción: Procedimientos de importacion/upsert desde archivos externos usando tablas temporales.
*/

USE com2900;
GO

-- Importacion de Provincias desde JSON.
CREATE OR ALTER PROCEDURE [parque].[ProvinciaImportarActualizar]
	@sourceData NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		CREATE TABLE #TempProvincia (
			ID      VARCHAR(MAX) NULL,
			Nombre  VARCHAR(MAX) NULL
		);

		-- SQL dinamico necesario: OPENROWSET BULK requiere la ruta del archivo dentro de la sentencia.
		DECLARE @SQLDin NVARCHAR(MAX) = N'
			INSERT INTO #TempProvincia (ID, Nombre)
			SELECT ID, Nombre
			FROM OPENROWSET (
				BULK ''' + REPLACE(@sourceData, '''', '''''') + N''',
				SINGLE_NCLOB
			) AS P
			CROSS APPLY OPENJSON(Bulkcolumn, ''$.provincias'')
			WITH(
				ID varchar(max) ''$.id'',
				Nombre varchar(max) ''$.nombre_completo''
			);';

		EXEC sp_executesql @SQLDin;

		;WITH Duplicados AS (
			SELECT *,
				ROW_NUMBER() OVER (PARTITION BY TRY_CAST(ID AS INT) ORDER BY Nombre) AS rn
			FROM #TempProvincia
			WHERE TRY_CAST(ID AS INT) IS NOT NULL
			  AND NULLIF(LTRIM(RTRIM(Nombre)), '') IS NOT NULL
		)
		DELETE FROM Duplicados WHERE rn > 1;

		UPDATE P
		SET P.Nombre = LEFT(T.Nombre, 200)
		FROM [parque].[Provincia] P
		JOIN #TempProvincia T ON TRY_CAST(T.ID AS INT) = P.ID
		WHERE NULLIF(LTRIM(RTRIM(T.Nombre)), '') IS NOT NULL;

		INSERT INTO [parque].[Provincia](ID, Nombre)
		SELECT TRY_CAST(T.ID AS INT), LEFT(T.Nombre, 200)
		FROM #TempProvincia T
		WHERE TRY_CAST(T.ID AS INT) IS NOT NULL
		  AND NULLIF(LTRIM(RTRIM(T.Nombre)), '') IS NOT NULL
		  AND NOT EXISTS (
				SELECT 1
				FROM [parque].[Provincia] P
				WHERE P.ID = TRY_CAST(T.ID AS INT)
		  );

		SELECT COUNT(*) AS RegistrosInvalidos
		FROM #TempProvincia T
		WHERE TRY_CAST(T.ID AS INT) IS NULL
		   OR NULLIF(LTRIM(RTRIM(T.Nombre)), '') IS NULL;

		DROP TABLE #TempProvincia;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempProvincia') IS NOT NULL
			DROP TABLE #TempProvincia;

		THROW;
	END CATCH
END
GO

-- Importacion de Areas Protegidas desde CSV.
CREATE OR ALTER PROCEDURE [parque].[AreaProtegidaImportarActualizar]
	@sourceData VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		CREATE TABLE #TempAreasProtegidas(
			TYPE		VARCHAR(MAX),	SITE_ID		VARCHAR(MAX), 
			SITE_PID	VARCHAR(MAX),	SITE_TYPE	VARCHAR(MAX),
			NAME_ENG	VARCHAR(MAX),	NAME		VARCHAR(MAX),
			DESIG		VARCHAR(MAX),	DESIG_ENG	VARCHAR(MAX),
			DESIG_TYPE	VARCHAR(MAX),	IUCN_CAT	VARCHAR(MAX),
			INT_CRIT	VARCHAR(MAX),	REALM		VARCHAR(MAX),
			REP_M_AREA	VARCHAR(MAX),	GIS_M_AREA	VARCHAR(MAX),
			REP_AREA	VARCHAR(MAX),	GIS_AREA	VARCHAR(MAX),
			NO_TAKE		VARCHAR(MAX),	NO_TK_AREA	VARCHAR(MAX),
			STATUS		VARCHAR(MAX),	STATUS_YR	VARCHAR(MAX),
			GOV_TYPE	VARCHAR(MAX),	GOVSUBTYPE	VARCHAR(MAX),
			OWN_TYPE	VARCHAR(MAX),	OWNSUBTYPE	VARCHAR(MAX),
			MANG_AUTH	VARCHAR(MAX),	MANG_PLAN	VARCHAR(MAX),
			VERIF		VARCHAR(MAX),	METADATAID	VARCHAR(MAX),
			PRNT_ISO3	VARCHAR(MAX),	ISO3		VARCHAR(MAX),
			SUPP_INFO	VARCHAR(MAX),	CONS_OBJ	VARCHAR(MAX),
			INLND_WTRS	VARCHAR(MAX),	OECM_ASMT	VARCHAR(MAX)
		);

		-- SQL dinamico necesario: BULK INSERT no acepta una variable simple como ruta del archivo.
		DECLARE @SQLDin NVARCHAR(MAX) = N'
			BULK INSERT #TempAreasProtegidas
			FROM ''' + REPLACE(@sourceData, '''', '''''') + N'''
			WITH (
				FIELDTERMINATOR = '','',
				ROWTERMINATOR   = ''0x0a'',
				FIRSTROW        = 2,
				CODEPAGE        = ''65001'',
				FIELDQUOTE      = ''"''
			);';
	
		EXEC sp_executesql @SQLDin;

		;WITH Duplicados AS (
			SELECT *,
				ROW_NUMBER() OVER (PARTITION BY TRY_CAST(REPLACE(SITE_PID, '_', '') AS BIGINT) ORDER BY NAME) AS rn
			FROM #TempAreasProtegidas
			WHERE TRY_CAST(REPLACE(SITE_PID, '_', '') AS BIGINT) IS NOT NULL
		)
		DELETE FROM Duplicados WHERE rn > 1;
	
		UPDATE P
		SET 
			P.Nombre     = LEFT(T.NAME, 100),
			P.TipoArea	 = T.DESIG,
			P.Superficie = TRY_CAST(T.REP_AREA AS DECIMAL(12,2))
		FROM [parque].[AreaProtegida] P
		JOIN #TempAreasProtegidas T ON P.ID = TRY_CAST(REPLACE(T.SITE_PID, '_', '') AS BIGINT)
		WHERE T.DESIG IN ('Parque Nacional', 'Reserva Nacional', 'Monumento Natural', 'Parque Nacional Marino')
		  AND NULLIF(LTRIM(RTRIM(T.NAME)), '') IS NOT NULL;
		
		INSERT INTO [parque].[AreaProtegida](ID, TipoArea, Nombre, Superficie)
		SELECT TRY_CAST(REPLACE(T.SITE_PID, '_', '') AS BIGINT), T.DESIG, LEFT(T.NAME, 100), TRY_CAST(T.REP_AREA AS DECIMAL(12,2))
		FROM #TempAreasProtegidas T
		WHERE T.DESIG IN ('Parque Nacional', 'Reserva Nacional', 'Monumento Natural', 'Parque Nacional Marino')
		  AND TRY_CAST(REPLACE(T.SITE_PID, '_', '') AS BIGINT) IS NOT NULL
		  AND NULLIF(LTRIM(RTRIM(T.NAME)), '') IS NOT NULL
		  AND NOT EXISTS (
				SELECT 1
				FROM [parque].[AreaProtegida] P
				WHERE P.ID = TRY_CAST(REPLACE(T.SITE_PID, '_', '') AS BIGINT)
		  );

		SELECT COUNT(*) AS RegistrosInvalidos
		FROM #TempAreasProtegidas T
		WHERE T.DESIG NOT IN ('Parque Nacional', 'Reserva Nacional', 'Monumento Natural', 'Parque Nacional Marino')
		   OR TRY_CAST(REPLACE(T.SITE_PID, '_', '') AS BIGINT) IS NULL
		   OR NULLIF(LTRIM(RTRIM(T.NAME)), '') IS NULL;
		
		DROP TABLE #TempAreasProtegidas;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempAreasProtegidas') IS NOT NULL
			DROP TABLE #TempAreasProtegidas;

		THROW;
	END CATCH
END
GO

-- Importacion de centroides y vinculacion directa con areas protegidas.
CREATE OR ALTER PROCEDURE [parque].[CentroideImportar]
	@sourceData VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		CREATE TABLE #TempCentroides(
			SITE_ID		VARCHAR(MAX),	SITE_PID	VARCHAR(MAX),
			SITE_TYPE	VARCHAR(MAX),	NAME_ENG	VARCHAR(MAX),
			NAME		VARCHAR(MAX),	DESIG		VARCHAR(MAX),
			DESIG_ENG	VARCHAR(MAX),	DESIG_TYPE	VARCHAR(MAX),
			IUCN_CAT	VARCHAR(MAX),	INT_CRIT	VARCHAR(MAX),
			REALM		VARCHAR(MAX),	REP_M_AREA	VARCHAR(MAX),
			REP_AREA	VARCHAR(MAX),	NO_TAKE	VARCHAR(MAX),
			NO_TK_AREA	VARCHAR(MAX),	STATUS	VARCHAR(MAX),
			STATUS_YR	VARCHAR(MAX),	GOV_TYPE VARCHAR(MAX),
			GOVSUBTYPE	VARCHAR(MAX),	OWN_TYPE VARCHAR(MAX),
			OWNSUBTYPE	VARCHAR(MAX),	MANG_AUTH VARCHAR(MAX),
			MANG_PLAN	VARCHAR(MAX),	VERIF VARCHAR(MAX),
			METADATAID	VARCHAR(MAX),	PRNT_ISO3 VARCHAR(MAX),
			ISO3		VARCHAR(MAX),	SUPP_INFO VARCHAR(MAX),
			CONS_OBJ	VARCHAR(MAX),	INLND_WTRS VARCHAR(MAX),
			OECM_ASMT	VARCHAR(MAX),	latitude VARCHAR(MAX),
			longitude	VARCHAR(MAX)
		);

		-- SQL dinamico necesario: BULK INSERT no acepta una variable simple como ruta del archivo.
		DECLARE @SQLDin NVARCHAR(MAX) = N'
			BULK INSERT #TempCentroides
			FROM ''' + REPLACE(@sourceData, '''', '''''') + N'''
			WITH (
				FIELDTERMINATOR = '','',
				ROWTERMINATOR = ''0x0a'',
				FIRSTROW = 2,
				CODEPAGE = ''65001'',
				FIELDQUOTE = ''"''
			);';

		EXEC sp_executesql @SQLDin;

		;WITH Duplicados AS (
			SELECT *,
				ROW_NUMBER() OVER (PARTITION BY TRY_CAST(REPLACE(SITE_PID, '_', '') AS BIGINT) ORDER BY NAME) AS rn
			FROM #TempCentroides
			WHERE TRY_CAST(REPLACE(SITE_PID, '_', '') AS BIGINT) IS NOT NULL
		)
		DELETE FROM Duplicados WHERE rn > 1;

		UPDATE P
		SET
			P.Longitud = TRY_CAST(T.longitude AS DECIMAL(12,9)),
			P.Latitud  = TRY_CAST(T.latitude AS DECIMAL(12,9))
		FROM [parque].[AreaProtegida] P
		JOIN #TempCentroides T ON TRY_CAST(REPLACE(T.SITE_PID, '_', '') AS BIGINT) = P.ID
		WHERE TRY_CAST(T.latitude AS DECIMAL(12,9)) IS NOT NULL
		  AND TRY_CAST(T.longitude AS DECIMAL(12,9)) IS NOT NULL;

		SELECT COUNT(*) AS RegistrosInvalidos
		FROM #TempCentroides T
		WHERE TRY_CAST(REPLACE(T.SITE_PID, '_', '') AS BIGINT) IS NULL
		   OR TRY_CAST(T.latitude AS DECIMAL(12,9)) IS NULL
		   OR TRY_CAST(T.longitude AS DECIMAL(12,9)) IS NULL;

		DROP TABLE #TempCentroides;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempCentroides') IS NOT NULL
			DROP TABLE #TempCentroides;

		THROW;
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE [parque].[CentroideTemporalEliminar] AS
BEGIN
	SET NOCOUNT ON;
	PRINT('INFO: La importacion de centroides usa tabla temporal local y no requiere limpieza manual.');
END;
GO

CREATE OR ALTER PROCEDURE [parque].[CentroideAreaVincular] AS
BEGIN
	SET NOCOUNT ON;
	PRINT('INFO: La vinculacion de centroides se realiza directamente en parque.CentroideImportar.');
END
GO

