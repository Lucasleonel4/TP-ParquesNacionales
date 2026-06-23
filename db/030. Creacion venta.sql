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
 * Descripción: Crea el esquema venta, sus tablas, procedimientos almacenados ABM y funciones de consulta sobre campos.
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
ELSE PRINT('INFO: tabla Divisa ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoEntrada' AND schema_id = SCHEMA_ID('venta'))
	BEGIN
		CREATE TABLE venta.TipoEntrada (
			ID      INT IDENTITY(1,1)   NOT NULL,
			Nombre  VARCHAR(100)        NOT NULL,

			CONSTRAINT PK_TipoEntrada PRIMARY KEY (ID)
		);
		PRINT('OK: tabla TipoEntrada creada exitosamente');
	END
ELSE PRINT('INFO: tabla TipoEntrada ya existe');

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
ELSE PRINT('INFO: tabla TipoEntradaParque ya existe');

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
ELSE PRINT('INFO: tabla Comprobante ya existe');

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
ELSE PRINT('INFO: tabla Entrada ya existe');

-- PROCEDIMIENTOS ALMACENADOS ABM: DIVISA
GO

CREATE OR ALTER PROCEDURE [venta].[SP_Divisa_Insert]
	@COD_ISO      CHAR(3),
	@Pais         VARCHAR(50)     = NULL,
	@ValorEnPesos DECIMAL(12,3)   = NULL
AS
	INSERT INTO [venta].[Divisa](COD_ISO, Pais, ValorEnPesos)
	VALUES(@COD_ISO, @Pais, @ValorEnPesos)
GO

CREATE OR ALTER PROCEDURE [venta].[SP_Divisa_Update]
	@COD_ISO      CHAR(3),
	@Pais         VARCHAR(50)     = NULL,
	@ValorEnPesos DECIMAL(12,3)   = NULL
AS
	UPDATE [venta].[Divisa]
	SET
		Pais         = CASE WHEN @Pais = 'SD' THEN NULL ELSE ISNULL(@Pais, Pais) END,
		ValorEnPesos = CASE WHEN @ValorEnPesos = -1 THEN NULL ELSE ISNULL(@ValorEnPesos, ValorEnPesos) END
	WHERE COD_ISO = @COD_ISO;
GO

CREATE OR ALTER PROCEDURE [venta].[SP_Divisa_Delete]
	@COD_ISO CHAR(3)
AS
	DELETE FROM [venta].[Divisa]
	WHERE COD_ISO = @COD_ISO;
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: TIPO DE ENTRADA

CREATE OR ALTER PROCEDURE [venta].[SP_TipoEntrada_Insert]
	@Nombre VARCHAR(100)
AS
	INSERT INTO [venta].[TipoEntrada](Nombre)
	VALUES(@Nombre)
GO

CREATE OR ALTER PROCEDURE [venta].[SP_TipoEntrada_Update]
	@ID     INT,
	@Nombre VARCHAR(100) = NULL
AS
	UPDATE [venta].[TipoEntrada]
	SET Nombre = ISNULL(@Nombre, Nombre)
	WHERE ID = @ID;
GO

CREATE OR ALTER PROCEDURE [venta].[SP_TipoEntrada_Delete]
	@ID INT
AS
	DELETE FROM [venta].[TipoEntrada]
	WHERE ID = @ID;
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: TIPO DE ENTRADA PARQUE

CREATE OR ALTER PROCEDURE [venta].[SP_TipoEntradaParque_Insert]
	@ID_AreaProtegida BIGINT,
	@ID_TipoEntrada   INT,
	@Precio           DECIMAL(12,2)
AS
	INSERT INTO [venta].[TipoEntradaParque](ID_AreaProtegida, ID_TipoEntrada, Precio)
	VALUES(@ID_AreaProtegida, @ID_TipoEntrada, @Precio)
GO

CREATE OR ALTER PROCEDURE [venta].[SP_TipoEntradaParque_Update]
	@ID               INT,
	@ID_AreaProtegida BIGINT         = NULL,
	@ID_TipoEntrada   INT            = NULL,
	@Precio           DECIMAL(12,2)  = NULL
AS
	UPDATE [venta].[TipoEntradaParque]
	SET
		ID_AreaProtegida = ISNULL(@ID_AreaProtegida, ID_AreaProtegida),
		ID_TipoEntrada   = ISNULL(@ID_TipoEntrada, ID_TipoEntrada),
		Precio           = ISNULL(@Precio, Precio)
	WHERE ID = @ID;
GO

CREATE OR ALTER PROCEDURE [venta].[SP_TipoEntradaParque_Delete]
	@ID INT
AS
	DELETE FROM [venta].[TipoEntradaParque]
	WHERE ID = @ID;
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: COMPROBANTE

CREATE OR ALTER PROCEDURE [venta].[SP_Comprobante_Insert]
	@ID_PuntoDeVenta INT,
	@COD_ISO_Divisa  CHAR(3),
	@MedioDePago     VARCHAR(20),
	@FechaHora       DATETIME,
	@Total           DECIMAL(12,2),
	@IDComprobante	 INT OUTPUT
AS
	INSERT INTO [venta].[Comprobante](ID_PuntoDeVenta, COD_ISO_Divisa, MedioDePago, FechaHora, Total)
	VALUES(@ID_PuntoDeVenta, @COD_ISO_Divisa, @MedioDePago, @FechaHora, @Total)
	SET @IDComprobante = SCOPE_IDENTITY()
GO

CREATE OR ALTER PROCEDURE [venta].[SP_Comprobante_Update]
	@ID              INT,
	@ID_PuntoDeVenta INT          = NULL,
	@COD_ISO_Divisa  CHAR(3)     = NULL,
	@MedioDePago     VARCHAR(20) = NULL,
	@FechaHora       DATETIME    = NULL,
	@Total           DECIMAL(12,2) = NULL
AS
	UPDATE [venta].[Comprobante]
	SET
		ID_PuntoDeVenta = ISNULL(@ID_PuntoDeVenta, ID_PuntoDeVenta),
		COD_ISO_Divisa  = ISNULL(@COD_ISO_Divisa, COD_ISO_Divisa),
		MedioDePago     = ISNULL(@MedioDePago, MedioDePago),
		FechaHora       = ISNULL(@FechaHora, FechaHora),
		Total           = ISNULL(@Total, Total)
	WHERE ID = @ID;
GO

CREATE OR ALTER PROCEDURE [venta].[SP_Comprobante_Delete]
	@ID INT
AS
	DELETE FROM [venta].[Comprobante]
	WHERE ID = @ID;
GO

-- PROCEDIMIENTOS ALMACENADOS ABM: ENTRADA

CREATE OR ALTER PROCEDURE [venta].[SP_Entrada_Insert]
	@ID_TipoEntradaParque INT,
	@ID_Comprobante       INT,
	@FechaHora            DATETIME,
	@PrecioCobrado        DECIMAL(12,2)
AS
	INSERT INTO [venta].[Entrada](ID_TipoEntradaParque, ID_Comprobante, FechaHora, PrecioCobrado)
	VALUES(@ID_TipoEntradaParque, @ID_Comprobante, @FechaHora, @PrecioCobrado)
GO

CREATE OR ALTER PROCEDURE [venta].[SP_Entrada_Update]
	@ID                   INT,
	@ID_TipoEntradaParque INT          = NULL,
	@ID_Comprobante       INT          = NULL,
	@FechaHora            DATETIME     = NULL,
	@PrecioCobrado        DECIMAL(12,2) = NULL
AS
	UPDATE [venta].[Entrada]
	SET
		ID_TipoEntradaParque = ISNULL(@ID_TipoEntradaParque, ID_TipoEntradaParque),
		ID_Comprobante       = ISNULL(@ID_Comprobante, ID_Comprobante),
		FechaHora            = ISNULL(@FechaHora, FechaHora),
		PrecioCobrado        = ISNULL(@PrecioCobrado, PrecioCobrado)
	WHERE ID = @ID;
GO

CREATE OR ALTER PROCEDURE [venta].[SP_Entrada_Delete]
	@ID INT
AS
	DELETE FROM [venta].[Entrada]
	WHERE ID = @ID;
GO

-- ============================================================
-- FUNCIONES
-- ============================================================
	
-- DEVUELVE EL ID DE TIPOENTRADAPARQUE SEGÚN ÁREAPROTEGIDA Y TIPOENTRADA

	CREATE OR ALTER FUNCTION [venta].[FN_TipoEntradaParque_ObtenerID] (@ID_AreaProtegida BIGINT, @ID_TipoEntrada INT)
	RETURNS INT
	AS
	BEGIN 
		DECLARE @ID INT

		SELECT @ID = ID
		FROM [venta].[TipoEntradaParque]
		WHERE ID_AreaProtegida = @ID_AreaProtegida AND ID_TipoEntrada = @ID_TipoEntrada

		RETURN @ID;
	END;
	GO

-- DEVUELVE EL PRECIO DE TIPOENTRADAPARQUE SEGÚN ÁREAPROTEGIDA Y TIPOENTRADA

	CREATE OR ALTER FUNCTION [venta].[FN_TipoEntradaParque_ObtenerPrecio] (@ID_AreaProtegida BIGINT, @ID_TipoEntrada INT)
	RETURNS DECIMAL(12,2)
	AS
	BEGIN 
		DECLARE @Precio DECIMAL(12,2)

		SELECT @Precio = Precio
		FROM [venta].[TipoEntradaParque]
		WHERE ID_AreaProtegida = @ID_AreaProtegida AND ID_TipoEntrada = @ID_TipoEntrada

		RETURN @Precio;
	END;
	GO