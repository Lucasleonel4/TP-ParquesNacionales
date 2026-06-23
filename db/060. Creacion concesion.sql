/*
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Script: 060. Creacion concesion
* Descripción: Crea el esquema concesion y sus tablas
*/

USE com2900;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'concesion')
	BEGIN TRY
		EXEC('CREATE SCHEMA concesion')
		PRINT('OK: esquema concesion creado exitosamente')
	END TRY
	BEGIN CATCH
		PRINT('ERROR: No se pudo crear el esquema concesion')
		RETURN
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
ELSE PRINT('INFO: tabla ActividadFiscal ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Empresa' AND schema_id = SCHEMA_ID('concesion'))
	BEGIN
		CREATE TABLE concesion.Empresa (
			CUIT    BIGINT       NOT NULL,
			Nombre  VARCHAR(150) NULL,

			CONSTRAINT PK_Empresa PRIMARY KEY (CUIT)
		);
		PRINT('OK: tabla Empresa creada exitosamente');
	END
ELSE PRINT('INFO: tabla Empresa ya existe')

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
ELSE PRINT('INFO: tabla TipoConcesion ya existe')

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
ELSE PRINT('INFO: tabla ActividadFiscalInscriptaEmpresa ya existe')

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
ELSE PRINT('INFO: tabla Concesion ya existe')

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
ELSE PRINT('INFO: tabla FacturaConcesion ya existe')

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
ELSE PRINT('INFO: tabla PagoConcesion ya existe')