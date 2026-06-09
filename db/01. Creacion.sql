/* ------------------------------------------------------ *
 |      CREACIÓN DE BASE DE DATOS, ESQUEMAS Y TABLAS      |
 * ------------------------------------------------------ */

USE MASTER;
GO

IF EXISTS( select 1 from sys.databases where name = 'com2900')
	DROP DATABASE com2900
GO
	CREATE DATABASE com2900
GO

USE com2900
GO

/* ------------------------------------------------------ *
 |                 CREACION DE ESQUEMAS                   |
 * ------------------------------------------------------ */


	-- CREACION DE ESQUEMA DE PARQUE
		IF SCHEMA_ID('parque') IS NOT NULL
			DROP SCHEMA [parque];
		GO
		CREATE SCHEMA [parque]
		GO
	-- CREACION DE ESQUEMA DE VENTAS
		IF SCHEMA_ID('venta') IS NOT NULL
			DROP SCHEMA [venta]
		GO
		CREATE SCHEMA [venta]
		GO
	-- CREACION DE ESQUEMA DE ACTIVIDADES
		IF SCHEMA_ID('actividad') IS NOT NULL
			DROP SCHEMA [actividad]
		GO
		CREATE SCHEMA [actividad]
		GO
	-- CREACION DE ESQUEMA DE PERSONAL
		IF SCHEMA_ID('personal') IS NOT NULL
			DROP SCHEMA [personal]
		GO
		CREATE SCHEMA [personal]
		GO
	-- CREACION DE ESQUEMA DE CONCESIONES
		IF SCHEMA_ID('concesion') IS NOT NULL
			DROP SCHEMA [concesion]
		GO
		CREATE SCHEMA [concesion]
		GO


/* ------------------------------------------------------ *
 |                 CREACION DE TABLAS                     |
 * ------------------------------------------------------ */
 

	-- =============================================
	--				 ESQUEMA: parque
	-- =============================================

		-- TABLA DE PROVINCIAS
				DROP TABLE IF EXISTS [parque].[Provincia]
				GO
				CREATE TABLE [parque].[Provincia] (
					ID		INT				NOT NULL,
					Nombre	VARCHAR(200)	NOT NULL,

					CONSTRAINT PK_Provincia PRIMARY KEY (ID)
				)
				GO

		-- TABLA DE TIPO DE PARQUES
			DROP TABLE IF EXISTS [parque].[TipoParque]
			GO
			CREATE TABLE [parque].[TipoParque] (
				ID			INT IDENTITY(1,1)	NOT NULL,
				Nombre		VARCHAR(50)			NOT NULL,
				Descripcion VARCHAR(200)		NULL,

				CONSTRAINT PK_TipoParque PRIMARY KEY (ID)
			)
			GO

		-- TABLA DE PARQUE NACIONAL
			DROP TABLE IF EXISTS [parque].[ParqueNacional]
			GO
			CREATE TABLE [parque].[ParqueNacional] (
				ID				INT	IDENTITY(1,1)	NOT NULL,
				ID_TipoParque	INT					NOT NULL,
				Nombre			VARCHAR(100)		NOT NULL,
				Superficie		DECIMAL(12,2)		NULL,
				Info_Operativa	VARCHAR(MAX)		NULL,
				Info_General	VARCHAR(MAX)		NULL,
				Calle_Entrada	VARCHAR(100)		NOT NULL,
				Nro_Entrada		VARCHAR(20)			NOT NULL,
				Latitud			DECIMAL(12,9)		NOT NULL,
				Longitud		DECIMAL(12,9)		NOT NULL

				CONSTRAINT PK_ParqueNacional PRIMARY KEY (ID),
				CONSTRAINT FK_ParqueNacional_TipoParque FOREIGN KEY (ID_TipoParque)
					REFERENCES [parque].[TipoParque](ID)
			)
			GO

		-- TABLA DE PUNTO DE VENTA
			DROP TABLE IF EXISTS [parque].[PuntoDeVenta]
			GO
			CREATE TABLE [parque].[PuntoDeVenta] (
				ID					INT IDENTITY(1,1)	NOT NULL,
				ID_ParqueNacional	INT					NOT NULL,
				Descripcion			VARCHAR(100)		NULL,
				CONSTRAINT PK_PuntoDeVenta PRIMARY KEY (ID),

				CONSTRAINT FK_PuntoDeVenta_ParqueNacional FOREIGN KEY (ID_ParqueNacional)
					REFERENCES [parque].[ParqueNacional](ID)
			)
			GO

		-- TABLA DE PROVINCIA CONTIENE PARQUE
			DROP TABLE IF EXISTS [parque].[ProvinciaContieneParque]
			GO
			CREATE TABLE [parque].[ProvinciaContieneParque] (
				ID_Provincia		INT NOT NULL,
				ID_ParqueNacional	INT NOT NULL,

				CONSTRAINT PK_ProvinciaContieneParque PRIMARY KEY (ID_Provincia, ID_ParqueNacional),
				CONSTRAINT FK_ProvinciaContieneParque_Provincia FOREIGN KEY (ID_Provincia)
					REFERENCES [parque].[Provincia](ID),
				CONSTRAINT FK_ProvinciaContieneParque_ParqueNacional FOREIGN KEY (ID_ParqueNacional)
					REFERENCES [parque].[ParqueNacional](ID)
			)
			GO

	-- =============================================
	--				 ESQUEMA: venta
	-- =============================================


		-- TABLA DE DIVISAS
			DROP TABLE IF EXISTS [venta].[Divisa]
			GO
			CREATE TABLE [venta].[Divisa] (
				COD_ISO			char(3)			NOT NULL,
				Pais			VARCHAR(50)		NOT NULL,
				ValorEnPesos	DECIMAL(12,3)	NOT NULL,

				CONSTRAINT PK_Divisa PRIMARY KEY (COD_ISO)
			)
			GO

		-- TABLA DE MEDIOS DE PAGOS
			DROP TABLE IF EXISTS [venta].[MedioDePago]
			GO
			CREATE TABLE [venta].[MedioDePago] (
				ID		INT IDENTITY(1,1)	NOT NULL,
				Nombre	VARCHAR(50)			NOT NULL,

				CONSTRAINT PK_MedioDePago PRIMARY KEY (ID)
			)
			GO

		-- TABLA DE COMPROBANTES
			DROP TABLE IF EXISTS [venta].[Comprobante]
			GO
			CREATE TABLE [venta].[Comprobante] (
				ID				INT IDENTITY(1,1)	NOT NULL,
				ID_PuntoDeVenta INT					NOT NULL,
				COD_ISO_Divisa	CHAR(3)				NOT NULL,
				ID_MedioDePago	INT					NOT NULL,
				FechaHora		DATETIME			NOT NULL,
				Total			DECIMAL(12,2)		NOT NULL,

				CONSTRAINT PK_Comprobante PRIMARY KEY (ID),
				CONSTRAINT FK_Comprobante_PuntoDeVenta FOREIGN KEY (ID_PuntoDeVenta)
					REFERENCES [parque].[PuntoDeVenta](ID),
				CONSTRAINT FK_Comprobante_COD_ISO_Divisa FOREIGN KEY (COD_ISO_Divisa)
					REFERENCES [venta].[Divisa](COD_ISO),
				CONSTRAINT FK_Comprobante_MedioDePago FOREIGN KEY (ID_MedioDePago)
					REFERENCES [venta].[MedioDePago](ID)
			)
			GO

		-- TABLA DE TIPOS DE ENTRADAS: TIPOS PREDEFINIDOS POR ENTIDAD GUBERNAMENTAL
			DROP TABLE IF EXISTS [venta].[TipoEntrada]
			GO
			CREATE TABLE [venta].[TipoEntrada] (
				ID		INT IDENTITY(1,1)	NOT NULL,
				Nombre	VARCHAR(100)		NOT NULL,
				
				CONSTRAINT PK_TipoEntrada PRIMARY KEY (ID)
			)
			GO

		-- TABLA DE TIPO ENTRADA PARQUES: MODIFICACIÓN DISCRECIONAL DE CADA PARQUE DE PRECIOS
			DROP TABLE IF EXISTS [venta].[TipoEntradaParque]
			GO
			CREATE TABLE [venta].[TipoEntradaParque] (
				ID_ParqueNacional	INT				NOT NULL,
				ID_TipoEntrada		INT				NOT NULL,
				Precio				DECIMAL(12,2)	NOT NULL,
				
				CONSTRAINT PK_TipoEntradaParque PRIMARY KEY (ID_ParqueNacional, ID_TipoEntrada),
				CONSTRAINT FK_TipoEntradaParque_ParqueNacional FOREIGN KEY (ID_ParqueNacional)
					REFERENCES [parque].[ParqueNacional](ID),
				CONSTRAINT FK_TipoEntradaParque_TipoEntrada FOREIGN KEY (ID_TipoEntrada)
					REFERENCES [venta].[TipoEntrada](ID)
			)
			GO

		-- TABLA DE ENTRADAS
			DROP TABLE IF EXISTS [venta].[Entrada]
			GO
			CREATE TABLE [venta].[Entrada] (
				ID				INT IDENTITY(1,1)	NOT NULL,
				ID_TipoEntrada	INT					NOT NULL,
				ID_Comprobante	INT					NOT NULL,
				FechaHora		DATETIME			NOT NULL,
				PrecioCobrado	DECIMAL(12,2)		NOT NULL,

				CONSTRAINT PK_Entrada PRIMARY KEY (ID),
				CONSTRAINT FK_Entrada_TipoEntrada FOREIGN KEY (ID_TipoEntrada)
					REFERENCES [venta].[TipoEntrada](ID),
				CONSTRAINT FK_Entrada_Comprobante FOREIGN KEY (ID_Comprobante)
					REFERENCES [venta].[Comprobante](ID)
			)
			GO

	-- =============================================
	--				 ESQUEMA: Personal
	-- =============================================


		-- TABLA DE GUIAS AUTORIZADOS
			DROP TABLE IF EXISTS [personal].[GuiaAutorizado]
			GO
			CREATE TABLE [personal].[GuiaAutorizado] (
				CUIL            INT		        NOT NULL,
				Nombre          VARCHAR(100)    NOT NULL,
				Apellido        VARCHAR(100)    NOT NULL,
				FechaNacimiento DATE            NULL,
				Autorizado      BIT             NOT NULL,

				CONSTRAINT PK_GuiaAutorizado PRIMARY KEY (CUIL)
			)
			GO

		-- TABLA DE TITULOS ACADEMICOS
			DROP TABLE IF EXISTS [personal].[TituloAcademico]
			GO
			CREATE TABLE [personal].[TituloAcademico] (
				ID              INT IDENTITY(1,1)	NOT NULL,
				Nombre          VARCHAR(100)		NOT NULL,
				Entidad_Otorga  VARCHAR(100)		NOT NULL,
				Tipo            VARCHAR(50)			NOT NULL,
				Area            VARCHAR(50)			NOT NULL,
				FechaObtenido   DATE				NOT NULL,

				CONSTRAINT PK_TituloAcademico PRIMARY KEY (ID) --, Nombre, Entidad_Otorga)
			)
			GO

		-- TABLA DE HABILITACIONES QUE UN GUIA PUEDE OBTENER
			DROP TABLE IF EXISTS [personal].[HabilitacionGuia]
			GO
			CREATE TABLE [personal].[HabilitacionGuia] (
				ID              INT IDENTITY(1,1)	NOT NULL,
				Nombre          VARCHAR(50) 		NOT NULL,
				Descripcion     VARCHAR(200)		NULL,
				FechaObtenido   DATE				NOT NULL,
				FechaExpiracion DATE				NOT NULL,

				CONSTRAINT PK_HabilitacionGuia PRIMARY KEY (ID)
			)
			GO

		-- TABLA DE ESPECIALIDADES QUE UN GUIA PUEDE OBTENER
			DROP TABLE IF EXISTS [personal].[EspecialidadGuia]
			GO
			CREATE TABLE [personal].[EspecialidadGuia] (
				ID              INT             NOT NULL,
				Nombre          VARCHAR(100)    NOT NULL,
				FechaObtenida   DATE            NOT NULL,

				CONSTRAINT PK_EspecialidadGuia PRIMARY KEY (ID)
			)
			GO

		-- TABLA DE TITULOS ASIGNADOS A UN GUIAS
			DROP TABLE IF EXISTS [personal].[GuiaConTitulo]
			GO
			CREATE TABLE [personal].[GuiaConTitulo] (
				CUIL_GuiaAutorizado INT	NOT NULL,
				ID_TituloAcademico  INT	NOT NULL,

				CONSTRAINT PK_GuiaConTitulo PRIMARY KEY (CUIL_GuiaAutorizado, ID_TituloAcademico),
				CONSTRAINT FK_GuiaConTitulo_Guia FOREIGN KEY (CUIL_GuiaAutorizado)
					REFERENCES [personal].[GuiaAutorizado](CUIL),
				CONSTRAINT FK_GuiaConTitulo_Titulo FOREIGN KEY (ID_TituloAcademico)
					REFERENCES [personal].[TituloAcademico](ID)
			)
			GO

		-- TABLA DE HABILITACIONES ASIGNADOS A UN GUIA
			DROP TABLE IF EXISTS [personal].[GuiaConHabilitacion]
			GO
			CREATE TABLE [personal].[GuiaConHabilitacion] (
				CUIL_GuiaAutorizado INT	NOT NULL,
				ID_HabilitacionGuia INT NOT NULL,

				CONSTRAINT PK_GuiaConHabilitacion PRIMARY KEY (CUIL_GuiaAutorizado, ID_HabilitacionGuia),
				CONSTRAINT FK_GuiaConHabilitacion_Guia FOREIGN KEY (CUIL_GuiaAutorizado)
					REFERENCES [personal].[GuiaAutorizado](CUIL),
				CONSTRAINT FK_GuiaConHabilitacion_Habilitacion FOREIGN KEY (ID_HabilitacionGuia)
					REFERENCES [personal].[HabilitacionGuia](ID)
			)
			GO

		-- TABLA DE ESPECIALIDADES ASIGNADAS A UN GUIA
			DROP TABLE IF EXISTS [personal].[GuiaConEspecialidad]
			GO
			CREATE TABLE [personal].[GuiaConEspecialidad] (
				CUIL_GuiaAutorizado INT	NOT NULL,
				ID_EspecialidadGuia INT NOT NULL,

				CONSTRAINT PK_GuiaConEspecialidad PRIMARY KEY (CUIL_GuiaAutorizado, ID_EspecialidadGuia),
				CONSTRAINT FK_GuiaConEspecialidad_Guia FOREIGN KEY (CUIL_GuiaAutorizado)
					REFERENCES [personal].[GuiaAutorizado](CUIL),
				CONSTRAINT FK_GuiaConEspecialidad_Especialidad FOREIGN KEY (ID_EspecialidadGuia)
					REFERENCES [personal].[EspecialidadGuia](ID)
			)
			GO

		-- TABLA DE GUARDAPARQUES
			DROP TABLE IF EXISTS [personal].[Guardaparques]
			GO
			CREATE TABLE [personal].[Guardaparques] (
				CUIL            INT		        NOT NULL,
				Nombre          VARCHAR(100)    NOT NULL,
				Apellido        VARCHAR(100)    NOT NULL,
				FechaNacimiento DATE            NOT NULL,
				FechaIngreso    DATE            NOT NULL,
				FechaEgreso     DATE            NULL,
				MotivoEgreso    VARCHAR(255)    NULL,

				CONSTRAINT PK_Guardaparques PRIMARY KEY (CUIL)
			)
			GO

		-- TABLA DE GUIAS CONTRADADOS POR UN PARQUE 
			DROP TABLE IF EXISTS [personal].[ContratoTrabajo]
			GO
			CREATE TABLE [personal].[ContratoTrabajo] (
				ID                  INT IDENTITY (1,1)	NOT NULL,
				ID_ParqueNacional   INT					NOT NULL,
				CUIL_Guardaparques  INT					NOT NULL,
				FechaInicio         DATE				NOT NULL,
				FechaFin            DATE				NULL,

				CONSTRAINT PK_ContratoTrabajo PRIMARY KEY (ID),
				CONSTRAINT FK_ContratoTrabajo_Parque FOREIGN KEY (ID_ParqueNacional)
					REFERENCES [parque].[ParqueNacional](ID),
				CONSTRAINT FK_ContratoTrabajo_Guardaparques FOREIGN KEY (CUIL_Guardaparques)
					REFERENCES [personal].[Guardaparques](CUIL)
			)
			GO

	-- =============================================
	--				 ESQUEMA: Actividad
	-- =============================================


		-- TABLA DE TIPOS DE ACTIVIDADES
			DROP TABLE IF EXISTS [actividad].[TipoActividad]
			GO
			CREATE TABLE [actividad].[TipoActividad] (
				ID		INT IDENTITY(1,1)	NOT NULL,
				Nombre	VARCHAR(50)			NOT NULL,

				CONSTRAINT PK_TipoActividad PRIMARY KEY (ID)
			)
			GO

		-- TABLA DE ACTIVIDADES
			DROP TABLE IF EXISTS [actividad].[Actividad]
			GO
			CREATE TABLE [actividad].[Actividad] (
				ID					INT IDENTITY(1,1)	NOT NULL,
				ID_ParqueNacional	INT					NOT NULL,
				ID_TipoActividad	INT					NOT NULL,
				Nombre				VARCHAR(50)			NOT NULL,
				Duracion			INT					NULL,
				Costo				DECIMAL(12,2)		NULL,
				CupoMaximo			INT					NULL,

				CONSTRAINT PK_Actividad PRIMARY KEY (ID),
				CONSTRAINT FK_Actividad_ParqueNacional FOREIGN KEY (ID_ParqueNacional)
					REFERENCES [parque].[ParqueNacional](ID),
				CONSTRAINT FK_Actividad_TipoActividad FOREIGN KEY (ID_TipoActividad)
					REFERENCES [actividad].[TipoActividad](ID),
			)
			GO

		-- TABLA DE INSCRIPCION A ACTIVIDADES
			DROP TABLE IF EXISTS [actividad].[InscripcionActividad]
			GO
			CREATE TABLE [actividad].[InscricionActividad] (
				ID              INT IDENTITY(1,1)   NOT NULL,
				ID_PuntoDeVenta INT					NOT NULL,
				ID_Actividad    INT					NOT NULL,
				ID_Comprobante  INT					NULL,
				FechaHora       DATETIME			NOT NULL,
				PrecioCobrado   DECIMAL(12,2)		NOT NULL,

				CONSTRAINT PK_InscripcionActividad PRIMARY KEY (ID),
				CONSTRAINT FK_InscripcionActividad_PuntoDeVenta FOREIGN KEY (ID_PuntoDeVenta)
					REFERENCES [parque].[PuntoDeVenta](ID),
				CONSTRAINT FK_InscripcionActividad_Actividad FOREIGN KEY (ID_Actividad)
					REFERENCES [actividad].[Actividad](ID),
				CONSTRAINT FK_InscripcionActividad_Comprobante FOREIGN KEY (ID_Comprobante)
					REFERENCES [venta].[Comprobante](ID)
			)
			GO

		-- TABLA DE GUIAS ASIGNADOS A ACTIVIDADES TIPO TOUR
			DROP TABLE IF EXISTS [actividad].[GuiaAsignadoTour]
			GO
			CREATE TABLE [actividad].[GuiaAsignadoTour] (
				ID_Actividad		INT NOT NULL,
				CUIL_GuiaAutorizado INT NOT NULL,

				CONSTRAINT PK_GuiaAsignadoTour PRIMARY KEY (ID_Actividad, CUIL_GuiaAutorizado),
				CONSTRAINT FK_GuiaAsignadoTour_Actividad FOREIGN KEY (ID_Actividad)
					REFERENCES [actividad].[Actividad](ID),
				CONSTRAINT FK_GuiaAsignadoTour_GuiaAutorizado FOREIGN KEY (CUIL_GuiaAutorizado)
					REFERENCES [personal].[GuiaAutorizado](CUIL)
			)
			GO

	-- =============================================
	--				 ESQUEMA: Concesiones
	-- =============================================


		-- TABLA DE ACTIVIDADES FISCALES (DEPENDE DE ENTIDAD FISCALIZADORA)
			DROP TABLE IF EXISTS [concesion].[ActividadFiscal]
			GO
			CREATE TABLE [concesion].[ActividadFiscal] (
				ID      INT IDENTITY(1,1)	NOT NULL,
				Nombre  VARCHAR(100)		NOT NULL,

				CONSTRAINT PK_ActividadFiscal PRIMARY KEY (ID)
			)
			GO

		-- TABLA DE EMPRESAS VINCULADAS A ALGUN PARQUE NACIONAL
			DROP TABLE IF EXISTS [concesion].[Empresa]
			GO
			CREATE TABLE [concesion].[Empresa] (
				CUIT    INT				NOT NULL,
				Nombre  VARCHAR(150)    NOT NULL,

				CONSTRAINT PK_Empresa PRIMARY KEY (CUIT)
			)
			GO

		-- TABLA DE LOS DIFERENTES TIPOS DE CONCESIONES
			DROP TABLE IF EXISTS [concesion].[TipoConcesion]
			GO
			CREATE TABLE [concesion].[TipoConcesion] (
				ID                  INT IDENTITY(1,1)   NOT NULL,
				ID_ActividadFiscal  INT					NOT NULL,
				Nombre              VARCHAR(100)		NOT NULL,

				CONSTRAINT PK_TipoConcesion PRIMARY KEY (ID),
				CONSTRAINT FK_TipoConcesion_ActividadFiscal FOREIGN KEY (ID_ActividadFiscal)
					REFERENCES [concesion].[ActividadFiscal](ID)
			)
			GO

		-- TABLA DE LAS DIFERENTES ACTIVIDADES FISCALES A LAS CUALES ESTA INSCRIPTA UNA EMPRESA
			DROP TABLE IF EXISTS [concesion].[ActividadFiscalInscriptaEmpresa]
			GO
			CREATE TABLE [concesion].[ActividadFiscalInscriptaEmpresa] (
				CUIT_Empresa        INT	NOT NULL,
				ID_ActividadFiscal  INT NOT NULL,
				CONSTRAINT PK_ActividadFiscalInscriptaEmpresa PRIMARY KEY (CUIT_Empresa, ID_ActividadFiscal),
				
				CONSTRAINT FK_ActividadFiscalInscriptaEmpresa_Empresa FOREIGN KEY (CUIT_Empresa)
					REFERENCES [concesion].[Empresa](CUIT),
				CONSTRAINT FK_ActividadFiscalInscriptaEmpresa_ActividadFiscal FOREIGN KEY (ID_ActividadFiscal)
					REFERENCES [concesion].[ActividadFiscal](ID)
			)
			GO

		-- TABLA DE CONCESIONES OTORGADAS
			DROP TABLE IF EXISTS [concesion].[Concesion]
			GO
			CREATE TABLE [concesion].[Concesion] (
				ID                  INT IDENTITY(1,1)	NOT NULL,
				ID_ParqueNacional   INT					NOT NULL,
				CUIT_Empresa        INT					NOT NULL,
				ID_TipoConcesion    INT					NOT NULL,
				FechaInicio         DATE				NOT NULL,
				FechaFin            DATE				NOT NULL,
				Canon               DECIMAL(20,2)		NOT NULL,
				
				CONSTRAINT PK_Concesion PRIMARY KEY (ID),
				CONSTRAINT FK_Concesion_Parque FOREIGN KEY (ID_ParqueNacional)
					REFERENCES [parque].[ParqueNacional](ID),
				CONSTRAINT FK_Concesion_Empresa FOREIGN KEY (CUIT_Empresa)
					REFERENCES [concesion].[Empresa](CUIT),
				CONSTRAINT FK_Concesion_TipoConcesion FOREIGN KEY (ID_TipoConcesion)
					REFERENCES [concesion].[TipoConcesion](ID)
			)
			GO

		-- TABLA DEL REGISTRO DE PAGO DE CONCESIONES
			DROP TABLE IF EXISTS [concesion].[PagoConcesion]
			GO
			CREATE TABLE [concesion].[PagoConcesion] (
				ID              INT IDENTITY(1,1)	NOT NULL,
				ID_Concesion    INT					NOT NULL,
				Fecha           DATE				NOT NULL,
				Monto           DECIMAL(20,2)		NOT NULL,
				CONSTRAINT PK_PagoConcesion PRIMARY KEY (ID),
				CONSTRAINT FK_PagoConcesion_Concesion FOREIGN KEY (ID_Concesion)
					REFERENCES [concesion].[Concesion](ID)
			)
			GO