/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comision: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Munoz, Emanuel Americo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Fecha: 23/06/2026
* Script: 075. Test venta de entradas
* Descripcion: Pruebas exitosas y fallidas para la venta de entradas.
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
	EXEC parque.SP_AreaProtegida_Insert @ID = @IDParque, @TipoArea = 'Parque Nacional', @Nombre = 'Parque Test Venta', @Superficie = 1000;

IF NOT EXISTS (SELECT 1 FROM parque.PuntoDeVenta WHERE ID_AreaProtegida = @IDParque AND Descripcion = 'Boleteria Test')
	EXEC parque.SP_PuntoDeVenta_Insert @ID_AreaProtegida = @IDParque, @Descripcion = 'Boleteria Test';

SELECT @IDPuntoVenta = ID FROM parque.PuntoDeVenta WHERE ID_AreaProtegida = @IDParque AND Descripcion = 'Boleteria Test';

IF NOT EXISTS (SELECT 1 FROM venta.Divisa WHERE COD_ISO = 'ARS')
	EXEC venta.SP_Divisa_Insert @COD_ISO = 'ARS', @Pais = 'Argentina', @ValorEnPesos = 1;

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntrada WHERE Nombre = 'General Test')
	EXEC venta.SP_TipoEntrada_Insert @Nombre = 'General Test';

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntrada WHERE Nombre = 'Menor Test')
	EXEC venta.SP_TipoEntrada_Insert @Nombre = 'Menor Test';

SELECT @IDTipoGeneral = ID FROM venta.TipoEntrada WHERE Nombre = 'General Test';
SELECT @IDTipoMenor = ID FROM venta.TipoEntrada WHERE Nombre = 'Menor Test';

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntradaParque WHERE ID_AreaProtegida = @IDParque AND ID_TipoEntrada = @IDTipoGeneral)
	EXEC venta.SP_TipoEntradaParque_Insert @ID_AreaProtegida = @IDParque, @ID_TipoEntrada = @IDTipoGeneral, @Precio = 5000;

IF NOT EXISTS (SELECT 1 FROM venta.TipoEntradaParque WHERE ID_AreaProtegida = @IDParque AND ID_TipoEntrada = @IDTipoMenor)
	EXEC venta.SP_TipoEntradaParque_Insert @ID_AreaProtegida = @IDParque, @ID_TipoEntrada = @IDTipoMenor, @Precio = 2500;

PRINT('Caso exitoso: venta de entradas del mismo tipo');

EXEC venta.SP_Negocio_RegistrarVentaEntradasMismoTipo
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

EXEC venta.SP_Negocio_RegistrarVentaEntradasDistintoTipo
	@ID_PuntoDeVenta = @IDPuntoVenta,
	@COD_ISO_Divisa = 'ARS',
	@MedioDePago = 'Tarjeta',
	@FechaHora = '2026-06-23T20:10:00',
	@ID_AreaProtegida = @IDParque,
	@Detalle = @Detalle;

PRINT('Caso fallido: cantidad invalida');
BEGIN TRY
	EXEC venta.SP_Negocio_RegistrarVentaEntradasMismoTipo
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

	EXEC venta.SP_Negocio_RegistrarVentaEntradasDistintoTipo
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
GO
