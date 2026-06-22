
/* ------------------------------------------------------ *
 | LUEGO:
    SE PIDE VALIDAR POR NO EXISTENCIA Y CREAR LOS DIFERENTES ELEMENTOS
    I.E. 
        USAR IF NOT EXISTS PARA CREAR ESQUEMAS
            IF NOT EXISTS (SELECT 1 FROM SYS.SCHEMAS WHERE NAME='PARQUE')
                CREATE SCHEMA [PARQUE]
            
        USAR IF NOT EXISTS PARA CREAR TABLAS
            IF NOT EXISTS (SELECT 1 FROM SYS.TABLES WHERE NAME='EspecialidadGuia')
                CREATE TABLE [Personal].[EspecialidadGuia](...)
 * ------------------------------------------------------ */
 
USE master;
GO

CREATE DATABASE com2900;
GO

USE com2900;
GO

/* ------------------------------------------------------ *
 | CREACIÓN DE ESQUEMAS
 * ------------------------------------------------------ */

CREATE SCHEMA parque;
GO
CREATE SCHEMA venta;
GO
CREATE SCHEMA actividad;
GO
CREATE SCHEMA personal;
GO
CREATE SCHEMA concesion;
GO

/* ------------------------------------------------------ *
 | ESQUEMA: parque
 * ------------------------------------------------------ */

CREATE TABLE parque.Provincia (
    ID      INT             NOT NULL,
    Nombre  VARCHAR(200)    NOT NULL,
    
    CONSTRAINT PK_Provincia PRIMARY KEY (ID)
);
GO

CREATE TABLE parque.AreaProtegida (
    ID              BIGINT             NOT NULL, -- IMPORTABLE
    TipoArea        VARCHAR(50)        NOT NULL, -- IMPORTABLE
    Nombre          VARCHAR(100)       NOT NULL, -- IMPORTABLE
    Superficie      DECIMAL(12,2)      NULL, -- IMPORTABLE
    Info_Operativa  VARCHAR(250)       NULL, -- VER DE DONDE OBTENER¿¿
    Info_General    VARCHAR(250)       NULL, -- VER DE DONDE OBTENER¿¿
    Calle_Entrada   VARCHAR(100)       NULL, -- VER SI QUITAR, NO RELEVANTE
    Nro_Entrada     VARCHAR(20)        NULL, -- VER SI QUITAR, NO RELEVANTE
    Latitud         DECIMAL(12,9)      NULL, -- ESTABLECER MEDIANTE CENTROIDES -> VER SI AÑADIR CAMPO FK A PROVINCIA RELACIONANDO ESE CAMPO A LA PROVINCIA DEL CENTROIDE (CON UNA API¿).
    Longitud        DECIMAL(12,9)      NULL, -- ESTABLECER MEDIANTE CENTROIDES -> VER SI AÑADIR CAMPO FK A PROVINCIA RELACIONANDO ESE CAMPO A LA PROVINCIA DEL CENTROIDE (CON UNA API¿).
    
    CONSTRAINT PK_AreaProtegida PRIMARY KEY (ID),
    CONSTRAINT CK_AreaProtegida_Tipo CHECK (TipoArea IN ('Parque Nacional', 'Reserva Nacional','Monumento Natural', 'Parque Nacional Marino'))
);
GO

CREATE TABLE parque.PuntoDeVenta (
    ID                  INT IDENTITY(1,1)   NOT NULL,
    ID_AreaProtegida    BIGINT              NOT NULL,
    Descripcion         VARCHAR(100)        NULL,
    
    CONSTRAINT PK_PuntoDeVenta PRIMARY KEY (ID),
    CONSTRAINT FK_PuntoDeVenta_AreaProtegida FOREIGN KEY (ID_AreaProtegida)
        REFERENCES parque.AreaProtegida(ID)
);
GO

CREATE TABLE parque.ProvinciaContieneParque ( -- PODRIA NO HACER FALTA
    ID_Provincia        INT    NOT NULL,
    ID_AreaProtegida    BIGINT NOT NULL,
    
    CONSTRAINT PK_ProvinciaContieneParque PRIMARY KEY (ID_Provincia, ID_AreaProtegida),
    CONSTRAINT FK_ProvinciaContieneParque_Provincia FOREIGN KEY (ID_Provincia)
        REFERENCES parque.Provincia(ID),
    CONSTRAINT FK_ProvinciaContieneParque_AreaProtegida FOREIGN KEY (ID_AreaProtegida)
        REFERENCES parque.AreaProtegida(ID)
);
GO

/* ------------------------------------------------------ *
 | ESQUEMA: venta
 * ------------------------------------------------------ */

CREATE TABLE venta.Divisa (
    COD_ISO         CHAR(3)         NOT NULL,
    Pais            VARCHAR(50)     NULL,
    ValorEnPesos    DECIMAL(12,3)   NULL,
    
    CONSTRAINT PK_Divisa PRIMARY KEY (COD_ISO)
);
GO

CREATE TABLE venta.TipoEntrada (
    ID      INT IDENTITY(1,1)   NOT NULL,
    Nombre  VARCHAR(100)        NOT NULL,
    
    CONSTRAINT PK_TipoEntrada PRIMARY KEY (ID)
);
GO

CREATE TABLE venta.TipoEntradaParque (
    ID                  INT IDENTITY(1,1) NOT NULL,
    ID_AreaProtegida    BIGINT            NOT NULL,
    ID_TipoEntrada      INT               NOT NULL,
    Precio              DECIMAL(12,2)     NOT NULL,

    CONSTRAINT PK_TipoEntradaParque PRIMARY KEY (ID),
    CONSTRAINT UQ_TipoEntradaParque_Parque_Tipo UNIQUE (ID_AreaProtegida, ID_TipoEntrada),
    CONSTRAINT FK_TipoEntradaParque_AreaProtegida FOREIGN KEY (ID_AreaProtegida)
        REFERENCES parque.AreaProtegida(ID),
    CONSTRAINT FK_TipoEntradaParque_TipoEntrada FOREIGN KEY (ID_TipoEntrada)
        REFERENCES venta.TipoEntrada(ID)
);
GO

CREATE TABLE venta.Comprobante (
    ID              INT IDENTITY(1,1)   NOT NULL,
    ID_PuntoDeVenta INT                 NOT NULL,
    COD_ISO_Divisa  CHAR(3)             NOT NULL,
    MedioDePago     VARCHAR(20)         NOT NULL,
    FechaHora       DATETIME            NOT NULL,
    Total           DECIMAL(12,2)       NOT NULL,

    CONSTRAINT PK_Comprobante PRIMARY KEY (ID),
    CONSTRAINT CK_Comprobante_MedioDePago CHECK (MedioDePago IN ('Efectivo', 'Tarjeta', 'Transferencia')),
    CONSTRAINT FK_Comprobante_PuntoDeVenta FOREIGN KEY (ID_PuntoDeVenta)
        REFERENCES parque.PuntoDeVenta(ID),
    CONSTRAINT FK_Comprobante_Divisa FOREIGN KEY (COD_ISO_Divisa)
        REFERENCES venta.Divisa(COD_ISO)
);
GO

CREATE TABLE venta.Entrada (
    ID                      INT IDENTITY(1,1)   NOT NULL,
    ID_TipoEntradaParque    INT                 NOT NULL,
    ID_Comprobante          INT                 NOT NULL,
    FechaHora               DATETIME            NOT NULL,
    PrecioCobrado           DECIMAL(12,2)       NOT NULL,
    
    CONSTRAINT PK_Entrada PRIMARY KEY (ID),
    CONSTRAINT FK_Entrada_TipoEntradaParque FOREIGN KEY (ID_TipoEntradaParque)
        REFERENCES venta.TipoEntradaParque(ID),
    CONSTRAINT FK_Entrada_Comprobante FOREIGN KEY (ID_Comprobante)
        REFERENCES venta.Comprobante(ID)
);
GO

/* ------------------------------------------------------ *
 | ESQUEMA: personal
 * ------------------------------------------------------ */

CREATE TABLE personal.GuiaAutorizado (
    CUIL        BIGINT          NOT NULL,
    Nombre      VARCHAR(100)    NOT NULL,
    Apellido    VARCHAR(100)    NOT NULL,
    Autorizado  BIT             NOT NULL,

    CONSTRAINT PK_GuiaAutorizado PRIMARY KEY (CUIL)
);
GO

CREATE TABLE personal.TituloAcademico (
    ID              INT IDENTITY(1,1)   NOT NULL,
    Nombre          VARCHAR(100)        NOT NULL,
    Entidad_Otorga  VARCHAR(100)        NOT NULL,
    Tipo            VARCHAR(50)         NOT NULL,
    Area            VARCHAR(50)         NOT NULL,

    CONSTRAINT PK_TituloAcademico PRIMARY KEY (ID),
    CONSTRAINT UQ_TituloAcademico_Nombre_Entidad UNIQUE (Nombre, Entidad_Otorga)
);
GO

CREATE TABLE personal.HabilitacionGuia (
    ID          INT IDENTITY(1,1)   NOT NULL,
    Nombre      VARCHAR(50)         NOT NULL,
    Descripcion VARCHAR(200)        NOT NULL,

    CONSTRAINT PK_HabilitacionGuia PRIMARY KEY (ID)
);
GO

CREATE TABLE personal.EspecialidadGuia (
    ID          INT IDENTITY(1,1)   NOT NULL,
    Nombre      VARCHAR(100)        NOT NULL,
    Descripcion VARCHAR(200)        NOT NULL,

    CONSTRAINT PK_EspecialidadGuia PRIMARY KEY (ID)
);
GO

CREATE TABLE personal.GuiaConTitulo (
    CUIL_GuiaAutorizado BIGINT  NOT NULL,
    ID_TituloAcademico  INT     NOT NULL,
    FechaObtenido       DATE    NOT NULL,
    
    CONSTRAINT PK_GuiaConTitulo PRIMARY KEY (CUIL_GuiaAutorizado, ID_TituloAcademico),
    CONSTRAINT FK_GuiaConTitulo_Guia FOREIGN KEY (CUIL_GuiaAutorizado)
        REFERENCES personal.GuiaAutorizado(CUIL),
    CONSTRAINT FK_GuiaConTitulo_Titulo FOREIGN KEY (ID_TituloAcademico)
        REFERENCES personal.TituloAcademico(ID)
);
GO

CREATE TABLE personal.GuiaConHabilitacion (
    CUIL_GuiaAutorizado     BIGINT  NOT NULL,
    ID_HabilitacionGuia     INT     NOT NULL,
    FechaObtenido           DATE    NOT NULL,
    FechaExpiracion         DATE    NOT NULL,

    CONSTRAINT PK_GuiaConHabilitacion PRIMARY KEY (CUIL_GuiaAutorizado, ID_HabilitacionGuia),
    CONSTRAINT FK_GuiaConHabilitacion_Guia FOREIGN KEY (CUIL_GuiaAutorizado)
        REFERENCES personal.GuiaAutorizado(CUIL),
    CONSTRAINT FK_GuiaConHabilitacion_Habilitacion FOREIGN KEY (ID_HabilitacionGuia)
        REFERENCES personal.HabilitacionGuia(ID)
);
GO

CREATE TABLE personal.GuiaConEspecialidad (
    CUIL_GuiaAutorizado BIGINT  NOT NULL,
    ID_EspecialidadGuia INT     NOT NULL,
    FechaObtenida       DATE    NOT NULL,

    CONSTRAINT PK_GuiaConEspecialidad PRIMARY KEY (CUIL_GuiaAutorizado, ID_EspecialidadGuia),
    CONSTRAINT FK_GuiaConEspecialidad_Guia FOREIGN KEY (CUIL_GuiaAutorizado)
        REFERENCES personal.GuiaAutorizado(CUIL),
    CONSTRAINT FK_GuiaConEspecialidad_Especialidad FOREIGN KEY (ID_EspecialidadGuia)
        REFERENCES personal.EspecialidadGuia(ID)
);
GO

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
GO

CREATE TABLE personal.ContratoTrabajo (
    ID                  INT IDENTITY(1,1)   NOT NULL,
    ID_AreaProtegida    BIGINT              NOT NULL,
    CUIL_Guardaparques  BIGINT              NOT NULL,
    FechaInicio         DATE                NOT NULL,
    FechaFin            DATE                NULL,

    CONSTRAINT PK_ContratoTrabajo PRIMARY KEY (ID),
    CONSTRAINT FK_ContratoTrabajo_Parque FOREIGN KEY (ID_AreaProtegida)
        REFERENCES parque.AreaProtegida(ID),
    CONSTRAINT FK_ContratoTrabajo_Guardaparques FOREIGN KEY (CUIL_Guardaparques)
        REFERENCES personal.Guardaparques(CUIL)
);
GO

CREATE TABLE personal.PermisoDeTrabajo (
    ID                  INT IDENTITY(1,1)   NOT NULL,
    ID_AreaProtegida    BIGINT              NOT NULL,
    CUIL_GuiaAutorizado BIGINT              NOT NULL,
    FechaInicio         DATE                NOT NULL,
    FechaFin            DATE                NULL,

    CONSTRAINT PK_PermisoDeTrabajo PRIMARY KEY (ID),
    CONSTRAINT FK_PermisoDeTrabajo_Parque FOREIGN KEY (ID_AreaProtegida)
        REFERENCES parque.AreaProtegida(ID),
    CONSTRAINT FK_PermisoDeTrabajo_Guia FOREIGN KEY (CUIL_GuiaAutorizado)
        REFERENCES personal.GuiaAutorizado(CUIL)
);
GO

/* ------------------------------------------------------ *
 | ESQUEMA: actividad
 * ------------------------------------------------------ */

CREATE TABLE actividad.TipoActividad (
    ID      INT IDENTITY(1,1) NOT NULL,
    Nombre  VARCHAR(50)       NOT NULL,
    CONSTRAINT PK_TipoActividad PRIMARY KEY (ID)
);
GO

CREATE TABLE actividad.Actividad (
    ID                  INT IDENTITY(1,1) NOT NULL,
    ID_AreaProtegida    BIGINT            NOT NULL,
    ID_TipoActividad    INT               NOT NULL,
    Nombre              VARCHAR(50)       NOT NULL,
    Duracion            INT               NULL,
    Costo               DECIMAL(12,2)     NOT NULL,
    CupoMaximo          INT               NULL,

    CONSTRAINT PK_Actividad PRIMARY KEY (ID),
    CONSTRAINT FK_Actividad_AreaProtegida FOREIGN KEY (ID_AreaProtegida)
        REFERENCES parque.AreaProtegida(ID),
    CONSTRAINT FK_Actividad_TipoActividad FOREIGN KEY (ID_TipoActividad)
        REFERENCES actividad.TipoActividad(ID)
);
GO

CREATE TABLE actividad.InscripcionActividad (
    ID              INT IDENTITY(1,1)   NOT NULL,
    ID_Actividad    INT                 NOT NULL,
    ID_Comprobante  INT                 NULL,
    FechaHora       DATETIME            NULL,
    PrecioCobrado   DECIMAL(12,2)       NULL,

    CONSTRAINT PK_InscripcionActividad PRIMARY KEY (ID),
    CONSTRAINT FK_InscripcionActividad_Actividad FOREIGN KEY (ID_Actividad)
        REFERENCES actividad.Actividad(ID),
    CONSTRAINT FK_InscripcionActividad_Comprobante FOREIGN KEY (ID_Comprobante)
        REFERENCES venta.Comprobante(ID)
);
GO

CREATE TABLE actividad.GuiaAsignadoTour (
    ID_Actividad        INT     NOT NULL,
    CUIL_GuiaAutorizado BIGINT  NOT NULL,

    CONSTRAINT PK_GuiaAsignadoTour PRIMARY KEY (ID_Actividad, CUIL_GuiaAutorizado),
    CONSTRAINT FK_GuiaAsignadoTour_Actividad FOREIGN KEY (ID_Actividad)
        REFERENCES actividad.Actividad(ID),
    CONSTRAINT FK_GuiaAsignadoTour_GuiaAutorizado FOREIGN KEY (CUIL_GuiaAutorizado)
        REFERENCES personal.GuiaAutorizado(CUIL)
);
GO

/* ------------------------------------------------------ *
 | ESQUEMA: concesion
 * ------------------------------------------------------ */

CREATE TABLE concesion.ActividadFiscal (
    ID          INT IDENTITY(1,1)   NOT NULL,
    Nombre      VARCHAR(100)        NULL,

    CONSTRAINT PK_ActividadFiscal PRIMARY KEY (ID)
);
GO

CREATE TABLE concesion.Empresa ( -- SE PUEDE QUITAR SI SOLO ES UNA TABLA PARA GUARDAR EL NOMBRE DE LA EMPRESA
    CUIT    BIGINT       NOT NULL,
    Nombre  VARCHAR(150) NULL,

    CONSTRAINT PK_Empresa PRIMARY KEY (CUIT)
);
GO

CREATE TABLE concesion.TipoConcesion (
    ID                  INT IDENTITY(1,1)   NOT NULL,
    ID_ActividadFiscal  INT                 NOT NULL,
    Nombre              VARCHAR(100)        NOT NULL,

    CONSTRAINT PK_TipoConcesion PRIMARY KEY (ID),
    CONSTRAINT FK_TipoConcesion_ActividadFiscal FOREIGN KEY (ID_ActividadFiscal)
        REFERENCES concesion.ActividadFiscal(ID)
);
GO

CREATE TABLE concesion.ActividadFiscalInscriptaEmpresa (
    CUIT_Empresa        BIGINT  NOT NULL,
    ID_ActividadFiscal  INT     NOT NULL,
    Principal           BIT     NOT NULL CONSTRAINT DF_ActividadFiscalInscriptaEmpresa_Principal DEFAULT (0),
    CONSTRAINT PK_ActividadFiscalInscriptaEmpresa PRIMARY KEY (CUIT_Empresa, ID_ActividadFiscal),
    CONSTRAINT FK_ActividadFiscalInscriptaEmpresa_Empresa FOREIGN KEY (CUIT_Empresa)
        REFERENCES concesion.Empresa(CUIT),
    CONSTRAINT FK_ActividadFiscalInscriptaEmpresa_ActividadFiscal FOREIGN KEY (ID_ActividadFiscal)
        REFERENCES concesion.ActividadFiscal(ID)
);
GO

CREATE TABLE concesion.Concesion (
    ID                  INT IDENTITY(1,1)   NOT NULL,
    ID_AreaProtegida    BIGINT              NOT NULL,
    CUIT_Empresa        BIGINT              NOT NULL,
    ID_TipoConcesion    INT                 NOT NULL,
    FechaInicio         DATE                NOT NULL,
    FechaFin            DATE                NOT NULL,
    Canon               DECIMAL(20,2)       NOT NULL,

    CONSTRAINT PK_Concesion PRIMARY KEY (ID),
    CONSTRAINT FK_Concesion_Parque FOREIGN KEY (ID_AreaProtegida)
        REFERENCES parque.AreaProtegida(ID),
    CONSTRAINT FK_Concesion_Empresa FOREIGN KEY (CUIT_Empresa)
        REFERENCES concesion.Empresa(CUIT),
    CONSTRAINT FK_Concesion_TipoConcesion FOREIGN KEY (ID_TipoConcesion)
        REFERENCES concesion.TipoConcesion(ID)
);
GO

CREATE TABLE concesion.FacturaConcesion (
    ID                  INT IDENTITY(1,1)   NOT NULL,
    ID_Concesion        INT                 NOT NULL,
    FechaEmision        DATE                NOT NULL,
    FechaVencimiento    DATE                NOT NULL,
    MontoEsperado       DECIMAL(20,2)       NOT NULL,

    CONSTRAINT PK_FacturaConcesion PRIMARY KEY (ID),
    CONSTRAINT FK_FacturaConcesion_Concesion FOREIGN KEY (ID_Concesion)
        REFERENCES concesion.Concesion(ID)
);
GO

CREATE TABLE concesion.PagoConcesion (
    ID          INT IDENTITY(1,1)   NOT NULL,
    ID_Factura  INT                 NOT NULL,
    FechaPago   DATE                NOT NULL,
    MontoPagado DECIMAL(20,2)       NOT NULL,

    CONSTRAINT PK_PagoConcesion PRIMARY KEY (ID),
    CONSTRAINT FK_PagoConcesion_Factura FOREIGN KEY (ID_Factura)
        REFERENCES concesion.FacturaConcesion(ID)
);
GO