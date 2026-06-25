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
* Fecha: 23/06/2026
* Script: 060. Creación concesion
* Descripción: Crea el esquema concesion, sus tablas y los stored procedures para las operaciones ABM de cada tabla
*/

USE com2900;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'concesion')
	BEGIN TRY
		EXEC('CREATE SCHEMA concesion')
		PRINT('OK: esquema concesion creado exitosamente');
	END TRY
	BEGIN CATCH
		PRINT('ERROR: No se pudo crear el esquema concesion');
		THROW;
	END CATCH
ELSE PRINT ('INFO: el esquema concesion ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ActividadFiscal' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.ActividadFiscal (
			ID          INT IDENTITY(1,1)   NOT NULL,
			Nombre      VARCHAR(100)        NULL,

			CONSTRAINT PK_ActividadFiscal PRIMARY KEY (ID)
		);
		PRINT('OK: tabla ActividadFiscal creada exitosamente');
	END
ELSE PRINT('INFO: tabla ActividadFiscal ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Empresa' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.Empresa (
			CUIT    BIGINT       NOT NULL,
			Nombre  VARCHAR(150) NULL,

			CONSTRAINT PK_Empresa PRIMARY KEY (CUIT)
		);
		PRINT('OK: tabla Empresa creada exitosamente');
	END
ELSE PRINT('INFO: tabla Empresa ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoConcesion' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.TipoConcesion (
			ID                  INT IDENTITY(1,1)   NOT NULL,
			ID_ActividadFiscal  INT                 NOT NULL,
			Nombre              VARCHAR(100)        NOT NULL,

			CONSTRAINT PK_TipoConcesion PRIMARY KEY (ID),
			CONSTRAINT FK_TipoConcesion_ActividadFiscal FOREIGN KEY (ID_ActividadFiscal) REFERENCES concesion.ActividadFiscal(ID)
		);
		PRINT('OK: tabla TipoConcesion creada exitosamente');
	END
ELSE PRINT('INFO: tabla TipoConcesion ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ActividadFiscalInscriptaEmpresa' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.ActividadFiscalInscriptaEmpresa (
			CUIT_Empresa        BIGINT  NOT NULL,
			ID_ActividadFiscal  INT     NOT NULL,
			Principal           BIT     NOT NULL CONSTRAINT DF_ActividadFiscalInscriptaEmpresa_Principal DEFAULT (0),
			CONSTRAINT PK_ActividadFiscalInscriptaEmpresa PRIMARY KEY (CUIT_Empresa, ID_ActividadFiscal),
			CONSTRAINT FK_ActividadFiscalInscriptaEmpresa_Empresa FOREIGN KEY (CUIT_Empresa) REFERENCES concesion.Empresa(CUIT),
			CONSTRAINT FK_ActividadFiscalInscriptaEmpresa_ActividadFiscal FOREIGN KEY (ID_ActividadFiscal) REFERENCES concesion.ActividadFiscal(ID)
		);
		PRINT('OK: tabla ActividadFiscalInscriptaEmpresa creada exitosamente');
	END
ELSE PRINT('INFO: tabla ActividadFiscalInscriptaEmpresa ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Concesion' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.Concesion (
			ID                  INT IDENTITY(1,1)   NOT NULL,
			ID_AreaProtegida    BIGINT              NOT NULL,
			CUIT_Empresa        BIGINT              NOT NULL,
			ID_TipoConcesion    INT                 NOT NULL,
			FechaInicio         DATE                NOT NULL,
			FechaFin            DATE                NOT NULL,
			Canon               DECIMAL(20,2)       NOT NULL,

			CONSTRAINT PK_Concesion PRIMARY KEY (ID),
			CONSTRAINT FK_Concesion_Parque FOREIGN KEY (ID_AreaProtegida) REFERENCES parque.AreaProtegida(ID),
			CONSTRAINT FK_Concesion_Empresa FOREIGN KEY (CUIT_Empresa) REFERENCES concesion.Empresa(CUIT),
			CONSTRAINT FK_Concesion_TipoConcesion FOREIGN KEY (ID_TipoConcesion) REFERENCES concesion.TipoConcesion(ID)
		);
		PRINT('OK: tabla Concesion creada exitosamente');
	END
ELSE PRINT('INFO: tabla Concesion ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacturaConcesion' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.FacturaConcesion (
			ID                  INT IDENTITY(1,1)   NOT NULL,
			ID_Concesion        INT                 NOT NULL,
			FechaEmision        DATE                NOT NULL,
			FechaVencimiento    DATE                NOT NULL,
			MontoEsperado       DECIMAL(20,2)       NOT NULL,

			CONSTRAINT PK_FacturaConcesion PRIMARY KEY (ID),
			CONSTRAINT FK_FacturaConcesion_Concesion FOREIGN KEY (ID_Concesion) REFERENCES concesion.Concesion(ID)
		);
		PRINT('OK: tabla FacturaConcesion creada exitosamente');
	END
ELSE PRINT('INFO: tabla FacturaConcesion ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PagoConcesion' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.PagoConcesion (
			ID          INT IDENTITY(1,1)   NOT NULL,
			ID_Factura  INT                 NOT NULL,
			FechaPago   DATE                NOT NULL,
			MontoPagado DECIMAL(20,2)       NOT NULL,

			CONSTRAINT PK_PagoConcesion PRIMARY KEY (ID),
			CONSTRAINT FK_PagoConcesion_Factura FOREIGN KEY (ID_Factura) REFERENCES concesion.FacturaConcesion(ID)
		);
		PRINT('OK: tabla PagoConcesion creada exitosamente');
	END
ELSE PRINT('INFO: tabla PagoConcesion ya existe');

GO

-- ============================================================================
-- Stored Procedures ABM para concesion.ActividadFiscal
-- ============================================================================

IF OBJECT_ID('concesion.ActividadFiscalAlta', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ActividadFiscalAlta;
GO

CREATE PROCEDURE concesion.ActividadFiscalAlta
	@Nombre      VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM concesion.ActividadFiscal WHERE Nombre = @Nombre)
	BEGIN
		RAISERROR('La actividad fiscal ya existe.', 16, 1);
		RETURN;
	END

	INSERT INTO concesion.ActividadFiscal (Nombre)
	VALUES (@Nombre);

	SELECT SCOPE_IDENTITY() AS ID;
END;
GO

IF OBJECT_ID('concesion.ActividadFiscalBaja', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ActividadFiscalBaja;
GO

CREATE PROCEDURE concesion.ActividadFiscalBaja
	@ID          INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscal WHERE ID = @ID)
	BEGIN
		RAISERROR('La actividad fiscal no existe.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.TipoConcesion WHERE ID_ActividadFiscal = @ID)
	BEGIN
		RAISERROR('No se puede eliminar: la actividad fiscal está vinculada a tipos de concesión.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.ActividadFiscalInscriptaEmpresa WHERE ID_ActividadFiscal = @ID)
	BEGIN
		RAISERROR('No se puede eliminar: la actividad fiscal está vinculada a empresas.', 16, 1);
		RETURN;
	END

	DELETE FROM concesion.ActividadFiscal WHERE ID = @ID;
END;
GO

IF OBJECT_ID('concesion.ActividadFiscalModificacion', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ActividadFiscalModificacion;
GO

CREATE PROCEDURE concesion.ActividadFiscalModificacion
	@ID          INT,
	@Nombre      VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscal WHERE ID = @ID)
	BEGIN
		RAISERROR('La actividad fiscal no existe.', 16, 1);
		RETURN;
	END

	IF @Nombre IS NOT NULL AND EXISTS (SELECT 1 FROM concesion.ActividadFiscal WHERE Nombre = @Nombre AND ID <> @ID)
	BEGIN
		RAISERROR('Ya existe otra actividad fiscal con ese nombre.', 16, 1);
		RETURN;
	END

	UPDATE concesion.ActividadFiscal
	SET Nombre = ISNULL(@Nombre, Nombre)
	WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE [concesion].[ActividadFiscalConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [concesion].[ActividadFiscal]
	WHERE ID = COALESCE(@ID, ID)
GO

-- ============================================================================
-- Stored Procedures ABM para concesion.Empresa
-- ============================================================================

IF OBJECT_ID('concesion.EmpresaAlta', 'P') IS NOT NULL
	DROP PROCEDURE concesion.EmpresaAlta;
GO

CREATE PROCEDURE concesion.EmpresaAlta
	@CUIT    BIGINT,
	@Nombre  VARCHAR(150)
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM concesion.Empresa WHERE CUIT = @CUIT)
	BEGIN
		RAISERROR('Ya existe una empresa con ese CUIT.', 16, 1);
		RETURN;
	END

	INSERT INTO concesion.Empresa (CUIT, Nombre)
	VALUES (@CUIT, @Nombre);
END;
GO

IF OBJECT_ID('concesion.EmpresaBaja', 'P') IS NOT NULL
	DROP PROCEDURE concesion.EmpresaBaja;
GO

CREATE PROCEDURE concesion.EmpresaBaja
	@CUIT    BIGINT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.Empresa WHERE CUIT = @CUIT)
	BEGIN
		RAISERROR('La empresa no existe.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.ActividadFiscalInscriptaEmpresa WHERE CUIT_Empresa = @CUIT)
	BEGIN
		RAISERROR('No se puede eliminar: la empresa tiene actividades fiscales inscriptas.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.Concesion WHERE CUIT_Empresa = @CUIT)
	BEGIN
		RAISERROR('No se puede eliminar: la empresa tiene concesiones vigentes.', 16, 1);
		RETURN;
	END

	DELETE FROM concesion.Empresa WHERE CUIT = @CUIT;
END;
GO

IF OBJECT_ID('concesion.EmpresaModificacion', 'P') IS NOT NULL
	DROP PROCEDURE concesion.EmpresaModificacion;
GO

CREATE PROCEDURE concesion.EmpresaModificacion
	@CUIT    BIGINT,
	@Nombre  VARCHAR(150)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.Empresa WHERE CUIT = @CUIT)
	BEGIN
		RAISERROR('La empresa no existe.', 16, 1);
		RETURN;
	END

	UPDATE concesion.Empresa
	SET Nombre = ISNULL(@Nombre, Nombre)
	WHERE CUIT = @CUIT;
END;
GO

CREATE OR ALTER PROCEDURE [concesion].[EmpresaConsulta]
	@CUIT BIGINT = NULL
AS
	SELECT * FROM [concesion].[Empresa]
	WHERE CUIT = COALESCE(@CUIT,CUIT)
GO

-- ============================================================================
-- Stored Procedures ABM para concesion.TipoConcesion
-- ============================================================================

IF OBJECT_ID('concesion.TipoConcesionAlta', 'P') IS NOT NULL
	DROP PROCEDURE concesion.TipoConcesionAlta;
GO

CREATE PROCEDURE concesion.TipoConcesionAlta
	@ID_ActividadFiscal  INT,
	@Nombre              VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscal WHERE ID = @ID_ActividadFiscal)
	BEGIN
		RAISERROR('La actividad fiscal especificada no existe.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.TipoConcesion WHERE Nombre = @Nombre AND ID_ActividadFiscal = @ID_ActividadFiscal)
	BEGIN
		RAISERROR('Ya existe un tipo de concesión con ese nombre para esa actividad fiscal.', 16, 1);
		RETURN;
	END

	INSERT INTO concesion.TipoConcesion (ID_ActividadFiscal, Nombre)
	VALUES (@ID_ActividadFiscal, @Nombre);

	SELECT SCOPE_IDENTITY() AS ID;
END;
GO

IF OBJECT_ID('concesion.TipoConcesionBaja', 'P') IS NOT NULL
	DROP PROCEDURE concesion.TipoConcesionBaja;
GO

CREATE PROCEDURE concesion.TipoConcesionBaja
	@ID          INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.TipoConcesion WHERE ID = @ID)
	BEGIN
		RAISERROR('El tipo de concesión no existe.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.Concesion WHERE ID_TipoConcesion = @ID)
	BEGIN
		RAISERROR('No se puede eliminar: el tipo de concesión está vinculado a concesiones.', 16, 1);
		RETURN;
	END

	DELETE FROM concesion.TipoConcesion WHERE ID = @ID;
END;
GO

IF OBJECT_ID('concesion.TipoConcesionModificacion', 'P') IS NOT NULL
	DROP PROCEDURE concesion.TipoConcesionModificacion;
GO

CREATE PROCEDURE concesion.TipoConcesionModificacion
	@ID                  INT,
	@ID_ActividadFiscal  INT,
	@Nombre              VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.TipoConcesion WHERE ID = @ID)
	BEGIN
		RAISERROR('El tipo de concesión no existe.', 16, 1);
		RETURN;
	END

	IF @ID_ActividadFiscal IS NOT NULL AND NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscal WHERE ID = @ID_ActividadFiscal)
	BEGIN
		RAISERROR('La actividad fiscal especificada no existe.', 16, 1);
		RETURN;
	END

	IF @Nombre IS NOT NULL AND EXISTS (SELECT 1 FROM concesion.TipoConcesion
		WHERE Nombre = @Nombre
		  AND ISNULL(@ID_ActividadFiscal, ID_ActividadFiscal) = ISNULL(@ID_ActividadFiscal, ID_ActividadFiscal)
		  AND ID <> @ID)
	BEGIN
		RAISERROR('Ya existe un tipo de concesión con ese nombre para esa actividad fiscal.', 16, 1);
		RETURN;
	END

	UPDATE concesion.TipoConcesion
	SET
		ID_ActividadFiscal = ISNULL(@ID_ActividadFiscal, ID_ActividadFiscal),
		Nombre             = ISNULL(@Nombre, Nombre)
	WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE [concesion].[TipoConcesionConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [concesion].[TipoConcesion]
	WHERE ID = COALESCE(@ID,ID)
GO

-- ============================================================================
-- Stored Procedures ABM para concesion.ActividadFiscalInscriptaEmpresa
-- ============================================================================

IF OBJECT_ID('concesion.ActividadFiscalInscriptaEmpresaAlta', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ActividadFiscalInscriptaEmpresaAlta;
GO

CREATE PROCEDURE concesion.ActividadFiscalInscriptaEmpresaAlta
	@CUIT_Empresa        BIGINT,
	@ID_ActividadFiscal  INT,
	@Principal           BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.Empresa WHERE CUIT = @CUIT_Empresa)
	BEGIN
		RAISERROR('La empresa no existe.', 16, 1);
		RETURN;
	END

	IF NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscal WHERE ID = @ID_ActividadFiscal)
	BEGIN
		RAISERROR('La actividad fiscal no existe.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.ActividadFiscalInscriptaEmpresa
		WHERE CUIT_Empresa = @CUIT_Empresa AND ID_ActividadFiscal = @ID_ActividadFiscal)
	BEGIN
		RAISERROR('La empresa ya está inscripta en esa actividad fiscal.', 16, 1);
		RETURN;
	END

	IF @Principal = 1 AND EXISTS (SELECT 1 FROM concesion.ActividadFiscalInscriptaEmpresa
		WHERE CUIT_Empresa = @CUIT_Empresa AND Principal = 1)
	BEGIN
		RAISERROR('La empresa ya tiene una actividad fiscal principal. Desactívela primero.', 16, 1);
		RETURN;
	END

	INSERT INTO concesion.ActividadFiscalInscriptaEmpresa (CUIT_Empresa, ID_ActividadFiscal, Principal)
	VALUES (@CUIT_Empresa, @ID_ActividadFiscal, @Principal);
END;
GO

IF OBJECT_ID('concesion.ActividadFiscalInscriptaEmpresaBaja', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ActividadFiscalInscriptaEmpresaBaja;
GO

CREATE PROCEDURE concesion.ActividadFiscalInscriptaEmpresaBaja
	@CUIT_Empresa        BIGINT,
	@ID_ActividadFiscal  INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscalInscriptaEmpresa
		WHERE CUIT_Empresa = @CUIT_Empresa AND ID_ActividadFiscal = @ID_ActividadFiscal)
	BEGIN
		RAISERROR('La inscripción no existe.', 16, 1);
		RETURN;
	END

	DELETE FROM concesion.ActividadFiscalInscriptaEmpresa
	WHERE CUIT_Empresa = @CUIT_Empresa AND ID_ActividadFiscal = @ID_ActividadFiscal;
END;
GO

IF OBJECT_ID('concesion.ActividadFiscalInscriptaEmpresaModificacion', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ActividadFiscalInscriptaEmpresaModificacion;
GO

CREATE PROCEDURE concesion.ActividadFiscalInscriptaEmpresaModificacion
	@CUIT_Empresa        BIGINT,
	@ID_ActividadFiscal  INT,
	@Principal           BIT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscalInscriptaEmpresa
		WHERE CUIT_Empresa = @CUIT_Empresa AND ID_ActividadFiscal = @ID_ActividadFiscal)
	BEGIN
		RAISERROR('La inscripción no existe.', 16, 1);
		RETURN;
	END

	IF @Principal = 1 AND EXISTS (SELECT 1 FROM concesion.ActividadFiscalInscriptaEmpresa
		WHERE CUIT_Empresa = @CUIT_Empresa AND Principal = 1
		  AND ID_ActividadFiscal <> @ID_ActividadFiscal)
	BEGIN
		RAISERROR('La empresa ya tiene una actividad fiscal principal. Desactívela primero.', 16, 1);
		RETURN;
	END

	UPDATE concesion.ActividadFiscalInscriptaEmpresa
	SET Principal = ISNULL(@Principal, Principal)
	WHERE CUIT_Empresa = @CUIT_Empresa AND ID_ActividadFiscal = @ID_ActividadFiscal;
END;
GO

CREATE OR ALTER PROCEDURE [concesion].[ActividadFiscalInscriptaEmpresaConsulta]
	@CUIT_Empresa BIGINT = NULL
AS
	SELECT * FROM [concesion].[ActividadFiscalInscriptaEmpresa]
	WHERE CUIT_Empresa = COALESCE(@CUIT_Empresa,CUIT_Empresa)
GO

-- ============================================================================
-- Stored Procedures ABM para concesion.Concesion
-- ============================================================================

IF OBJECT_ID('concesion.ConcesionAlta', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ConcesionAlta;
GO

CREATE PROCEDURE concesion.ConcesionAlta
	@ID_AreaProtegida    BIGINT,
	@CUIT_Empresa        BIGINT,
	@ID_TipoConcesion    INT,
	@FechaInicio         DATE,
	@FechaFin            DATE,
	@Canon               DECIMAL(20,2)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';

	IF NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @ID_AreaProtegida)
		SET @Errores += N'- El area protegida no existe.' + CHAR(13) + CHAR(10);

	IF NOT EXISTS (SELECT 1 FROM concesion.Empresa WHERE CUIT = @CUIT_Empresa)
		SET @Errores += N'- La empresa no existe.' + CHAR(13) + CHAR(10);

	IF NOT EXISTS (SELECT 1 FROM concesion.TipoConcesion WHERE ID = @ID_TipoConcesion)
		SET @Errores += N'- El tipo de concesion no existe.' + CHAR(13) + CHAR(10);

	IF @FechaInicio IS NULL
		SET @Errores += N'- La fecha de inicio es obligatoria.' + CHAR(13) + CHAR(10);

	IF @FechaFin IS NULL
		SET @Errores += N'- La fecha de fin es obligatoria.' + CHAR(13) + CHAR(10);

	IF @FechaInicio IS NOT NULL AND @FechaFin IS NOT NULL AND @FechaFin < @FechaInicio
		SET @Errores += N'- La fecha de fin debe ser posterior o igual a la fecha de inicio.' + CHAR(13) + CHAR(10);

	IF @Canon IS NULL OR @Canon <= 0
		SET @Errores += N'- El canon debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	INSERT INTO concesion.Concesion (ID_AreaProtegida, CUIT_Empresa, ID_TipoConcesion, FechaInicio, FechaFin, Canon)
	VALUES (@ID_AreaProtegida, @CUIT_Empresa, @ID_TipoConcesion, @FechaInicio, @FechaFin, @Canon);

	SELECT SCOPE_IDENTITY() AS ID;
END;
GO

IF OBJECT_ID('concesion.ConcesionBaja', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ConcesionBaja;
GO

CREATE PROCEDURE concesion.ConcesionBaja
	@ID          INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.Concesion WHERE ID = @ID)
	BEGIN
		RAISERROR('La concesión no existe.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.FacturaConcesion WHERE ID_Concesion = @ID)
	BEGIN
		RAISERROR('No se puede eliminar: la concesión tiene facturas asociadas.', 16, 1);
		RETURN;
	END

	DELETE FROM concesion.Concesion WHERE ID = @ID;
END;
GO

IF OBJECT_ID('concesion.ConcesionModificacion', 'P') IS NOT NULL
	DROP PROCEDURE concesion.ConcesionModificacion;
GO

CREATE PROCEDURE concesion.ConcesionModificacion
	@ID                  INT,
	@ID_AreaProtegida    BIGINT         = NULL,
	@CUIT_Empresa        BIGINT         = NULL,
	@ID_TipoConcesion    INT            = NULL,
	@FechaInicio         DATE           = NULL,
	@FechaFin            DATE           = NULL,
	@Canon               DECIMAL(20,2)  = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';
	DECLARE @FechaInicioFinal DATE;
	DECLARE @FechaFinFinal DATE;

	IF NOT EXISTS (SELECT 1 FROM concesion.Concesion WHERE ID = @ID)
		SET @Errores += N'- La concesion no existe.' + CHAR(13) + CHAR(10);

	IF @ID_AreaProtegida IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @ID_AreaProtegida)
		SET @Errores += N'- El area protegida no existe.' + CHAR(13) + CHAR(10);

	IF @CUIT_Empresa IS NOT NULL AND NOT EXISTS (SELECT 1 FROM concesion.Empresa WHERE CUIT = @CUIT_Empresa)
		SET @Errores += N'- La empresa no existe.' + CHAR(13) + CHAR(10);

	IF @ID_TipoConcesion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM concesion.TipoConcesion WHERE ID = @ID_TipoConcesion)
		SET @Errores += N'- El tipo de concesion no existe.' + CHAR(13) + CHAR(10);

	SELECT
		@FechaInicioFinal = ISNULL(@FechaInicio, FechaInicio),
		@FechaFinFinal = ISNULL(@FechaFin, FechaFin)
	FROM concesion.Concesion
	WHERE ID = @ID;

	IF @FechaInicioFinal IS NOT NULL AND @FechaFinFinal IS NOT NULL AND @FechaFinFinal < @FechaInicioFinal
		SET @Errores += N'- La fecha de fin debe ser posterior o igual a la fecha de inicio.' + CHAR(13) + CHAR(10);

	IF @Canon IS NOT NULL AND @Canon <= 0
		SET @Errores += N'- El canon debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	UPDATE concesion.Concesion
	SET
		ID_AreaProtegida = ISNULL(@ID_AreaProtegida, ID_AreaProtegida),
		CUIT_Empresa     = ISNULL(@CUIT_Empresa, CUIT_Empresa),
		ID_TipoConcesion = ISNULL(@ID_TipoConcesion, ID_TipoConcesion),
		FechaInicio      = ISNULL(@FechaInicio, FechaInicio),
		FechaFin         = ISNULL(@FechaFin, FechaFin),
		Canon            = ISNULL(@Canon, Canon)
	WHERE ID = @ID;
END;
GO


CREATE OR ALTER PROCEDURE [concesion].[ConcesionConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [concesion].[Concesion]
	WHERE ID = COALESCE(@ID,ID)
GO

-- ============================================================================
-- Stored Procedures ABM para concesion.FacturaConcesion
-- ============================================================================

IF OBJECT_ID('concesion.FacturaConcesionAlta', 'P') IS NOT NULL
	DROP PROCEDURE concesion.FacturaConcesionAlta;
GO

CREATE PROCEDURE concesion.FacturaConcesionAlta
	@ID_Concesion        INT,
	@FechaEmision        DATE,
	@FechaVencimiento    DATE,
	@MontoEsperado       DECIMAL(20,2)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';

	IF NOT EXISTS (SELECT 1 FROM concesion.Concesion WHERE ID = @ID_Concesion)
		SET @Errores += N'- La concesion no existe.' + CHAR(13) + CHAR(10);

	IF @FechaEmision IS NULL
		SET @Errores += N'- La fecha de emision es obligatoria.' + CHAR(13) + CHAR(10);

	IF @FechaVencimiento IS NULL
		SET @Errores += N'- La fecha de vencimiento es obligatoria.' + CHAR(13) + CHAR(10);

	IF @FechaEmision IS NOT NULL AND @FechaVencimiento IS NOT NULL AND @FechaVencimiento < @FechaEmision
		SET @Errores += N'- La fecha de vencimiento debe ser posterior o igual a la fecha de emision.' + CHAR(13) + CHAR(10);

	IF @MontoEsperado IS NULL OR @MontoEsperado <= 0
		SET @Errores += N'- El monto esperado debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	INSERT INTO concesion.FacturaConcesion (ID_Concesion, FechaEmision, FechaVencimiento, MontoEsperado)
	VALUES (@ID_Concesion, @FechaEmision, @FechaVencimiento, @MontoEsperado);

	SELECT SCOPE_IDENTITY() AS ID;
END;
GO

IF OBJECT_ID('concesion.FacturaConcesionBaja', 'P') IS NOT NULL
	DROP PROCEDURE concesion.FacturaConcesionBaja;
GO

CREATE PROCEDURE concesion.FacturaConcesionBaja
	@ID          INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.FacturaConcesion WHERE ID = @ID)
	BEGIN
		RAISERROR('La factura no existe.', 16, 1);
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM concesion.PagoConcesion WHERE ID_Factura = @ID)
	BEGIN
		RAISERROR('No se puede eliminar: la factura tiene pagos asociados.', 16, 1);
		RETURN;
	END

	DELETE FROM concesion.FacturaConcesion WHERE ID = @ID;
END;
GO

IF OBJECT_ID('concesion.FacturaConcesionModificacion', 'P') IS NOT NULL
	DROP PROCEDURE concesion.FacturaConcesionModificacion;
GO

CREATE PROCEDURE concesion.FacturaConcesionModificacion
	@ID                  INT,
	@ID_Concesion        INT            = NULL,
	@FechaEmision        DATE           = NULL,
	@FechaVencimiento    DATE           = NULL,
	@MontoEsperado       DECIMAL(20,2)  = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.FacturaConcesion WHERE ID = @ID)
	BEGIN
		RAISERROR('La factura no existe.', 16, 1);
		RETURN;
	END

	IF @ID_Concesion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM concesion.Concesion WHERE ID = @ID_Concesion)
	BEGIN
		RAISERROR('La concesión no existe.', 16, 1);
		RETURN;
	END

	UPDATE concesion.FacturaConcesion
	SET
		ID_Concesion     = ISNULL(@ID_Concesion, ID_Concesion),
		FechaEmision     = ISNULL(@FechaEmision, FechaEmision),
		FechaVencimiento = ISNULL(@FechaVencimiento, FechaVencimiento),
		MontoEsperado    = ISNULL(@MontoEsperado, MontoEsperado)
	WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE [concesion].[FacturaConcesionConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [concesion].[FacturaConcesion]
	WHERE ID = COALESCE(@ID,ID)
GO

-- ============================================================================
-- Stored Procedures ABM para concesion.PagoConcesion
-- ============================================================================

IF OBJECT_ID('concesion.PagoConcesionAlta', 'P') IS NOT NULL
	DROP PROCEDURE concesion.PagoConcesionAlta;
GO

CREATE PROCEDURE concesion.PagoConcesionAlta
	@ID_Factura    INT,
	@FechaPago     DATE,
	@MontoPagado   DECIMAL(20,2)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';

	IF NOT EXISTS (SELECT 1 FROM concesion.FacturaConcesion WHERE ID = @ID_Factura)
		SET @Errores += N'- La factura no existe.' + CHAR(13) + CHAR(10);

	IF @FechaPago IS NULL
		SET @Errores += N'- La fecha de pago es obligatoria.' + CHAR(13) + CHAR(10);

	IF @MontoPagado IS NULL OR @MontoPagado <= 0
		SET @Errores += N'- El monto pagado debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	INSERT INTO concesion.PagoConcesion (ID_Factura, FechaPago, MontoPagado)
	VALUES (@ID_Factura, @FechaPago, @MontoPagado);

	SELECT SCOPE_IDENTITY() AS ID;
END;
GO

IF OBJECT_ID('concesion.PagoConcesionBaja', 'P') IS NOT NULL
	DROP PROCEDURE concesion.PagoConcesionBaja;
GO

CREATE PROCEDURE concesion.PagoConcesionBaja
	@ID          INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.PagoConcesion WHERE ID = @ID)
	BEGIN
		RAISERROR('El pago no existe.', 16, 1);
		RETURN;
	END

	DELETE FROM concesion.PagoConcesion WHERE ID = @ID;
END;
GO

IF OBJECT_ID('concesion.PagoConcesionModificacion', 'P') IS NOT NULL
	DROP PROCEDURE concesion.PagoConcesionModificacion;
GO

CREATE PROCEDURE concesion.PagoConcesionModificacion
	@ID              INT,
	@ID_Factura      INT            = NULL,
	@FechaPago       DATE           = NULL,
	@MontoPagado     DECIMAL(20,2)  = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM concesion.PagoConcesion WHERE ID = @ID)
	BEGIN
		RAISERROR('El pago no existe.', 16, 1);
		RETURN;
	END

	IF @ID_Factura IS NOT NULL AND NOT EXISTS (SELECT 1 FROM concesion.FacturaConcesion WHERE ID = @ID_Factura)
	BEGIN
		RAISERROR('La factura no existe.', 16, 1);
		RETURN;
	END

	UPDATE concesion.PagoConcesion
	SET
		ID_Factura  = ISNULL(@ID_Factura, ID_Factura),
		FechaPago   = ISNULL(@FechaPago, FechaPago),
		MontoPagado = ISNULL(@MontoPagado, MontoPagado)
	WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE [concesion].[PagoConcesionConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [concesion].[PagoConcesion]
	WHERE ID = COALESCE(@ID,ID)
GO

