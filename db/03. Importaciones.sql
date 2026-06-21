USE com2900
GO

-- Importacion de Provincias desde JSON
	CREATE OR ALTER PROCEDURE SP_importarActualizarProvincias
		@sourceData nvarchar(MAX)
	AS
	BEGIN
		BEGIN TRY
			CREATE TABLE #TempProvincia (
				ID      INT             NOT NULL,
				Nombre  VARCHAR(200)    NOT NULL
			);

			DECLARE @SQLDin NVARCHAR(MAX) = '
				INSERT INTO #TempProvincia (ID, Nombre)
				SELECT ID, Nombre
				FROM OPENROWSET (
					BULK ' + '''' + @sourceData + '''' + ', 
					SINGLE_NCLOB
				) as P
				CROSS APPLY OPENJSON(Bulkcolumn, ''$.provincias'')
				WITH(
					ID int ''$.id'',
					Nombre nvarchar(200) ''$.nombre_completo''
				)
			'
			EXEC sp_executesql @SQLDin;

			UPDATE P
			SET P.Nombre = T.Nombre
			FROM [parque].[Provincia] P
			JOIN #TempProvincia T ON T.ID = P.ID

			INSERT INTO [parque].[Provincia](ID, Nombre)
			SELECT T.ID, T.Nombre
			FROM #TempProvincia T
			WHERE NOT EXISTS (
					SELECT 1 
					FROM [parque].[Provincia] P
					WHERE P.ID = T.ID
			);
			DROP TABLE #TempProvincia
		END TRY
		BEGIN CATCH
			IF OBJECT_ID('tempdb..#TempProvincia') IS NOT NULL
			BEGIN
				DROP TABLE #TempProvincia
			END;
			THROW;
		END CATCH
	END
	GO
	
-- IMPORTACION DE AREAS PROTEGIDAS DESDE CSV
	CREATE OR ALTER PROCEDURE SP_importarActualizarParquesNacionales
		@sourceData VARCHAR(MAX)
	AS
	BEGIN
		BEGIN TRY
			create table #TempAreasProtegidas(
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
			)
			DECLARE @SQLDin NVARCHAR(MAX) = '
				BULK INSERT #TempAreasProtegidas
				FROM ''' + @sourceData + '''
				WITH (
					FIELDTERMINATOR = '','',
					ROWTERMINATOR   = ''0x0a'',
					FIRSTROW        = 2,
					CODEPAGE        = ''65001'',
					FIELDQUOTE      = ''"''
			)'
		
			EXEC sp_executesql @SQLDin

			UPDATE P
			SET 
				P.Nombre     = T.Name,
				P.TipoParque = T.Desig,
				P.Superficie = TRY_CAST(T.REP_AREA AS DECIMAL(12,2))
			FROM [parque].[ParqueNacional] as P JOIN #TempAreasProtegidas as T on P.ID = TRY_CAST(T.SITE_ID AS INT)
			
			INSERT INTO [parque].[ParqueNacional](ID, TipoParque, Nombre, Superficie)
			SELECT TRY_CAST(T.SITE_ID AS INT), T.DESIG, T.NAME, TRY_CAST(T.REP_AREA AS DECIMAL(12,2)) FROM #TempAreasProtegidas T
			WHERE T.DESIG IN ('Parque Nacional', 'Reserva Nacional', 'Monumento Natural', 'Parque Nacional Marino')
			AND NOT EXISTS (SELECT 1 FROM [parque].[ParqueNacional] P WHERE P.ID = TRY_CAST(T.SITE_ID AS INT));

			DROP TABLE #TempAreasProtegidas

		END TRY
		BEGIN CATCH
			IF OBJECT_ID('tempdb..#TempAreasProtegidas') IS NOT NULL
			BEGIN
				DROP TABLE #TempAreasProtegidas
			END;
			THROW;
		END CATCH
	END
	GO

-- IMPORTACION DE CENTROIDES Y CREACION DE TABLA GLOBAL
		CREATE OR ALTER PROCEDURE [parque].[SP_ImportarCentroides]
			@sourceData VARCHAR(MAX)
		AS
		BEGIN
			BEGIN TRY
				IF OBJECT_ID('tempdb..##tempCentroides') IS NULL
					BEGIN
						CREATE TABLE ##tempCentroides(
							SITE_ID		INT NOT NULL,	SITE_PID	VARCHAR(MAX),
							SITE_TYPE	VARCHAR(MAX),	NAME_ENG	VARCHAR(MAX),
							NAME		VARCHAR(MAX),	DESIG		VARCHAR(MAX),
							DESIG_ENG	VARCHAR(MAX),	DESIG_TYPE	VARCHAR(MAX),
							IUCN_CAT	VARCHAR(MAX),	INT_CRIT	VARCHAR(MAX),
							REALM		VARCHAR(MAX),	REP_M_AREA	VARCHAR(MAX),
							REP_AREA	VARCHAR(MAX),	NO_TAKE		VARCHAR(MAX),
							NO_TK_AREA	VARCHAR(MAX),	STATUS		VARCHAR(MAX),
							STATUS_YR	VARCHAR(MAX),	GOV_TYPE	VARCHAR(MAX),
							GOVSUBTYPE	VARCHAR(MAX),	OWN_TYPE	VARCHAR(MAX),
							OWNSUBTYPE	VARCHAR(MAX),	MANG_AUTH	VARCHAR(MAX),
							MANG_PLAN	VARCHAR(MAX),	VERIF		VARCHAR(MAX),
							METADATAID	VARCHAR(MAX),	PRNT_ISO3	VARCHAR(MAX),
							ISO3		VARCHAR(MAX),	SUPP_INFO	VARCHAR(MAX),
							CONS_OBJ	VARCHAR(MAX),	INLND_WTRS	VARCHAR(MAX),
							OECM_ASMT	VARCHAR(MAX),	latitude	DECIMAL(12,9),
							longitude	DECIMAL(12,9)

							CONSTRAINT PK_tempCentroides PRIMARY KEY (SITE_ID)
						)
					END

					DECLARE @SQLDin NVARCHAR(MAX) = '
						BULK INSERT ##tempCentroides 
						FROM ' + '''' + @sourceData + '''' + '
						WITH(
							FIELDTERMINATOR = '','',
							ROWTERMINATOR = ''0x0a'',
							FIRSTROW = 2,
							CODEPAGE = ''65001'',
							FIELDQUOTE = ''"''
						);
						'
	
					EXEC sp_executesql @SQLDin
				END TRY
			BEGIN CATCH
				THROW;
			END CATCH
		END
		GO

		-- FORZADO DE ELIMINACION DE TABLA TEMPORAL DE CENTROIDES: tempCentroides
			CREATE OR ALTER PROCEDURE [parque].[SP_EliminarTablaTemporalCentroides] AS
			BEGIN
				if exists (select 1 from tempdb.sys.tables where name like '##tempCentroides%')
					DROP TABLE ##tempCentroides;
			END;
			GO

-- VINCULACION DE CENTROIDES IMPORTADOS Y CREACION DE TABLA GLOBAL
	CREATE OR ALTER PROCEDURE [parque].[VincularCentroidesAreas] AS
	BEGIN
		BEGIN TRY
			UPDATE P
			SET
				P.Longitud = CAST(T.longitude AS DECIMAL(12,9)),
				P.Latitud  = CAST(T.latitude AS DECIMAL(12,9))
			FROM [parque].[VincularCentroidesAreas] 
			JOIN ##tempCentroides T ON T.SITE_ID = P.ID
			--EXEC [parque].[SP_EliminarTablaTemporalCentroides]
		END TRY
		BEGIN CATCH
			--EXEC [parque].[SP_EliminarTablaTemporalCentroides]
			THROW;
		END CATCH
	END