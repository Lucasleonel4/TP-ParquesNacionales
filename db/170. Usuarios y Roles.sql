/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Mancilla Muñoz, Emmanuel Américo
*  - Ruiz Carletti, Emiliano
*  - Costilla, Lucas Leonel
* Fecha: 30/06/2026
* Script: 170. Usuarios y Roles
* Descripción: Se crean usuarios y se les asignan responsabilidades (admin, importador, consultas, personal, pdv [punto de venta])
*/

USE com2900
GO

-- ============================================================
-- CREACIÓN DE ROLES
-- ============================================================

-- ADMINISTRADOR
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'administrador')
	BEGIN
		CREATE ROLE administrador;
		PRINT('OK: Rol "administrador" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "administrador" ya existe');
	GO

-- IMPORTADOR DE ÁREAS
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'importadorAreas')
	BEGIN
		CREATE ROLE importadorAreas;
		PRINT('OK: Rol "importadorAreas" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "importadorAreas" ya existe');
	GO

-- CONSULTAS SOLO
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'consultas')
	BEGIN
		CREATE ROLE consultas;
		PRINT('OK: Rol "consultas" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "consultas" ya existe');
	GO

-- GESTIÓN DE ÁREAS PROTEGIDAS
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'gestionArea')
	BEGIN
		CREATE ROLE gestionArea;
		PRINT('OK: Rol "gestionArea" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "gestionArea" ya existe');
	GO

-- GESTIÓN DE VENTAS
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'gestionVenta')
	BEGIN
		CREATE ROLE gestionVenta;
		PRINT('OK: Rol "gestionVenta" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "gestionVenta" ya existe');
	GO

-- GESTIÓN DE ACTIVIDADES
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'gestionActividad')
	BEGIN
		CREATE ROLE gestionActividad
		PRINT('OK: Rol "gestionActividad" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "gestionActividad" ya existe');
	GO

-- GESTIÓN DE CONCESIONES
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'gestionConcesion')
	BEGIN
		CREATE ROLE gestionConcesion;
		PRINT('OK: Rol "gestionConcesion" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "gestionConcesion" ya existe');
	GO

-- GESTIÓN DE PERSONAL
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'gestionPersonal')
	BEGIN
		CREATE ROLE gestionPersonal;
		PRINT('OK: Rol "gestionPersonal" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "gestionPersonal" ya existe');
	GO

-- PUNTO DE VENTA OPERACIONES
	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE type IN ('R') AND name = 'operacionPDV')
	BEGIN
		CREATE ROLE operacionPDV;
		PRINT('OK: Rol "operacionPDV" creado exitosamente');
	END
	ELSE PRINT('INFO: Rol "operacionPDV" ya existe');
	GO


-- ============================================================
-- ASIGNACIÓN DE PERMISOS PARA CADA ROL
-- ============================================================

-- [administrador] -> ADMINISTRADOR
	GRANT CONTROL ON DATABASE::com2900 TO administrador
	GO

-- [importadorAreas] -> IMPORTADOR DE ÁREAS PROTEGIDAS
	GRANT EXECUTE ON OBJECT::[parque].[ProvinciaImportarActualizar]		TO importadorAreas
	GRANT EXECUTE ON OBJECT::[parque].[AreaProtegidaImportarActualizar] TO importadorAreas
	GRANT EXECUTE ON OBJECT::[parque].[CentroideImportar]				TO importadorAreas
	GRANT EXECUTE ON OBJECT::[parque].[AreaProtegidaConsulta]		    TO importadorAreas
	GRANT EXECUTE ON OBJECT::[parque].[AreaProtegidaModificacion]		TO importadorAreas
	GRANT EXECUTE ON SCHEMA::[integracion]								TO importadorAreas
	GO

-- [consultas] -> CONSULTAS SOLO
	GRANT SELECT ON SCHEMA::[parque] TO consultas
		GRANT EXECUTE ON OBJECT::[parque].[AreaProtegidaConsulta]			TO consultas
		GRANT EXECUTE ON OBJECT::[parque].[ProvinciaConsulta]				TO consultas
		GRANT EXECUTE ON OBJECT::[parque].[ProvinciaContieneParqueConsulta] TO consultas

	GRANT SELECT ON SCHEMA::[venta] TO consultas
		GRANT EXECUTE ON OBJECT::[venta].[DivisaConsulta]					TO consultas
		GRANT EXECUTE ON OBJECT::[venta].[TipoEntradaConsulta]				TO consultas
		GRANT EXECUTE ON OBJECT::[venta].[TipoEntradaParqueConsulta]		TO consultas
		GRANT EXECUTE ON OBJECT::[venta].[ComprobanteConsulta]				TO consultas
		GRANT EXECUTE ON OBJECT::[venta].[EntradaConsulta]					TO consultas

	GRANT SELECT ON SCHEMA::[actividad] TO consultas
		GRANT EXECUTE ON OBJECT::[actividad].[TipoActividadConsulta]		TO consultas
		GRANT EXECUTE ON OBJECT::[actividad].[ActividadConsulta]			TO consultas
		GRANT EXECUTE ON OBJECT::[actividad].[InscripcionActividadConsulta] TO consultas
		GRANT EXECUTE ON OBJECT::[actividad].[GuiaAsignadoTourConsulta]		TO consultas

	GRANT SELECT ON SCHEMA::[personal]	TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[GuiaAutorizadoConsulta]		TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[TituloAcademicoConsulta]		TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[HabilitacionGuiaConsulta]		TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[EspecialidadGuiaConsulta]		TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[GuiaConTituloConsulta]			TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[GuiaConHabilitacionConsulta]	TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[GuiaConEspecialidadConsulta]	TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[GuardaparquesConsulta]			TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[ContratoTrabajoConsulta]		TO consultas
		GRANT EXECUTE ON OBJECT::[personal].[PermisoDeTrabajoConsulta]		TO consultas

	GRANT SELECT ON SCHEMA::[concesion] TO consultas
		GRANT EXECUTE ON OBJECT::[concesion].[ActividadFiscalConsulta]					TO consultas
		GRANT EXECUTE ON OBJECT::[concesion].[EmpresaConsulta]							TO consultas
		GRANT EXECUTE ON OBJECT::[concesion].[TipoConcesionConsulta]					TO consultas
		GRANT EXECUTE ON OBJECT::[concesion].[ActividadFiscalInscriptaEmpresaConsulta]	TO consultas
		GRANT EXECUTE ON OBJECT::[concesion].[ConcesionConsulta]						TO consultas
		GRANT EXECUTE ON OBJECT::[concesion].[FacturaConcesionConsulta]					TO consultas
		GRANT EXECUTE ON OBJECT::[concesion].[PagoConcesionConsulta]					TO consultas

	GRANT EXECUTE ON SCHEMA::[reporte] TO consultas
	GO
-- [gestionArea] -> GESTIÓN DE ÁREAS 
	GRANT SELECT  ON SCHEMA::[parque] TO gestionArea
	GRANT EXECUTE ON SCHEMA::[parque] TO gestionArea
	GO

-- [gestionVenta] -> GESTIÓN DE VENTAS
	GRANT SELECT  ON SCHEMA::[venta] TO gestionVenta
	GRANT EXECUTE ON SCHEMA::[venta] TO gestionVenta
	GO

-- [gestionConcesion] -> GESTIÓN DE CONCESIONES
	GRANT SELECT  ON SCHEMA::[concesion] TO gestionConcesion
	GRANT EXECUTE ON SCHEMA::[concesion] TO gestionConcesion
	GO

-- [gestionActividad] -> GESTIÓN DE ACTIVIDADES
	GRANT SELECT  ON SCHEMA::[actividad] TO gestionActividad
	GRANT EXECUTE ON SCHEMA::[actividad] TO gestionActividad
	GO

-- [gestionPersonal] -> GESTIÓN DE PERSONAL
	GRANT SELECT  ON SCHEMA::[personal]	TO gestionPersonal
	GRANT EXECUTE ON SCHEMA::[personal] TO gestionPersonal
	GO

-- [operacionPDV] -> PUNTO DE VENTA OPERACIONES
	GRANT EXECUTE ON OBJECT::[venta].[VentaEntradasMismoTipoRegistrar]	  TO operacionPDV
	GRANT EXECUTE ON OBJECT::[venta].[VentaEntradasDistintoTipoRegistrar] TO operacionPDV
	GRANT EXECUTE ON OBJECT::[venta].[VentaEntradasYActividadesRegistrar] TO operacionPDV
	GRANT EXECUTE ON OBJECT::[actividad].[ActividadRegistrar]			  TO operacionPDV
	GO


-- ============================================================
-- NOTA SOBRE LOGINS Y USUARIOS
-- ============================================================
-- Por seguridad del repositorio publico, este script no versiona contrasenas ni crea logins con claves fijas.
-- Los roles y permisos quedan definidos en la base. En un ambiente real, el DBA debe crear los logins/usuarios
-- correspondientes y asociarlos a estos roles con ALTER ROLE ... ADD MEMBER.
/*
CONCEPTOS GENERALES:
	- LOGIN:	Permite acceder al servidor (p.ej.: localhost\\sqlexpress) pero no otorga permisos de consulta o manipulación de ninguna bd (ej.: com2900). Puede tener solo 1 (un) usuario asociado.
	
	- USUARIO:  Se crea a nivel BD y se asocia a un LOGIN. Su nombre puede ser distinto al del login. A este usuario se le confieren diferentes responsabilidades sobre la BD mediante permisos explícitos.
				Existe el USUARIO DBO con permisos para realizar todas las actividades en la BD.

	- ROL:		Es un agrupador de responsabilidades y niveles de acceso asignados al rol, al darle asignarle permisos explícitos al rol dado. Luego los LOGINs pueden suscribir a este ROL y sus usuarios
				tener los permisos y niveles de acceso asignados para el rol. Es mas recomendado que darle permisos a los USUARIOs directamente.
*/
