/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emmanuel Américo
*  - Ruiz Carletti, Emiliano
* Fecha: 28/06/2026
* Script: 135. Test integracion APIs
* Descripción: Pruebas exitosas y fallidas para consumo de APIs publicas.
*/

USE com2900;
GO

/*
IMPORTANTE:
Para ejecutar estos tests, la instancia SQL Server debe tener habilitado Ole Automation Procedures.
Debe ejecutarlo un login con permisos de sysadmin:

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
*/

PRINT('Caso exitoso/repetible: importar feriados dos veces');
BEGIN TRY
	EXEC integracion.FeriadoImportarActualizar @Anio = 2026;
	EXEC integracion.FeriadoImportarActualizar @Anio = 2026;

	SELECT COUNT(*) AS Feriados2026
	FROM integracion.FeriadoArgentina
	WHERE Anio = 2026;

	SELECT TOP 10 Fecha, Tipo, Nombre
	FROM integracion.FeriadoArgentina
	WHERE Anio = 2026
	ORDER BY Fecha;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO

PRINT('Caso exitoso/repetible: importar cotizacion dolar y actualizar divisa USD');
BEGIN TRY
	EXEC integracion.CotizacionDolarImportarActualizar
		@ActualizarDivisa = 1,
		@CasaDivisa = 'oficial';

	EXEC integracion.CotizacionDolarImportarActualizar
		@ActualizarDivisa = 1,
		@CasaDivisa = 'oficial';

	SELECT TOP 10 Casa, Nombre, Moneda, Compra, Venta, FechaActualizacion, FechaConsulta
	FROM integracion.CotizacionDolar
	ORDER BY FechaConsulta DESC, ID DESC;

	SELECT COD_ISO, Pais, ValorEnPesos
	FROM venta.Divisa
	WHERE COD_ISO = 'USD';
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO

PRINT('Caso exitoso: consultar si una fecha es feriado');
DECLARE @EsFeriado BIT;
DECLARE @NombreFeriado VARCHAR(200);

EXEC integracion.FeriadoConsultar
	@Fecha = '2026-01-01',
	@EsFeriado = @EsFeriado OUTPUT,
	@Nombre = @NombreFeriado OUTPUT;

SELECT @EsFeriado AS EsFeriado, @NombreFeriado AS NombreFeriado;
GO

PRINT('Caso exitoso: obtener ultima cotizacion oficial del dolar');
BEGIN TRY
	DECLARE @ValorVenta DECIMAL(18,4);

	EXEC integracion.DolarCotizacionObtener
		@Casa = 'oficial',
		@ValorVenta = @ValorVenta OUTPUT;

	SELECT @ValorVenta AS ValorVentaDolarOficial;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO

PRINT('Caso fallido: anio de feriados fuera de rango');
BEGIN TRY
	EXEC integracion.FeriadoImportarActualizar @Anio = 1900;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO

PRINT('Caso fallido: cotizacion inexistente');
BEGIN TRY
	DECLARE @ValorVentaInexistente DECIMAL(18,4);

	EXEC integracion.DolarCotizacionObtener
		@Casa = 'casa-inexistente',
		@ValorVenta = @ValorVentaInexistente OUTPUT;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO