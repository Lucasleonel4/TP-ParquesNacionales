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
* Descripción: Crea el esquema actividad y sus tablas
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