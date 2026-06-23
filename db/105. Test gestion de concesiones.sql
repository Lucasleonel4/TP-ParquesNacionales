/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emmanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Fecha: 23/06/2026
* Script: 105. Test gestion de concesiones
* Descripción: Pruebas exitosas y fallidas para gestion de concesiones.
*/

USE com2900;
GO

DECLARE @IDParque BIGINT = 900004;
DECLARE @IDConcesion INT;
DECLARE @FacturasAntes INT;
DECLARE @ConcesionesAntes INT;

IF NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @IDParque)
	EXEC parque.SP_AreaProtegida_Insert @ID = @IDParque, @TipoArea = 'Parque Nacional', @Nombre = 'Parque Test Concesion', @Superficie = 1000;

PRINT('Caso exitoso: alta integral de concesion');

CREATE TABLE #ResultadoConcesion (
	ID_Concesion INT,
	ID_TipoConcesion INT,
	ID_ActividadFiscal INT
);

INSERT INTO #ResultadoConcesion
EXEC concesion.sp_Negocio_AltaIntegralConcesion
	@ID_AreaProtegida = @IDParque,
	@CUIT_Empresa = 30999000111,
	@NombreEmpresa = 'Empresa Test Concesion',
	@NombreActividadFiscal = 'Gastronomia Test',
	@NombreTipoConcesion = 'Kiosco Test',
	@FechaInicio = '2026-07-01',
	@FechaFin = '2026-12-31',
	@Canon = 100000,
	@FechaEmisionFactura = '2026-07-01',
	@FechaVencimientoFactura = '2026-07-10';

SELECT @IDConcesion = ID_Concesion FROM #ResultadoConcesion;

SELECT C.ID, C.CUIT_Empresa, C.Canon, F.ID AS ID_Factura, F.MontoEsperado
FROM concesion.Concesion C
JOIN concesion.FacturaConcesion F ON F.ID_Concesion = C.ID
WHERE C.ID = @IDConcesion;

DROP TABLE #ResultadoConcesion;

PRINT('Caso fallido: ABM con multiples validaciones acumuladas');
BEGIN TRY
	EXEC concesion.sp_Concesion_Alta
		@ID_AreaProtegida = -1,
		@CUIT_Empresa = -1,
		@ID_TipoConcesion = -1,
		@FechaInicio = '2026-12-31',
		@FechaFin = '2026-01-01',
		@Canon = 0;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT @ConcesionesAntes = COUNT(*) FROM concesion.Concesion;
SELECT @FacturasAntes = COUNT(*) FROM concesion.FacturaConcesion;

PRINT('Caso fallido: alta integral con multiples validaciones y evidencia de rollback');
BEGIN TRY
	EXEC concesion.sp_Negocio_AltaIntegralConcesion
		@ID_AreaProtegida = -1,
		@CUIT_Empresa = 0,
		@NombreEmpresa = '',
		@NombreActividadFiscal = '',
		@NombreTipoConcesion = '',
		@FechaInicio = '2026-12-31',
		@FechaFin = '2026-01-01',
		@Canon = -1,
		@FechaEmisionFactura = '2026-08-01',
		@FechaVencimientoFactura = '2026-07-01';
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT
	@ConcesionesAntes AS ConcesionesAntes,
	(SELECT COUNT(*) FROM concesion.Concesion) AS ConcesionesDespues,
	@FacturasAntes AS FacturasAntes,
	(SELECT COUNT(*) FROM concesion.FacturaConcesion) AS FacturasDespues;
GO


