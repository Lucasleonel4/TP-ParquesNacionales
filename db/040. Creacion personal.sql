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
 * Script: 040. Creacion personal
 * Descripción: Crea el esquema personal, sus tablas y los procedimientos almacenados ABM para todas las tablas del esquema
*/

USE com2900;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'personal')
	BEGIN TRY
		EXEC('CREATE SCHEMA personal')
		PRINT('OK: esquema personal creado exitosamente');
	END TRY
	BEGIN CATCH
		PRINT('ERROR: No se pudo crear el esquema personal');
		RETURN
	END CATCH
ELSE PRINT ('INFO: el esquema personal ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'GuiaAutorizado' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.GuiaAutorizado (
			CUIL        BIGINT          NOT NULL,
			Nombre      VARCHAR(100)    NOT NULL,
			Apellido    VARCHAR(100)    NOT NULL,
			Autorizado  BIT             NOT NULL,

			CONSTRAINT PK_GuiaAutorizado PRIMARY KEY (CUIL)
		);
		PRINT('OK: tabla GuiaAutorizado creada exitosamente');
	END
ELSE PRINT('INFO: tabla GuiaAutorizado ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TituloAcademico' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.TituloAcademico (
			ID              INT IDENTITY(1,1)   NOT NULL,
			Nombre          VARCHAR(100)        NOT NULL,
			Entidad_Otorga  VARCHAR(100)        NOT NULL,
			Tipo            VARCHAR(50)         NOT NULL,
			Area            VARCHAR(50)         NOT NULL,

			CONSTRAINT PK_TituloAcademico PRIMARY KEY (ID),
			CONSTRAINT UQ_TituloAcademico_Nombre_Entidad UNIQUE (Nombre, Entidad_Otorga)
		);
		PRINT('OK: tabla TituloAcademico creada exitosamente');
	END
ELSE PRINT('INFO: tabla TituloAcademico ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HabilitacionGuia' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.HabilitacionGuia (
			ID          INT IDENTITY(1,1)   NOT NULL,
			Nombre      VARCHAR(50)         NOT NULL,
			Descripcion VARCHAR(200)        NOT NULL,

			CONSTRAINT PK_HabilitacionGuia PRIMARY KEY (ID)
		);
		PRINT('OK: tabla HabilitacionGuia creada exitosamente');
	END
ELSE PRINT('INFO: tabla HabilitacionGuia ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'EspecialidadGuia' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.EspecialidadGuia (
			ID          INT IDENTITY(1,1)   NOT NULL,
			Nombre      VARCHAR(100)        NOT NULL,
			Descripcion VARCHAR(200)        NOT NULL,

			CONSTRAINT PK_EspecialidadGuia PRIMARY KEY (ID)
		);
		PRINT('OK: tabla EspecialidadGuia creada exitosamente');
	END
ELSE PRINT('INFO: tabla EspecialidadGuia ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'GuiaConTitulo' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.GuiaConTitulo (
			CUIL_GuiaAutorizado BIGINT  NOT NULL,
			ID_TituloAcademico  INT     NOT NULL,
			FechaObtenido       DATE    NOT NULL,

			CONSTRAINT PK_GuiaConTitulo PRIMARY KEY (CUIL_GuiaAutorizado, ID_TituloAcademico),
			CONSTRAINT FK_GuiaConTitulo_Guia FOREIGN KEY (CUIL_GuiaAutorizado) REFERENCES personal.GuiaAutorizado(CUIL),
			CONSTRAINT FK_GuiaConTitulo_Titulo FOREIGN KEY (ID_TituloAcademico) REFERENCES personal.TituloAcademico(ID)
		);
		PRINT('OK: tabla GuiaConTitulo creada exitosamente');
	END
ELSE PRINT('INFO: tabla GuiaConTitulo ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'GuiaConHabilitacion' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.GuiaConHabilitacion (
			CUIL_GuiaAutorizado     BIGINT  NOT NULL,
			ID_HabilitacionGuia     INT     NOT NULL,
			FechaObtenido           DATE    NOT NULL,
			FechaExpiracion         DATE    NOT NULL,

			CONSTRAINT PK_GuiaConHabilitacion PRIMARY KEY (CUIL_GuiaAutorizado, ID_HabilitacionGuia),
			CONSTRAINT FK_GuiaConHabilitacion_Guia FOREIGN KEY (CUIL_GuiaAutorizado) REFERENCES personal.GuiaAutorizado(CUIL),
			CONSTRAINT FK_GuiaConHabilitacion_Habilitacion FOREIGN KEY (ID_HabilitacionGuia) REFERENCES personal.HabilitacionGuia(ID)
		);
		PRINT('OK: tabla GuiaConHabilitacion creada exitosamente');
	END
ELSE PRINT('INFO: tabla GuiaConHabilitacion ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'GuiaConEspecialidad' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.GuiaConEspecialidad (
			CUIL_GuiaAutorizado BIGINT  NOT NULL,
			ID_EspecialidadGuia INT     NOT NULL,
			FechaObtenida       DATE    NOT NULL,

			CONSTRAINT PK_GuiaConEspecialidad PRIMARY KEY (CUIL_GuiaAutorizado, ID_EspecialidadGuia),
			CONSTRAINT FK_GuiaConEspecialidad_Guia FOREIGN KEY (CUIL_GuiaAutorizado) REFERENCES personal.GuiaAutorizado(CUIL),
			CONSTRAINT FK_GuiaConEspecialidad_Especialidad FOREIGN KEY (ID_EspecialidadGuia) REFERENCES personal.EspecialidadGuia(ID)
		);
		PRINT('OK: tabla GuiaConEspecialidad creada exitosamente');
	END
ELSE PRINT('INFO: tabla GuiaConEspecialidad ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Guardaparques' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.Guardaparques (
			CUIL            BIGINT       NOT NULL,
			Nombre          VARCHAR(100) NOT NULL,
			Apellido        VARCHAR(100) NOT NULL,
			FechaNacimiento DATE         NOT NULL,
			FechaIngreso    DATE         NOT NULL,
			FechaEgreso     DATE         NULL,
			MotivoEgreso    VARCHAR(255) NULL,

			CONSTRAINT PK_Guardaparques PRIMARY KEY (CUIL)
		);
		PRINT('OK: tabla Guardaparques creada exitosamente');
	END
ELSE PRINT('INFO: tabla Guardaparques ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ContratoTrabajo' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.ContratoTrabajo (
			ID                  INT IDENTITY(1,1)   NOT NULL,
			ID_AreaProtegida    BIGINT              NOT NULL,
			CUIL_Guardaparques  BIGINT              NOT NULL,
			FechaInicio         DATE                NOT NULL,
			FechaFin            DATE                NULL,

			CONSTRAINT PK_ContratoTrabajo PRIMARY KEY (ID),
			CONSTRAINT FK_ContratoTrabajo_Parque FOREIGN KEY (ID_AreaProtegida) REFERENCES parque.AreaProtegida(ID),
			CONSTRAINT FK_ContratoTrabajo_Guardaparques FOREIGN KEY (CUIL_Guardaparques) REFERENCES personal.Guardaparques(CUIL)
		);
		PRINT('OK: tabla ContratoTrabajo creada exitosamente');
	END
ELSE PRINT('INFO: tabla ContratoTrabajo ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PermisoDeTrabajo' AND schema_id = SCHEMA_ID('personal'))
	BEGIN
		CREATE TABLE personal.PermisoDeTrabajo (
			ID                  INT IDENTITY(1,1)   NOT NULL,
			ID_AreaProtegida    BIGINT              NOT NULL,
			CUIL_GuiaAutorizado BIGINT              NOT NULL,
			FechaInicio         DATE                NOT NULL,
			FechaFin            DATE                NULL,

			CONSTRAINT PK_PermisoDeTrabajo PRIMARY KEY (ID),
			CONSTRAINT FK_PermisoDeTrabajo_Parque FOREIGN KEY (ID_AreaProtegida) REFERENCES parque.AreaProtegida(ID),
			CONSTRAINT FK_PermisoDeTrabajo_Guia FOREIGN KEY (CUIL_GuiaAutorizado) REFERENCES personal.GuiaAutorizado(CUIL)
		);
		PRINT('OK: tabla PermisoDeTrabajo creada exitosamente');
	END
ELSE PRINT('INFO: tabla PermisoDeTrabajo ya existe');

-- PROCEDIMIENTOS ALMACENADOS ABM: GUIA AUTORIZADO
GO
CREATE OR ALTER PROCEDURE [personal].[GuiaAutorizadoAlta]
	@CUIL		BIGINT,
	@Nombre		VARCHAR(100),
	@Apellido	VARCHAR(100),
	@Autorizado BIT
AS
	INSERT INTO [personal].[GuiaAutorizado](CUIL, Nombre, Apellido, Autorizado)
	VALUES (@CUIL, @Nombre, @Apellido, @Autorizado)
GO

CREATE OR ALTER PROCEDURE [personal].[GuiaAutorizadoModificacion]
	@CUIL		BIGINT,
	@Nombre		VARCHAR(100) = NULL,
	@Apellido	VARCHAR(100) = NULL,
	@Autorizado BIT			 = NULL
AS
UPDATE [personal].[GuiaAutorizado]
SET
	Nombre		= ISNULL(@Nombre, Nombre),
	Apellido	= ISNULL(@Apellido, Apellido),
	Autorizado	= ISNULL(@Autorizado, Autorizado)
WHERE CUIL = @CUIL
GO

CREATE OR ALTER PROCEDURE [personal].[GuiaAutorizadoBaja]
	@CUIL BIGINT
AS
	DELETE FROM [personal].[GuiaAutorizado]
	WHERE CUIL = @CUIL
GO

CREATE OR ALTER PROCEDURE [personal].[GuiaAutorizadoConsulta]
	@CUIL BIGINT = NULL
AS
	SELECT * FROM [personal].[GuiaAutorizado]
	WHERE CUIL = COALESCE(@CUIL,CUIL)
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: TITULO ACADEMICO

CREATE OR ALTER PROCEDURE [personal].[TituloAcademicoAlta]
	@Nombre          VARCHAR(100),
	@Entidad_Otorga  VARCHAR(100),
	@Tipo			 VARCHAR(50),
	@Area			 VARCHAR(50)
AS
	INSERT INTO [personal].[TituloAcademico](Nombre, Entidad_Otorga, Tipo, Area)
	VALUES (@Nombre, @Entidad_Otorga, @Tipo, @Area)
GO

CREATE OR ALTER PROCEDURE [personal].[TituloAcademicoModificacion]
	@ID				 INT,
	@Nombre          VARCHAR(100) = NULL,
	@Entidad_Otorga  VARCHAR(100) = NULL,
	@Tipo			 VARCHAR(50)  = NULL,
	@Area			 VARCHAR(50)  = NULL
AS
	UPDATE [personal].[TituloAcademico]
	SET
		Nombre			= ISNULL(@Nombre,Nombre),
		Entidad_Otorga	= ISNULL(@Entidad_Otorga,Entidad_Otorga),
		Tipo			= ISNULL(@Tipo, Tipo),
		Area			= ISNULL(@Area, Area)
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [personal].[TituloAcademicoBaja]
	@ID INT
AS
	DELETE FROM [personal].[TituloAcademico]
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [personal].[TituloAcademicoConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [personal].[TituloAcademico]
	WHERE ID = COALESCE(@ID, ID)
GO


-- PROCEDIMIENTOS ALMACENADOS ABM: HABILITACION

CREATE OR ALTER PROCEDURE [personal].[HabilitacionGuiaAlta]
	@Nombre      VARCHAR(50),
	@Descripcion VARCHAR(200)
AS
	INSERT INTO [personal].[HabilitacionGuia](Nombre, Descripcion)
	VALUES (@Nombre, @Descripcion)

GO

CREATE OR ALTER PROCEDURE [personal].[HabilitacionGuiaModificacion]
	@ID          INT,
	@Nombre      VARCHAR(50)	= NULL,
	@Descripcion VARCHAR(200)	= NULL 
AS
	UPDATE [personal].[HabilitacionGuia]
	SET 
		Nombre		= ISNULL(@Nombre, Nombre),
		Descripcion	= ISNULL(@Descripcion, Descripcion)
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [personal].[HabilitacionGuiaBaja]
	@ID INT
AS
	DELETE FROM [personal].[HabilitacionGuia]
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [personal].[HabilitacionGuiaConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [personal].[HabilitacionGuia]
	WHERE ID = COALESCE(@ID,ID)
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: ESPECIALIDAD

CREATE OR ALTER PROCEDURE [personal].[EspecialidadGuiaAlta]
	@Nombre      VARCHAR(100),
	@Descripcion VARCHAR(200)
AS
	INSERT INTO [personal].[EspecialidadGuia](Nombre, Descripcion)
	VALUES(@Nombre, @Descripcion)
GO

CREATE OR ALTER PROCEDURE [personal].[EspecialidadGuiaModificacion]
	@ID          INT,
	@Nombre      VARCHAR(100)        = NULL,
	@Descripcion VARCHAR(200)        = NULL
AS
	UPDATE [personal].[EspecialidadGuia]
	SET
		Nombre		= ISNULL(@Nombre, Nombre),
		Descripcion	= ISNULL(@Descripcion, Descripcion)
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [personal].[EspecialidadGuiaBaja]
	@ID INT
AS
	DELETE FROM [personal].[EspecialidadGuia]
	WHERE ID = @ID
GO

CREATE OR ALTER PROCEDURE [personal].[EspecialidadGuiaConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [personal].[EspecialidadGuia]
	WHERE ID = COALESCE(@ID, ID)
GO

-- ========================================
-- GUIA CON TITULO OPERACIONES
-- ========================================

-- GUIA CON TITULO: INSERT
CREATE OR ALTER PROCEDURE [personal].[GuiaConTituloAlta]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_TituloAcademico  INT,
	@FechaObtenido       DATE
AS
BEGIN
	BEGIN TRY
		INSERT INTO [personal].[GuiaConTitulo](CUIL_GuiaAutorizado, ID_TituloAcademico, FechaObtenido)
		VALUES (@CUIL_GuiaAutorizado, @ID_TituloAcademico, @FechaObtenido)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON TITULO: UPDATE
CREATE OR ALTER PROCEDURE [personal].[GuiaConTituloModificacion]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_TituloAcademico  INT,
	@FechaObtenido       DATE = NULL
AS
BEGIN
	BEGIN TRY
		UPDATE [personal].[GuiaConTitulo]
		SET
			FechaObtenido = ISNULL(@FechaObtenido, FechaObtenido)
		WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
		  AND ID_TituloAcademico  = @ID_TituloAcademico
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON TITULO: DELETE
CREATE OR ALTER PROCEDURE [personal].[GuiaConTituloBaja]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_TituloAcademico  INT
AS
BEGIN
	BEGIN TRY
		DELETE FROM [personal].[GuiaConTitulo]
		WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
		  AND ID_TituloAcademico  = @ID_TituloAcademico
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON TITULO: CONSULTA
CREATE OR ALTER PROCEDURE [personal].[GuiaConTituloConsulta]
	@CUIL_GuiaAutorizado BIGINT = NULL
AS
	SELECT * FROM [personal].[GuiaConTitulo]
	WHERE CUIL_GuiaAutorizado = COALESCE(@CUIL_GuiaAutorizado, CUIL_GuiaAutorizado)
GO

-- ========================================
-- GUIA CON HABILITACION OPERACIONES
-- ========================================

-- GUIA CON HABILITACION: INSERT
CREATE OR ALTER PROCEDURE [personal].[GuiaConHabilitacionAlta]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_HabilitacionGuia INT,
	@FechaObtenido       DATE,
	@FechaExpiracion     DATE
AS
BEGIN
	BEGIN TRY
		INSERT INTO [personal].[GuiaConHabilitacion](CUIL_GuiaAutorizado, ID_HabilitacionGuia, FechaObtenido, FechaExpiracion)
		VALUES (@CUIL_GuiaAutorizado, @ID_HabilitacionGuia, @FechaObtenido, @FechaExpiracion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON HABILITACION: UPDATE
CREATE OR ALTER PROCEDURE [personal].[GuiaConHabilitacionModificacion]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_HabilitacionGuia INT,
	@FechaObtenido       DATE = NULL,
	@FechaExpiracion     DATE = NULL
AS
BEGIN
	BEGIN TRY
		UPDATE [personal].[GuiaConHabilitacion]
		SET
			FechaObtenido   = ISNULL(@FechaObtenido, FechaObtenido),
			FechaExpiracion = ISNULL(@FechaExpiracion, FechaExpiracion)
		WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
		  AND ID_HabilitacionGuia = @ID_HabilitacionGuia
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON HABILITACION: DELETE
CREATE OR ALTER PROCEDURE [personal].[GuiaConHabilitacionBaja]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_HabilitacionGuia INT
AS
BEGIN
	BEGIN TRY
		DELETE FROM [personal].[GuiaConHabilitacion]
		WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
		  AND ID_HabilitacionGuia = @ID_HabilitacionGuia
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON HABILITACIÓN: CONSULTA
CREATE OR ALTER PROCEDURE [personal].[GuiaConHabilitacionConsulta]
	@CUIL_GuiaAutorizado BIGINT = NULL
AS
	SELECT * FROM [personal].[GuiaConHabilitacion]
	WHERE CUIL_GuiaAutorizado = COALESCE(@CUIL_GuiaAutorizado, CUIL_GuiaAutorizado)
GO


-- ========================================
-- GUIA CON ESPECIALIDAD OPERACIONES
-- ========================================

-- GUIA CON ESPECIALIDAD: INSERT
CREATE OR ALTER PROCEDURE [personal].[GuiaConEspecialidadAlta]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_EspecialidadGuia INT,
	@FechaObtenida       DATE
AS
BEGIN
	BEGIN TRY
		INSERT INTO [personal].[GuiaConEspecialidad](CUIL_GuiaAutorizado, ID_EspecialidadGuia, FechaObtenida)
		VALUES (@CUIL_GuiaAutorizado, @ID_EspecialidadGuia, @FechaObtenida)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON ESPECIALIDAD: UPDATE
CREATE OR ALTER PROCEDURE [personal].[GuiaConEspecialidadModificacion]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_EspecialidadGuia INT,
	@FechaObtenida       DATE = NULL
AS
BEGIN
	BEGIN TRY
		UPDATE [personal].[GuiaConEspecialidad]
		SET
			FechaObtenida = ISNULL(@FechaObtenida, FechaObtenida)
		WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
		  AND ID_EspecialidadGuia = @ID_EspecialidadGuia
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON ESPECIALIDAD: DELETE
CREATE OR ALTER PROCEDURE [personal].[GuiaConEspecialidadBaja]
	@CUIL_GuiaAutorizado BIGINT,
	@ID_EspecialidadGuia INT
AS
BEGIN
	BEGIN TRY
		DELETE FROM [personal].[GuiaConEspecialidad]
		WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
		  AND ID_EspecialidadGuia = @ID_EspecialidadGuia
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUIA CON ESPECIALIDAD: CONSULTA
CREATE OR ALTER PROCEDURE [personal].[GuiaConEspecialidadConsulta]
	@CUIL_GuiaAutorizado BIGINT = NULL
AS
	SELECT * FROM [personal].[GuiaConEspecialidad]
	WHERE CUIL_GuiaAutorizado = COALESCE(@CUIL_GuiaAutorizado,CUIL_GuiaAutorizado)
GO


-- ========================================
-- GUARDAPARQUES OPERACIONES
-- ========================================

-- GUARDAPARQUES: INSERT
CREATE OR ALTER PROCEDURE [personal].[GuardaparquesAlta]
	@CUIL            BIGINT,
	@Nombre          VARCHAR(100),
	@Apellido        VARCHAR(100),
	@FechaNacimiento DATE,
	@FechaIngreso    DATE,
	@FechaEgreso     DATE         = NULL,
	@MotivoEgreso    VARCHAR(255) = NULL
AS
BEGIN
	BEGIN TRY
		INSERT INTO [personal].[Guardaparques](CUIL, Nombre, Apellido, FechaNacimiento, FechaIngreso, FechaEgreso, MotivoEgreso)
		VALUES (@CUIL, @Nombre, @Apellido, @FechaNacimiento, @FechaIngreso, @FechaEgreso, @MotivoEgreso)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUARDAPARQUES: UPDATE
CREATE OR ALTER PROCEDURE [personal].[GuardaparquesModificacion]
	@CUIL            BIGINT       = NULL,
	@Nombre          VARCHAR(100) = NULL,
	@Apellido        VARCHAR(100) = NULL,
	@FechaNacimiento DATE         = NULL,
	@FechaIngreso    DATE         = NULL,
	@FechaEgreso     DATE         = NULL,
	@MotivoEgreso    VARCHAR(255) = NULL
AS
BEGIN
	BEGIN TRY
		UPDATE [personal].[Guardaparques]
		SET
			Nombre          = ISNULL(@Nombre, Nombre),
			Apellido        = ISNULL(@Apellido, Apellido),
			FechaNacimiento = ISNULL(@FechaNacimiento, FechaNacimiento),
			FechaIngreso    = ISNULL(@FechaIngreso, FechaIngreso),
			FechaEgreso     = ISNULL(@FechaEgreso, FechaEgreso),
			MotivoEgreso    = ISNULL(@MotivoEgreso, MotivoEgreso)
		WHERE CUIL = @CUIL
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUARDAPARQUES: DELETE
CREATE OR ALTER PROCEDURE [personal].[GuardaparquesBaja]
	@CUIL BIGINT
AS
BEGIN
	BEGIN TRY
		DELETE FROM [personal].[Guardaparques]
		WHERE CUIL = @CUIL
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- GUARDAPARQUES: CONSULTA
CREATE OR ALTER PROCEDURE [personal].[GuardaparquesConsulta]
	@CUIL BIGINT = NULL
AS
	SELECT * FROM [personal].[Guardaparques]
	WHERE CUIL = COALESCE(@CUIL,CUIL)
GO


-- ========================================
-- CONTRATO TRABAJO OPERACIONES
-- ========================================

-- CONTRATO TRABAJO: INSERT
CREATE OR ALTER PROCEDURE [personal].[ContratoTrabajoAlta]
	@ID_AreaProtegida  BIGINT,
	@CUIL_Guardaparques BIGINT,
	@FechaInicio       DATE,
	@FechaFin          DATE = NULL
AS
BEGIN
	BEGIN TRY
		INSERT INTO [personal].[ContratoTrabajo](ID_AreaProtegida, CUIL_Guardaparques, FechaInicio, FechaFin)
		VALUES (@ID_AreaProtegida, @CUIL_Guardaparques, @FechaInicio, @FechaFin)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- CONTRATO TRABAJO: UPDATE
CREATE OR ALTER PROCEDURE [personal].[ContratoTrabajoModificacion]
	@ID                  INT          = NULL,
	@ID_AreaProtegida    BIGINT       = NULL,
	@CUIL_Guardaparques  BIGINT       = NULL,
	@FechaInicio         DATE         = NULL,
	@FechaFin            DATE         = NULL
AS
BEGIN
	BEGIN TRY
		UPDATE [personal].[ContratoTrabajo]
		SET
			ID_AreaProtegida   = ISNULL(@ID_AreaProtegida, ID_AreaProtegida),
			CUIL_Guardaparques = ISNULL(@CUIL_Guardaparques, CUIL_Guardaparques),
			FechaInicio        = ISNULL(@FechaInicio, FechaInicio),
			FechaFin           = ISNULL(@FechaFin, FechaFin)
		WHERE ID = @ID
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- CONTRATO TRABAJO: DELETE
CREATE OR ALTER PROCEDURE [personal].[ContratoTrabajoBaja]
	@ID INT
AS
BEGIN
	BEGIN TRY
		DELETE FROM [personal].[ContratoTrabajo]
		WHERE ID = @ID
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- CONTRATO DE TRABAJO: CONSULTA
CREATE OR ALTER PROCEDURE [personal].[ContratoTrabajoConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [personal].[ContratoTrabajo]
	WHERE ID = COALESCE(@ID, ID)
GO

-- ========================================
-- PERMISO DE TRABAJO OPERACIONES
-- ========================================

-- PERMISO DE TRABAJO: INSERT
CREATE OR ALTER PROCEDURE [personal].[PermisoDeTrabajoAlta]
	@ID_AreaProtegida    BIGINT,
	@CUIL_GuiaAutorizado BIGINT,
	@FechaInicio         DATE,
	@FechaFin            DATE = NULL
AS
BEGIN
	BEGIN TRY
		INSERT INTO [personal].[PermisoDeTrabajo](ID_AreaProtegida, CUIL_GuiaAutorizado, FechaInicio, FechaFin)
		VALUES (@ID_AreaProtegida, @CUIL_GuiaAutorizado, @FechaInicio, @FechaFin)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- PERMISO DE TRABAJO: UPDATE
CREATE OR ALTER PROCEDURE [personal].[PermisoDeTrabajoModificacion]
	@ID                    INT          = NULL,
	@ID_AreaProtegida      BIGINT       = NULL,
	@CUIL_GuiaAutorizado   BIGINT       = NULL,
	@FechaInicio           DATE         = NULL,
	@FechaFin              DATE         = NULL
AS
BEGIN
	BEGIN TRY
		UPDATE [personal].[PermisoDeTrabajo]
		SET
			ID_AreaProtegida    = ISNULL(@ID_AreaProtegida, ID_AreaProtegida),
			CUIL_GuiaAutorizado = ISNULL(@CUIL_GuiaAutorizado, CUIL_GuiaAutorizado),
			FechaInicio         = ISNULL(@FechaInicio, FechaInicio),
			FechaFin            = ISNULL(@FechaFin, FechaFin)
		WHERE ID = @ID
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- PERMISO DE TRABAJO: DELETE
CREATE OR ALTER PROCEDURE [personal].[PermisoDeTrabajoBaja]
	@ID INT
AS
BEGIN
	BEGIN TRY
		DELETE FROM [personal].[PermisoDeTrabajo]
		WHERE ID = @ID
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- PERMISO DE TRABAJO: CONSULTA
CREATE OR ALTER PROCEDURE [personal].[PermisoDeTrabajoConsulta]
	@ID INT = NULL
AS
	SELECT * FROM [personal].[PermisoDeTrabajo]
	WHERE ID = COALESCE(@ID, ID)
GO
