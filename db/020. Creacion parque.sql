/*
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Script: 020. Creacion parque
* Descripción: Crea el esquema parque y sus tablas
*/

USE com2900;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'parque')
	BEGIN TRY
		EXEC('CREATE SCHEMA parque')
		PRINT('OK: esquema parque creado exitosamente')
	END TRY
	BEGIN CATCH
		PRINT('ERROR: No se pudo crear el esquema parque')
		RETURN
	END CATCH
ELSE PRINT ('INFO: el equema parque ya existe');

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Provincia' AND schema_id = SCHEMA_ID('parque'))
	BEGIN
		CREATE TABLE parque.Provincia (
			ID      INT             NOT NULL,
			Nombre  VARCHAR(200)    NOT NULL,
			CONSTRAINT PK_Provincia PRIMARY KEY (ID)
		);
		PRINT('OK: tabla Provincia creada exitosamente');
	END
ELSE PRINT('INFO: tabla Provincia ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AreaProtegida' AND schema_id = SCHEMA_ID('parque'))
	BEGIN
		CREATE TABLE parque.AreaProtegida (
			ID              BIGINT             NOT NULL,
			TipoArea        VARCHAR(50)        NOT NULL,
			Nombre          VARCHAR(100)       NOT NULL,
			Superficie      DECIMAL(12,2)      NULL,
			Info_Operativa  VARCHAR(250)       NULL,
			Info_General    VARCHAR(250)       NULL,
			Calle_Entrada   VARCHAR(100)       NULL,
			Nro_Entrada     VARCHAR(20)        NULL,
			Latitud         DECIMAL(12,9)      NULL,
			Longitud        DECIMAL(12,9)      NULL,
			CONSTRAINT PK_AreaProtegida PRIMARY KEY (ID),
			CONSTRAINT CK_AreaProtegida_Tipo CHECK (TipoArea IN ('Parque Nacional', 'Reserva Nacional','Monumento Natural', 'Parque Nacional Marino'))
		);
		PRINT('OK: tabla AreaProtegida creada exitosamente');
	END
ELSE PRINT('INFO: tabla AreaProtegida ya existe')


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PuntoDeVenta' AND schema_id = SCHEMA_ID('parque'))
	BEGIN
		CREATE TABLE parque.PuntoDeVenta (
			ID                  INT IDENTITY(1,1)   NOT NULL,
			ID_AreaProtegida    BIGINT              NOT NULL,
			Descripcion         VARCHAR(100)        NULL,
			CONSTRAINT PK_PuntoDeVenta PRIMARY KEY (ID),
			CONSTRAINT FK_PuntoDeVenta_AreaProtegida FOREIGN KEY (ID_AreaProtegida)
			REFERENCES parque.AreaProtegida(ID)
		);
		PRINT('OK: tabla PuntoDeVenta creada exitosamente');
	END
ELSE PRINT('INFO: tabla PuntoDeVenta ya existe')

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ProvinciaContieneParque' AND schema_id = SCHEMA_ID('parque'))
	BEGIN
		CREATE TABLE parque.ProvinciaContieneParque (
			ID_Provincia        INT    NOT NULL,
			ID_AreaProtegida    BIGINT NOT NULL,
			CONSTRAINT PK_ProvinciaContieneParque PRIMARY KEY (ID_Provincia, ID_AreaProtegida),
			CONSTRAINT FK_ProvinciaContieneParque_Provincia FOREIGN KEY (ID_Provincia)
			REFERENCES parque.Provincia(ID),
			CONSTRAINT FK_ProvinciaContieneParque_AreaProtegida FOREIGN KEY (ID_AreaProtegida)
			REFERENCES parque.AreaProtegida(ID)
		);
		PRINT('OK: tabla ProvinciaContieneParque creada exitosamente');
	END
ELSE PRINT('INFO: tabla ProvinciaContieneParque ya existe')