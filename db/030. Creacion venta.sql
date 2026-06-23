/*
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Script: 030. Creacion venta
* Descripción: Crea el esquema venta y sus tablas
*/

USE com2900;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'venta')
	BEGIN TRY
		EXEC('CREATE SCHEMA venta')
		PRINT('OK: esquema venta creado exitosamente')
	END TRY
	BEGIN CATCH
		PRINT('ERROR: No se pudo crear el esquema venta')
		RETURN
	END CATCH
ELSE PRINT ('INFO: el esquema venta ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Divisa' AND schema_id = SCHEMA_ID('venta'))
	BEGIN
		CREATE TABLE venta.Divisa (
			COD_ISO         CHAR(3)         NOT NULL,
			Pais            VARCHAR(50)     NULL,
			ValorEnPesos    DECIMAL(12,3)   NULL,

			CONSTRAINT PK_Divisa PRIMARY KEY (COD_ISO)
		);
		PRINT('OK: tabla Divisa creada exitosamente');
	END
ELSE PRINT('INFO: tabla Divisa ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoEntrada' AND schema_id = SCHEMA_ID('venta'))
	BEGIN
		CREATE TABLE venta.TipoEntrada (
			ID      INT IDENTITY(1,1)   NOT NULL,
			Nombre  VARCHAR(100)        NOT NULL,

			CONSTRAINT PK_TipoEntrada PRIMARY KEY (ID)
		);
		PRINT('OK: tabla TipoEntrada creada exitosamente');
	END
ELSE PRINT('INFO: tabla TipoEntrada ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoEntradaParque' AND schema_id = SCHEMA_ID('venta'))
	BEGIN
		CREATE TABLE venta.TipoEntradaParque (
			ID                  INT IDENTITY(1,1) NOT NULL,
			ID_AreaProtegida    BIGINT            NOT NULL,
			ID_TipoEntrada      INT               NOT NULL,
			Precio              DECIMAL(12,2)     NOT NULL,

			CONSTRAINT PK_TipoEntradaParque PRIMARY KEY (ID),
			CONSTRAINT UQ_TipoEntradaParque_Parque_Tipo UNIQUE (ID_AreaProtegida, ID_TipoEntrada),
			CONSTRAINT FK_TipoEntradaParque_AreaProtegida FOREIGN KEY (ID_AreaProtegida) REFERENCES parque.AreaProtegida(ID),
			CONSTRAINT FK_TipoEntradaParque_TipoEntrada FOREIGN KEY (ID_TipoEntrada) REFERENCES venta.TipoEntrada(ID)
		);
		PRINT('OK: tabla TipoEntradaParque creada exitosamente');
	END
ELSE PRINT('INFO: tabla TipoEntradaParque ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Comprobante' AND schema_id = SCHEMA_ID('venta'))
	BEGIN
		CREATE TABLE venta.Comprobante (
			ID              INT IDENTITY(1,1)   NOT NULL,
			ID_PuntoDeVenta INT                 NOT NULL,
			COD_ISO_Divisa  CHAR(3)             NOT NULL,
			MedioDePago     VARCHAR(20)         NOT NULL,
			FechaHora       DATETIME            NOT NULL,
			Total           DECIMAL(12,2)       NOT NULL,

			CONSTRAINT PK_Comprobante PRIMARY KEY (ID),
			CONSTRAINT CK_Comprobante_MedioDePago CHECK (MedioDePago IN ('Efectivo', 'Tarjeta', 'Transferencia')),
			CONSTRAINT FK_Comprobante_PuntoDeVenta FOREIGN KEY (ID_PuntoDeVenta) REFERENCES parque.PuntoDeVenta(ID),
			CONSTRAINT FK_Comprobante_Divisa FOREIGN KEY (COD_ISO_Divisa) REFERENCES venta.Divisa(COD_ISO)
		);
		PRINT('OK: tabla Comprobante creada exitosamente');
	END
ELSE PRINT('INFO: tabla Comprobante ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Entrada' AND schema_id = SCHEMA_ID('venta'))
	BEGIN
		CREATE TABLE venta.Entrada (
			ID                      INT IDENTITY(1,1)   NOT NULL,
			ID_TipoEntradaParque    INT                 NOT NULL,
			ID_Comprobante          INT                 NOT NULL,
			FechaHora               DATETIME            NOT NULL,
			PrecioCobrado           DECIMAL(12,2)       NOT NULL,

			CONSTRAINT PK_Entrada PRIMARY KEY (ID),
			CONSTRAINT FK_Entrada_TipoEntradaParque FOREIGN KEY (ID_TipoEntradaParque) REFERENCES venta.TipoEntradaParque(ID),
			CONSTRAINT FK_Entrada_Comprobante FOREIGN KEY (ID_Comprobante) REFERENCES venta.Comprobante(ID)
		);
		PRINT('OK: tabla Entrada creada exitosamente');
	END
ELSE PRINT('INFO: tabla Entrada ya existe')