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
* Script: 115. Test importacion de datos
* Descripción: Pruebas repetibles para importacion/upsert de datos externos.
*/

USE com2900;
GO

DECLARE @RutaProvincias NVARCHAR(MAX) = N'C:\SQLImport\Provincias_UTF-16LE.json';
DECLARE @RutaAreas VARCHAR(MAX) = 'C:\SQLImport\WDPA_WDOECM_Jun2026_Public_ARG_csv.csv';
DECLARE @RutaCentroides VARCHAR(MAX) = 'C:\SQLImport\centroides\geojson_shapefile_1.csv';

PRINT('Caso exitoso/repetible: importar provincias dos veces');
EXEC parque.ProvinciaImportarActualizar @sourceData = @RutaProvincias;
EXEC parque.ProvinciaImportarActualizar @sourceData = @RutaProvincias;

SELECT TOP 10 ID, Nombre
FROM parque.Provincia
ORDER BY ID;

PRINT('Caso exitoso/repetible: importar areas protegidas dos veces');
EXEC parque.AreaProtegidaImportarActualizar @sourceData = @RutaAreas;
EXEC parque.AreaProtegidaImportarActualizar @sourceData = @RutaAreas;

SELECT TOP 10 ID, TipoArea, Nombre, Superficie
FROM parque.AreaProtegida
ORDER BY ID;

PRINT('Caso exitoso/repetible: importar centroides y vincular coordenadas');
EXEC parque.CentroideImportar @sourceData = @RutaCentroides;

SELECT TOP 10 ID, Nombre, Latitud, Longitud
FROM parque.AreaProtegida
WHERE Latitud IS NOT NULL OR Longitud IS NOT NULL
ORDER BY ID;

PRINT('Caso fallido: ruta inexistente');
BEGIN TRY
	EXEC parque.ProvinciaImportarActualizar @sourceData = N'C:\ruta\inexistente\provincias.json';
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO

