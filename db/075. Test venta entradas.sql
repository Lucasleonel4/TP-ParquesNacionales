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
* Script: 075. Test venta de entradas
* Descripción: Pruebas exitosas y fallidas para la venta de entradas.
*/

USE com2900;
GO

DECLARE @IDParque BIGINT = 900001;
DECLARE @IDPuntoVenta INT;
DECLARE @IDTipoGeneral INT;
DECLARE @IDTipoMenor INT;
DECLARE @ComprobantesAntes INT;
DECLARE @EntradasAntes INT;

IF NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @IDParque)
	EXEC parque.AreaProtegidaAlta @ID = @IDParque, @TipoArea = 'Parque Nacional', @Nombre = 'Parque Test Venta', @Superficie = 1000;

IF NOT EXISTS (SELECT 1 FROM parque.PuntoDeVenta WHERE ID_AreaProtegida = @IDParque AND Descripcion = 'Boleteria Test')
	EXEC parque.PuntoDeVentaAlta @ID_AreaProtegida = @IDParque, @Descripcion = 'Boleteria Test';

SELECT @IDPuntoVenta = ID FROM parque.PuntoDeVenta WHERE ID_AreaProtegida = @IDParque AND Descripcion = 'Boleteria Test';

IF NOT EXISTS (SELECT 1 FROM venta.Divisa WHERE COD_ISO = 'ARS')
	EXEC venta.DivisaAlta @COD_ISO = 'ARS', @Pais = 'Argentina', @ValorEnPesos = 1;

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntrada WHERE Nombre = 'General Test')
	EXEC venta.TipoEntradaAlta @Nombre = 'General Test';

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntrada WHERE Nombre = 'Menor Test')
	EXEC venta.TipoEntradaAlta @Nombre = 'Menor Test';

SELECT @IDTipoGeneral = ID FROM venta.TipoEntrada WHERE Nombre = 'General Test';
SELECT @IDTipoMenor = ID FROM venta.TipoEntrada WHERE Nombre = 'Menor Test';

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntradaParque WHERE ID_AreaProtegida = @IDParque AND ID_TipoEntrada = @IDTipoGeneral)
	EXEC venta.TipoEntradaParqueAlta @ID_AreaProtegida = @IDParque, @ID_TipoEntrada = @IDTipoGeneral, @Precio = 5000;

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntradaParque WHERE ID_AreaProtegida = @IDParque AND ID_TipoEntrada = @IDTipoMenor)
	EXEC venta.TipoEntradaParqueAlta @ID_AreaProtegida = @IDParque, @ID_TipoEntrada = @IDTipoMenor, @Precio = 2500;

PRINT('Caso exitoso: venta de entradas del mismo tipo');

EXEC venta.VentaEntradasMismoTipoRegistrar
	@ID_PuntoDeVenta = @IDPuntoVenta,
	@COD_ISO_Divisa = 'ARS',
	@MedioDePago = 'Efectivo',
	@FechaHora = '2026-06-23T20:00:00',
	@ID_AreaProtegida = @IDParque,
	@ID_TipoEntrada = @IDTipoGeneral,
	@Cantidad = 2;

SELECT TOP 5 C.ID, C.Total, COUNT(E.ID) AS CantidadEntradas
FROM venta.Comprobante C
JOIN venta.Entrada E ON E.ID_Comprobante = C.ID
WHERE C.ID_PuntoDeVenta = @IDPuntoVenta
GROUP BY C.ID, C.Total
ORDER BY C.ID DESC;

PRINT('Caso exitoso: venta de entradas de distinto tipo');

DECLARE @Detalle venta.TipoTablaDetalleEntradas;
INSERT INTO @Detalle(ID_TipoEntrada, Cantidad) VALUES (@IDTipoGeneral, 1), (@IDTipoMenor, 2);

EXEC venta.VentaEntradasDistintoTipoRegistrar
	@ID_PuntoDeVenta = @IDPuntoVenta,
	@COD_ISO_Divisa = 'ARS',
	@MedioDePago = 'Tarjeta',
	@FechaHora = '2026-06-23T20:10:00',
	@ID_AreaProtegida = @IDParque,
	@Detalle = @Detalle;

PRINT('Caso fallido: cantidad invalida');
BEGIN TRY
	EXEC venta.VentaEntradasMismoTipoRegistrar
		@ID_PuntoDeVenta = @IDPuntoVenta,
		@COD_ISO_Divisa = 'ARS',
		@MedioDePago = 'Efectivo',
		@FechaHora = '2026-06-23T20:20:00',
		@ID_AreaProtegida = @IDParque,
		@ID_TipoEntrada = @IDTipoGeneral,
		@Cantidad = 0;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT @ComprobantesAntes = COUNT(*) FROM venta.Comprobante;
SELECT @EntradasAntes = COUNT(*) FROM venta.Entrada;

PRINT('Caso fallido: multiples validaciones y evidencia de rollback');
BEGIN TRY
	DECLARE @DetalleError venta.TipoTablaDetalleEntradas;
	INSERT INTO @DetalleError(ID_TipoEntrada, Cantidad) VALUES (-1, 0), (-1, -2);

	EXEC venta.VentaEntradasDistintoTipoRegistrar
		@ID_PuntoDeVenta = -1,
		@COD_ISO_Divisa = 'ZZZ',
		@MedioDePago = 'Cripto',
		@FechaHora = NULL,
		@ID_AreaProtegida = -1,
		@Detalle = @DetalleError;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT
	@ComprobantesAntes AS ComprobantesAntes,
	(SELECT COUNT(*) FROM venta.Comprobante) AS ComprobantesDespues,
	@EntradasAntes AS EntradasAntes,
	(SELECT COUNT(*) FROM venta.Entrada) AS EntradasDespues;

PRINT('Caso exitoso: venta conjunta de entradas y actividades');

DECLARE @IDTipoActividad INT;
DECLARE @IDActividad INT;
DECLARE @ComprobanteConjunto TABLE (ID_Comprobante INT, Total DECIMAL(12,2));

IF NOT EXISTS (SELECT 1 FROM actividad.TipoActividad WHERE Nombre = 'Actividad Venta Test')
	EXEC actividad.TipoActividadAlta @Nombre = 'Actividad Venta Test';

SELECT @IDTipoActividad = ID
FROM actividad.TipoActividad
WHERE Nombre = 'Actividad Venta Test';

IF NOT EXISTS (SELECT 1 FROM actividad.Actividad WHERE ID_AreaProtegida = @IDParque AND Nombre = 'Excursion Venta Test')
	EXEC actividad.ActividadAlta
		@ID_AreaProtegida = @IDParque,
		@ID_TipoActividad = @IDTipoActividad,
		@Nombre = 'Excursion Venta Test',
		@Duracion = 60,
		@Costo = 750,
		@CupoMaximo = 20;

SELECT @IDActividad = ID
FROM actividad.Actividad
WHERE ID_AreaProtegida = @IDParque
  AND Nombre = 'Excursion Venta Test';

EXEC actividad.ActividadModificacion @ID = @IDActividad, @Costo = 750, @CupoMaximo = 20, @CupoLibre = 20;

DECLARE @EntradasConjuntas venta.TipoTablaDetalleEntradas;
DECLARE @ActividadesConjuntas actividad.TipoTablaDetalleActividad;

INSERT INTO @EntradasConjuntas(ID_TipoEntrada, Cantidad)
VALUES (@IDTipoGeneral, 1);

INSERT INTO @ActividadesConjuntas(ID_Actividad, Cantidad)
VALUES (@IDActividad, 2);

INSERT INTO @ComprobanteConjunto
EXEC venta.VentaEntradasYActividadesRegistrar
	@ID_PuntoDeVenta = @IDPuntoVenta,
	@COD_ISO_Divisa = 'ARS',
	@MedioDePago = 'Transferencia',
	@FechaHora = '2026-06-23T20:30:00',
	@ID_AreaProtegida = @IDParque,
	@DetalleEntrada = @EntradasConjuntas,
	@DetalleActividad = @ActividadesConjuntas;

SELECT
	C.ID,
	C.Total,
	COUNT(DISTINCT E.ID) AS CantidadEntradas,
	COUNT(DISTINCT IA.ID) AS CantidadActividades
FROM @ComprobanteConjunto R
JOIN venta.Comprobante C ON C.ID = R.ID_Comprobante
LEFT JOIN venta.Entrada E ON E.ID_Comprobante = C.ID
LEFT JOIN actividad.InscripcionActividad IA ON IA.ID_Comprobante = C.ID
GROUP BY C.ID, C.Total;

PRINT('Caso fallido: venta conjunta sin cupo suficiente');

SELECT @ComprobantesAntes = COUNT(*) FROM venta.Comprobante;
SELECT @EntradasAntes = COUNT(*) FROM venta.Entrada;
DECLARE @InscripcionesAntes INT;
SELECT @InscripcionesAntes = COUNT(*) FROM actividad.InscripcionActividad;

EXEC actividad.ActividadModificacion @ID = @IDActividad, @CupoLibre = 1;

BEGIN TRY
	DECLARE @EntradasSinCupo venta.TipoTablaDetalleEntradas;
	DECLARE @ActividadesSinCupo actividad.TipoTablaDetalleActividad;

	INSERT INTO @EntradasSinCupo(ID_TipoEntrada, Cantidad)
	VALUES (@IDTipoGeneral, 1);

	INSERT INTO @ActividadesSinCupo(ID_Actividad, Cantidad)
	VALUES (@IDActividad, 2);

	EXEC venta.VentaEntradasYActividadesRegistrar
		@ID_PuntoDeVenta = @IDPuntoVenta,
		@COD_ISO_Divisa = 'ARS',
		@MedioDePago = 'Tarjeta',
		@FechaHora = '2026-06-23T20:40:00',
		@ID_AreaProtegida = @IDParque,
		@DetalleEntrada = @EntradasSinCupo,
		@DetalleActividad = @ActividadesSinCupo;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT
	@ComprobantesAntes AS ComprobantesAntes,
	(SELECT COUNT(*) FROM venta.Comprobante) AS ComprobantesDespues,
	@EntradasAntes AS EntradasAntes,
	(SELECT COUNT(*) FROM venta.Entrada) AS EntradasDespues,
	@InscripcionesAntes AS InscripcionesAntes,
	(SELECT COUNT(*) FROM actividad.InscripcionActividad) AS InscripcionesDespues;
GO

