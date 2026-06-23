/*
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Script: 050. Creacion actividad
* Descripción: Crea el esquema actividad, sus tablas y los procedimientos almacenados ABM
*/

USE com2900;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'actividad')
	BEGIN TRY
		EXEC('CREATE SCHEMA actividad')
		PRINT('OK: esquema actividad creado exitosamente')
	END TRY
	BEGIN CATCH
		PRINT('ERROR: No se pudo crear el esquema actividad')
		RETURN
	END CATCH
ELSE PRINT ('INFO: el esquema actividad ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoActividad' AND schema_id = SCHEMA_ID('actividad'))
	BEGIN
		CREATE TABLE actividad.TipoActividad (
			ID      INT IDENTITY(1,1) NOT NULL,
			Nombre  VARCHAR(50)       NOT NULL,
			CONSTRAINT PK_TipoActividad PRIMARY KEY (ID)
		);
		PRINT('OK: tabla TipoActividad creada exitosamente');
	END
ELSE PRINT('INFO: tabla TipoActividad ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Actividad' AND schema_id = SCHEMA_ID('actividad'))
	BEGIN
		CREATE TABLE actividad.Actividad (
			ID                  INT IDENTITY(1,1) NOT NULL,
			ID_AreaProtegida    BIGINT            NOT NULL,
			ID_TipoActividad    INT               NOT NULL,
			Nombre              VARCHAR(50)       NOT NULL,
			Duracion            INT               NULL,
			Costo               DECIMAL(12,2)     NOT NULL,
			CupoMaximo          INT               NULL,

			CONSTRAINT PK_Actividad PRIMARY KEY (ID),
			CONSTRAINT FK_Actividad_AreaProtegida FOREIGN KEY (ID_AreaProtegida) REFERENCES parque.AreaProtegida(ID),
			CONSTRAINT FK_Actividad_TipoActividad FOREIGN KEY (ID_TipoActividad) REFERENCES actividad.TipoActividad(ID)
		);
		PRINT('OK: tabla Actividad creada exitosamente');
	END
ELSE PRINT('INFO: tabla Actividad ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'InscripcionActividad' AND schema_id = SCHEMA_ID('actividad'))
	BEGIN
		CREATE TABLE actividad.InscripcionActividad (
			ID              INT IDENTITY(1,1)   NOT NULL,
			ID_Actividad    INT                 NOT NULL,
			ID_Comprobante  INT                 NULL,
			FechaHora       DATETIME            NULL,
			PrecioCobrado   DECIMAL(12,2)       NULL,

			CONSTRAINT PK_InscripcionActividad PRIMARY KEY (ID),
			CONSTRAINT FK_InscripcionActividad_Actividad FOREIGN KEY (ID_Actividad) REFERENCES actividad.Actividad(ID),
			CONSTRAINT FK_InscripcionActividad_Comprobante FOREIGN KEY (ID_Comprobante) REFERENCES venta.Comprobante(ID)
		);
		PRINT('OK: tabla InscripcionActividad creada exitosamente');
	END
ELSE PRINT('INFO: tabla InscripcionActividad ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'GuiaAsignadoTour' AND schema_id = SCHEMA_ID('actividad'))
	BEGIN
		CREATE TABLE actividad.GuiaAsignadoTour (
			ID_Actividad        INT     NOT NULL,
			CUIL_GuiaAutorizado BIGINT  NOT NULL,

			CONSTRAINT PK_GuiaAsignadoTour PRIMARY KEY (ID_Actividad, CUIL_GuiaAutorizado),
			CONSTRAINT FK_GuiaAsignadoTour_Actividad FOREIGN KEY (ID_Actividad) REFERENCES actividad.Actividad(ID),
			CONSTRAINT FK_GuiaAsignadoTour_GuiaAutorizado FOREIGN KEY (CUIL_GuiaAutorizado) REFERENCES personal.GuiaAutorizado(CUIL)
		);
		PRINT('OK: tabla GuiaAsignadoTour creada exitosamente');
	END
ELSE PRINT('INFO: tabla GuiaAsignadoTour ya existe')

-- PROCEDIMIENTOS ALMACENADOS ABM: TIPO ACTIVIDAD

CREATE OR ALTER PROCEDURE [actividad].[SP_TipoActividad_Insert]
	@Nombre VARCHAR(50)
AS
	INSERT INTO [actividad].[TipoActividad](Nombre)
	VALUES(@Nombre)
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_TipoActividad_Update]
	@ID     INT,
	@Nombre VARCHAR(50) = NULL
AS
	UPDATE [actividad].[TipoActividad]
	SET Nombre = ISNULL(@Nombre, Nombre)
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_TipoActividad_Delete]
	@ID INT
AS
	DELETE FROM [actividad].[TipoActividad]
	WHERE ID = @ID
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: ACTIVIDAD

CREATE OR ALTER PROCEDURE [actividad].[SP_Actividad_Insert]
	@ID_AreaProtegida BIGINT,
	@ID_TipoActividad INT,
	@Nombre           VARCHAR(50),
	@Duracion         INT          = NULL,
	@Costo            DECIMAL(12,2),
	@CupoMaximo       INT          = NULL
AS
	INSERT INTO [actividad].[Actividad](ID_AreaProtegida, ID_TipoActividad, Nombre, Duracion, Costo, CupoMaximo)
	VALUES(@ID_AreaProtegida, @ID_TipoActividad, @Nombre, @Duracion, @Costo, @CupoMaximo)
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_Actividad_Update]
	@ID                 INT,
	@ID_AreaProtegida   BIGINT         = NULL,
	@ID_TipoActividad   INT            = NULL,
	@Nombre             VARCHAR(50)    = NULL,
	@Duracion           INT            = NULL,
	@Costo              DECIMAL(12,2)  = NULL,
	@CupoMaximo         INT            = NULL
AS
	UPDATE [actividad].[Actividad]
	SET
		ID_AreaProtegida = ISNULL(@ID_AreaProtegida, ID_AreaProtegida),
		ID_TipoActividad = ISNULL(@ID_TipoActividad, ID_TipoActividad),
		Nombre           = ISNULL(@Nombre, Nombre),
		Duracion         = CASE WHEN @Duracion = -1 THEN NULL ELSE ISNULL(@Duracion, Duracion) END,
		Costo            = ISNULL(@Costo, Costo),
		CupoMaximo       = CASE WHEN @CupoMaximo = -1 THEN NULL ELSE ISNULL(@CupoMaximo, CupoMaximo) END
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_Actividad_Delete]
	@ID INT
AS
	DELETE FROM [actividad].[Actividad]
	WHERE ID = @ID
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: INSCRIPCION ACTIVIDAD

CREATE OR ALTER PROCEDURE [actividad].[SP_InscripcionActividad_Insert]
	@ID_Actividad    INT,
	@ID_Comprobante  INT        = NULL,
	@FechaHora       DATETIME   = NULL,
	@PrecioCobrado   DECIMAL(12,2) = NULL
AS
	INSERT INTO [actividad].[InscripcionActividad](ID_Actividad, ID_Comprobante, FechaHora, PrecioCobrado)
	VALUES(@ID_Actividad, @ID_Comprobante, @FechaHora, @PrecioCobrado)
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_InscripcionActividad_Update]
	@ID                INT,
	@ID_Actividad      INT            = NULL,
	@ID_Comprobante    INT            = NULL,
	@FechaHora         DATETIME       = NULL,
	@PrecioCobrado     DECIMAL(12,2)  = NULL
AS
	UPDATE [actividad].[InscripcionActividad]
	SET
		ID_Actividad   = ISNULL(@ID_Actividad, ID_Actividad),
		ID_Comprobante = CASE WHEN @ID_Comprobante = -1 THEN NULL ELSE ISNULL(@ID_Comprobante, ID_Comprobante) END,
		FechaHora      = CASE WHEN @FechaHora = '1900-01-01' THEN NULL ELSE ISNULL(@FechaHora, FechaHora) END,
		PrecioCobrado  = CASE WHEN @PrecioCobrado = -1 THEN NULL ELSE ISNULL(@PrecioCobrado, PrecioCobrado) END
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_InscripcionActividad_Delete]
	@ID INT
AS
	DELETE FROM [actividad].[InscripcionActividad]
	WHERE ID = @ID
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: GUIA ASIGNADO TOUR

CREATE OR ALTER PROCEDURE [actividad].[SP_GuiaAsignadoTour_Insert]
	@ID_Actividad        INT,
	@CUIL_GuiaAutorizado BIGINT
AS
	INSERT INTO [actividad].[GuiaAsignadoTour](ID_Actividad, CUIL_GuiaAutorizado)
	VALUES(@ID_Actividad, @CUIL_GuiaAutorizado)
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_GuiaAsignadoTour_Delete]
	@ID_Actividad        INT,
	@CUIL_GuiaAutorizado BIGINT
AS
	DELETE FROM [actividad].[GuiaAsignadoTour]
	WHERE ID_Actividad = @ID_Actividad AND CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
GO