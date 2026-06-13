USE com2900
GO

-- Importacion de Provincias desde @OrigenDatos
	CREATE OR ALTER PROCEDURE SP_importarActualizarProvincias
		@OrigenDatos nvarchar(MAX)
	AS
	BEGIN
		CREATE TABLE #TempProvincia (
			ID      INT             NOT NULL,
			Nombre  VARCHAR(200)    NOT NULL
		);

		DECLARE @SQLDin NVARCHAR(MAX) = '
			INSERT INTO #TempProvincia (ID, Nombre)
			SELECT ID, Nombre
			FROM OPENROWSET (
				BULK ' + '''' + @OrigenDatos + '''' + ', 
				SINGLE_NCLOB
			) as P
			CROSS APPLY OPENJSON(Bulkcolumn, ''$.provincias'')
			WITH(
				ID int ''$.id'',
				Nombre nvarchar(200) ''$.nombre_completo''
			)
		'
		EXEC sp_executesql @SQLDin;
		-- Con MERGE es mas simple.
		UPDATE [parque].[Provincia]
		SET Provincia.Nombre = T.Nombre
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
	END