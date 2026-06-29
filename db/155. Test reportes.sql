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
* Fecha: 29/06/2026
* Script: 155. Test reportes
* Descripción: Pruebas y evidencia para los stored procedures de reportes.
*/

USE com2900;
GO

PRINT('Reporte 1: visitas por parque agrupadas por mes');
EXEC reporte.VisitasPorPeriodoParque
	@FechaDesde = '2025-01-01',
	@FechaHasta = '2026-12-31',
	@Agrupacion = 'MES';
GO

PRINT('Reporte 1: visitas por parque agrupadas por semana');
EXEC reporte.VisitasPorPeriodoParque
	@FechaDesde = '2025-01-01',
	@FechaHasta = '2026-12-31',
	@Agrupacion = 'SEMANA';
GO

PRINT('Reporte 2: ingresos por parque por mes');
EXEC reporte.IngresosPorPeriodoParque
	@FechaDesde = '2025-01-01',
	@FechaHasta = '2026-12-31',
	@Agrupacion = 'MES';
GO

PRINT('Reporte 3: concesiones deudoras tabular');
EXEC reporte.ConcesionesDeudoras
	@FechaCorte = '2026-06-29';
GO

PRINT('Reporte 3 XML: concesiones deudoras');
EXEC reporte.ConcesionesDeudorasXml
	@FechaCorte = '2026-06-29';
GO

PRINT('Reporte 4: matriz de visitas por mes y parque');
EXEC reporte.MatrizVisitasMensual
	@Anio = 2025;
GO

PRINT('Reporte 5 XML: parques con concesiones anidadas');
EXEC reporte.ParquesConConcesionesXml;
GO

PRINT('Reporte adicional: actividades mas demandadas');
EXEC reporte.ActividadesMasDemandadas
	@FechaDesde = '2025-01-01',
	@FechaHasta = '2026-12-31',
	@Top = 10;
GO

PRINT('Caso fallido: agrupacion invalida');
BEGIN TRY
	EXEC reporte.VisitasPorPeriodoParque
		@FechaDesde = '2025-01-01',
		@FechaHasta = '2025-12-31',
		@Agrupacion = 'DIA';
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO

PRINT('Caso fallido: anio invalido para matriz');
BEGIN TRY
	EXEC reporte.MatrizVisitasMensual
		@Anio = 1900;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;
GO
