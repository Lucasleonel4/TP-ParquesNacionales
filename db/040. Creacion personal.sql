/*
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Script: 040. Creacion personal
* Descripción: Crea el esquema personal y sus tablas
*/

USE com2900;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'personal')
	BEGIN TRY
		EXEC('CREATE SCHEMA personal')
		PRINT('OK: esquema personal creado exitosamente')
	END TRY
	BEGIN CATCH
		PRINT('ERROR: No se pudo crear el esquema personal')
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
ELSE PRINT('INFO: tabla GuiaAutorizado ya existe')

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
ELSE PRINT('INFO: tabla TituloAcademico ya existe')

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
ELSE PRINT('INFO: tabla HabilitacionGuia ya existe')

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
ELSE PRINT('INFO: tabla EspecialidadGuia ya existe')

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
ELSE PRINT('INFO: tabla GuiaConTitulo ya existe')

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
ELSE PRINT('INFO: tabla GuiaConHabilitacion ya existe')

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
ELSE PRINT('INFO: tabla GuiaConEspecialidad ya existe')

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
ELSE PRINT('INFO: tabla Guardaparques ya existe')

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
ELSE PRINT('INFO: tabla ContratoTrabajo ya existe')

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
ELSE PRINT('INFO: tabla PermisoDeTrabajo ya existe')