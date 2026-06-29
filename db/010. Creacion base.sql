/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emmanuel Américo
*  - Ruiz Carletti, Emiliano
* Fecha: 23/06/2026
* Script: 010. Creacion base
* Descripción: Inicializa la base de datos
*/

IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = 'com2900')
    BEGIN TRY
	    CREATE DATABASE com2900;
	    PRINT('OK: base de datos com2900 creada exitosamente');
	END TRY
	BEGIN CATCH;
		PRINT('ERROR: No se pudo crear la base de datos com2900');
		THROW;
	END CATCH;
ELSE PRINT('INFO: base de datos 2900 ya existe');

