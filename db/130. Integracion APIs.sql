/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emmanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Fecha: 28/06/2026
* Script: 130. Integracion APIs
* Descripción: Crea tablas y procedimientos para consumir APIs publicas de feriados y cotizacion del dolar.
*/

USE com2900;
GO

IF SCHEMA_ID('integracion') IS NULL
	EXEC('CREATE SCHEMA integracion');
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FeriadoArgentina' AND schema_id = SCHEMA_ID('integracion'))
BEGIN
	CREATE TABLE integracion.FeriadoArgentina (
		Fecha          DATE           NOT NULL,
		Anio           INT            NOT NULL,
		Tipo           VARCHAR(100)   NOT NULL,
		Nombre         VARCHAR(200)   NOT NULL,
		FechaConsulta  DATETIME2(0)   NOT NULL CONSTRAINT DF_FeriadoArgentina_FechaConsulta DEFAULT SYSDATETIME(),
		CONSTRAINT PK_FeriadoArgentina PRIMARY KEY (Fecha)
	);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CotizacionDolar' AND schema_id = SCHEMA_ID('integracion'))
BEGIN
	CREATE TABLE integracion.CotizacionDolar (
		ID                  INT             IDENTITY(1,1) NOT NULL,
		Casa                VARCHAR(50)     NOT NULL,
		Nombre              VARCHAR(100)    NOT NULL,
		Moneda              VARCHAR(10)     NOT NULL,
		Compra              DECIMAL(18,4)   NULL,
		Venta               DECIMAL(18,4)   NULL,
		FechaActualizacion  DATETIME2(0)    NULL,
		FechaConsulta       DATETIME2(0)    NOT NULL CONSTRAINT DF_CotizacionDolar_FechaConsulta DEFAULT SYSDATETIME(),
		CONSTRAINT PK_CotizacionDolar PRIMARY KEY (ID)
	);

	CREATE UNIQUE INDEX UX_CotizacionDolar_Casa_Fecha
		ON integracion.CotizacionDolar(Casa, FechaActualizacion)
		WHERE FechaActualizacion IS NOT NULL;
END;
GO

CREATE OR ALTER PROCEDURE integracion.ApiHttpGet
	@Url       NVARCHAR(500),
	@Response  NVARCHAR(MAX) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Object INT;
	DECLARE @Resultado INT;
	DECLARE @HttpStatus INT;
	DECLARE @Errores NVARCHAR(MAX) = N'';
	DECLARE @Json TABLE (Data NVARCHAR(MAX));

	IF NULLIF(LTRIM(RTRIM(@Url)), N'') IS NULL
		SET @Errores += N'- La URL de la API es obligatoria.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	BEGIN TRY
		-- Uso necesario de OLE Automation: SQL Server no posee un cliente HTTP nativo en T-SQL.
		EXEC @Resultado = sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
		IF @Resultado <> 0
			THROW 50002, 'No se pudo crear el cliente HTTP OLE. Verifique que Ole Automation Procedures este habilitado.', 1;

		EXEC @Resultado = sp_OAMethod @Object, 'setTimeouts', NULL, 5000, 5000, 10000, 10000;
		IF @Resultado <> 0
			THROW 50002, 'No se pudieron configurar los tiempos de espera del cliente HTTP.', 1;

		EXEC @Resultado = sp_OAMethod @Object, 'open', NULL, 'GET', @Url, 'false';
		IF @Resultado <> 0
			THROW 50002, 'No se pudo abrir la conexion HTTP.', 1;

		EXEC @Resultado = sp_OAMethod @Object, 'send';
		IF @Resultado <> 0
			THROW 50002, 'No se pudo enviar la solicitud HTTP.', 1;

		EXEC @Resultado = sp_OAGetProperty @Object, 'status', @HttpStatus OUT;
		IF @Resultado <> 0
			THROW 50002, 'No se pudo obtener el estado HTTP de la respuesta.', 1;

		INSERT INTO @Json(Data)
			EXEC sp_OAGetProperty @Object, 'responseText';

		SELECT @Response = Data FROM @Json;

		EXEC sp_OADestroy @Object;
		SET @Object = NULL;

		IF @HttpStatus < 200 OR @HttpStatus >= 300
			THROW 50002, 'La API devolvio un estado HTTP no exitoso.', 1;

		IF NULLIF(LTRIM(RTRIM(@Response)), N'') IS NULL
			THROW 50002, 'La API no devolvio contenido.', 1;
	END TRY
	BEGIN CATCH
		IF @Object IS NOT NULL
			EXEC sp_OADestroy @Object;

		THROW;
	END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE integracion.FeriadoImportarActualizar
	@Anio INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';
	DECLARE @Url NVARCHAR(500);
	DECLARE @Respuesta NVARCHAR(MAX);

	IF @Anio IS NULL OR @Anio < 2016 OR @Anio > YEAR(GETDATE())
		SET @Errores += N'- El año debe estar entre 2016 y el año actual.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	SET @Url = CONCAT(N'https://api.argentinadatos.com/v1/feriados/', @Anio);

	EXEC integracion.ApiHttpGet
		@Url = @Url,
		@Response = @Respuesta OUTPUT;

	CREATE TABLE #FeriadosApi (
		Fecha  DATE          NULL,
		Tipo   VARCHAR(100)  NULL,
		Nombre VARCHAR(200)  NULL
	);

	INSERT INTO #FeriadosApi(Fecha, Tipo, Nombre)
	SELECT
		TRY_CONVERT(DATE, Fecha, 23),
		LEFT(Tipo, 100),
		LEFT(Nombre, 200)
	FROM OPENJSON(@Respuesta)
	WITH (
		Fecha  VARCHAR(20)   '$.fecha',
		Tipo   VARCHAR(100)  '$.tipo',
		Nombre VARCHAR(200)  '$.nombre'
	);

	;WITH Duplicados AS (
		SELECT *,
			ROW_NUMBER() OVER (PARTITION BY Fecha ORDER BY Nombre) AS rn
		FROM #FeriadosApi
		WHERE Fecha IS NOT NULL
	)
	DELETE FROM Duplicados WHERE rn > 1;

	UPDATE F
	SET
		F.Anio = @Anio,
		F.Tipo = A.Tipo,
		F.Nombre = A.Nombre,
		F.FechaConsulta = SYSDATETIME()
	FROM integracion.FeriadoArgentina F
	JOIN #FeriadosApi A ON A.Fecha = F.Fecha
	WHERE A.Fecha IS NOT NULL
	  AND NULLIF(LTRIM(RTRIM(A.Tipo)), '') IS NOT NULL
	  AND NULLIF(LTRIM(RTRIM(A.Nombre)), '') IS NOT NULL;

	INSERT INTO integracion.FeriadoArgentina(Fecha, Anio, Tipo, Nombre)
	SELECT A.Fecha, @Anio, A.Tipo, A.Nombre
	FROM #FeriadosApi A
	WHERE A.Fecha IS NOT NULL
	  AND NULLIF(LTRIM(RTRIM(A.Tipo)), '') IS NOT NULL
	  AND NULLIF(LTRIM(RTRIM(A.Nombre)), '') IS NOT NULL
	  AND NOT EXISTS (
			SELECT 1
			FROM integracion.FeriadoArgentina F
			WHERE F.Fecha = A.Fecha
	  );

	SELECT COUNT(*) AS RegistrosInvalidos
	FROM #FeriadosApi
	WHERE Fecha IS NULL
	   OR NULLIF(LTRIM(RTRIM(Tipo)), '') IS NULL
	   OR NULLIF(LTRIM(RTRIM(Nombre)), '') IS NULL;

	DROP TABLE #FeriadosApi;
END;
GO

CREATE OR ALTER PROCEDURE integracion.CotizacionDolarImportarActualizar
	@ActualizarDivisa BIT = 1,
	@CasaDivisa VARCHAR(50) = 'oficial'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Respuesta NVARCHAR(MAX);
	DECLARE @ValorVenta DECIMAL(18,4);

	EXEC integracion.ApiHttpGet
		@Url = N'https://dolarapi.com/v1/dolares',
		@Response = @Respuesta OUTPUT;

	CREATE TABLE #CotizacionesApi (
		Casa                VARCHAR(50)    NULL,
		Nombre              VARCHAR(100)   NULL,
		Moneda              VARCHAR(10)    NULL,
		Compra              DECIMAL(18,4)  NULL,
		Venta               DECIMAL(18,4)  NULL,
		FechaActualizacion  DATETIME2(0)   NULL
	);

	INSERT INTO #CotizacionesApi(Casa, Nombre, Moneda, Compra, Venta, FechaActualizacion)
	SELECT
		LEFT(Casa, 50),
		LEFT(Nombre, 100),
		LEFT(Moneda, 10),
		Compra,
		Venta,
		CAST(TRY_CONVERT(DATETIMEOFFSET, FechaActualizacion, 127) AS DATETIME2(0))
	FROM OPENJSON(@Respuesta)
	WITH (
		Compra              DECIMAL(18,4)  '$.compra',
		Venta               DECIMAL(18,4)  '$.venta',
		Casa                VARCHAR(50)    '$.casa',
		Nombre              VARCHAR(100)   '$.nombre',
		Moneda              VARCHAR(10)    '$.moneda',
		FechaActualizacion  VARCHAR(40)    '$.fechaActualizacion'
	);

	INSERT INTO integracion.CotizacionDolar(Casa, Nombre, Moneda, Compra, Venta, FechaActualizacion)
	SELECT C.Casa, C.Nombre, C.Moneda, C.Compra, C.Venta, C.FechaActualizacion
	FROM #CotizacionesApi C
	WHERE NULLIF(LTRIM(RTRIM(C.Casa)), '') IS NOT NULL
	  AND NULLIF(LTRIM(RTRIM(C.Nombre)), '') IS NOT NULL
	  AND C.Venta IS NOT NULL
	  AND NOT EXISTS (
			SELECT 1
			FROM integracion.CotizacionDolar D
			WHERE D.Casa = C.Casa
			  AND ISNULL(D.FechaActualizacion, '19000101') = ISNULL(C.FechaActualizacion, '19000101')
	  );

	IF @ActualizarDivisa = 1
	BEGIN
		SELECT TOP 1 @ValorVenta = Venta
		FROM integracion.CotizacionDolar
		WHERE Casa = @CasaDivisa
		  AND Venta IS NOT NULL
		ORDER BY FechaActualizacion DESC, ID DESC;

		IF @ValorVenta IS NULL
			THROW 50001, 'No se encontro cotizacion valida para actualizar la divisa USD.', 1;

		IF EXISTS (SELECT 1 FROM venta.Divisa WHERE COD_ISO = 'USD')
			EXEC venta.DivisaModificacion
				@COD_ISO = 'USD',
				@Pais = 'Estados Unidos',
				@ValorEnPesos = @ValorVenta;
		ELSE
			EXEC venta.DivisaAlta
				@COD_ISO = 'USD',
				@Pais = 'Estados Unidos',
				@ValorEnPesos = @ValorVenta;
	END;

	SELECT COUNT(*) AS RegistrosInvalidos
	FROM #CotizacionesApi
	WHERE NULLIF(LTRIM(RTRIM(Casa)), '') IS NULL
	   OR NULLIF(LTRIM(RTRIM(Nombre)), '') IS NULL
	   OR Venta IS NULL;

	DROP TABLE #CotizacionesApi;
END;
GO

CREATE OR ALTER PROCEDURE integracion.FeriadoConsultar
	@Fecha     DATE,
	@EsFeriado BIT OUTPUT,
	@Nombre    VARCHAR(200) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	SET @EsFeriado = 0;
	SET @Nombre = NULL;

	IF EXISTS (SELECT 1 FROM integracion.FeriadoArgentina WHERE Fecha = @Fecha)
	BEGIN
		SET @EsFeriado = 1;

		SELECT @Nombre = Nombre
		FROM integracion.FeriadoArgentina
		WHERE Fecha = @Fecha;
	END;
END;
GO

CREATE OR ALTER PROCEDURE integracion.DolarCotizacionObtener
	@Casa       VARCHAR(50) = 'oficial',
	@ValorVenta DECIMAL(18,4) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT TOP 1 @ValorVenta = Venta
	FROM integracion.CotizacionDolar
	WHERE Casa = @Casa
	  AND Venta IS NOT NULL
	ORDER BY FechaActualizacion DESC, ID DESC;

	IF @ValorVenta IS NULL
		THROW 50001, 'No existe una cotizacion valida para la casa indicada.', 1;
END;
GO
