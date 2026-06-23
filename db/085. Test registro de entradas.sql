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
* Script: 085. Test registro de actividades
* Descripcion: Pruebas exitosas y fallidas para registro/contratacion de actividades.
*/

USE com2900;
GO

DECLARE @IDParque BIGINT = 900002;
DECLARE @IDTipoActividad INT;
DECLARE @IDActividad INT;
DECLARE @IDPuntoVenta INT;
DECLARE @IDComprobante INT;
DECLARE @Antes INT;

IF NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @IDParque)
	EXEC parque.SP_AreaProtegida_Insert @ID = @IDParque, @TipoArea = 'Parque Nacional', @Nombre = 'Parque Test Actividad', @Superficie = 1000;

IF NOT EXISTS (SELECT 1 FROM actividad.TipoActividad WHERE Nombre = 'Trekking Test')
	EXEC actividad.SP_TipoActividad_Insert @Nombre = 'Trekking Test';

SELECT @IDTipoActividad = ID FROM actividad.TipoActividad WHERE Nombre = 'Trekking Test';

IF NOT EXISTS (SELECT 1 FROM actividad.Actividad WHERE ID_AreaProtegida = @IDParque AND Nombre = 'Sendero Test')
	EXEC actividad.SP_Actividad_Insert @ID_AreaProtegida = @IDParque, @ID_TipoActividad = @IDTipoActividad, @Nombre = 'Sendero Test', @Duracion = 120, @Costo = 1500, @CupoMaximo = 5;

SELECT @IDActividad = ID FROM actividad.Actividad WHERE ID_AreaProtegida = @IDParque AND Nombre = 'Sendero Test';

DECLARE @IDInscripcionBorrar INT;
WHILE EXISTS (SELECT 1 FROM actividad.InscripcionActividad WHERE ID_Actividad = @IDActividad)
BEGIN
	SELECT TOP 1 @IDInscripcionBorrar = ID
	FROM actividad.InscripcionActividad
	WHERE ID_Actividad = @IDActividad;

	EXEC actividad.SP_InscripcionActividad_Delete @ID = @IDInscripcionBorrar;
END

IF NOT EXISTS (SELECT 1 FROM parque.PuntoDeVenta WHERE ID_AreaProtegida = @IDParque AND Descripcion = 'Caja Actividad Test')
	EXEC parque.SP_PuntoDeVenta_Insert @ID_AreaProtegida = @IDParque, @Descripcion = 'Caja Actividad Test';

SELECT @IDPuntoVenta = ID FROM parque.PuntoDeVenta WHERE ID_AreaProtegida = @IDParque AND Descripcion = 'Caja Actividad Test';

IF NOT EXISTS (SELECT 1 FROM venta.Divisa WHERE COD_ISO = 'ARS')
	EXEC venta.SP_Divisa_Insert @COD_ISO = 'ARS', @Pais = 'Argentina', @ValorEnPesos = 1;

EXEC venta.SP_Comprobante_Insert
	@ID_PuntoDeVenta = @IDPuntoVenta,
	@COD_ISO_Divisa = 'ARS',
	@MedioDePago = 'Efectivo',
	@FechaHora = '2026-06-23T21:00:00',
	@Total = 3000,
	@IDComprobante = @IDComprobante OUTPUT;

PRINT('Caso exitoso: registro de actividad paga');
EXEC actividad.SP_Negocio_RegistrarActividad
	@ID_AreaProtegida = @IDParque,
	@ID_Actividad = @IDActividad,
	@ID_Comprobante = @IDComprobante,
	@FechaHora = '2026-06-24T10:00:00',
	@Cantidad = 2;

SELECT ID_Actividad, ID_Comprobante, COUNT(*) AS Inscriptos, SUM(PrecioCobrado) AS TotalCobrado
FROM actividad.InscripcionActividad
WHERE ID_Actividad = @IDActividad
GROUP BY ID_Actividad, ID_Comprobante;

PRINT('Caso fallido: actividad paga sin comprobante');
BEGIN TRY
	EXEC actividad.SP_Negocio_RegistrarActividad
		@ID_AreaProtegida = @IDParque,
		@ID_Actividad = @IDActividad,
		@ID_Comprobante = NULL,
		@FechaHora = '2026-06-24T11:00:00',
		@Cantidad = 1;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT @Antes = COUNT(*) FROM actividad.InscripcionActividad WHERE ID_Actividad = @IDActividad;

PRINT('Caso fallido: multiples validaciones y evidencia de rollback');
BEGIN TRY
	EXEC actividad.SP_Negocio_RegistrarActividad
		@ID_AreaProtegida = -1,
		@ID_Actividad = -1,
		@ID_Comprobante = -1,
		@FechaHora = NULL,
		@Cantidad = 0;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT @Antes AS InscripcionesAntes, COUNT(*) AS InscripcionesDespues
FROM actividad.InscripcionActividad
WHERE ID_Actividad = @IDActividad;
GO
