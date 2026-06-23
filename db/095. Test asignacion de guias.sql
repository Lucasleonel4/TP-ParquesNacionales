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
* Script: 095. Test asignacion de guias
* Descripción: Pruebas exitosas y fallidas para asignacion de guias.
*/

USE com2900;
GO

DECLARE @IDParque BIGINT = 900003;
DECLARE @IDTipoActividad INT;
DECLARE @IDActividad INT;
DECLARE @IDHabilitacion INT;
DECLARE @CUILGuia BIGINT = 20999000111;
DECLARE @Antes INT;

IF NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @IDParque)
	EXEC parque.SP_AreaProtegida_Insert @ID = @IDParque, @TipoArea = 'Parque Nacional', @Nombre = 'Parque Test Guias', @Superficie = 1000;

IF NOT EXISTS (SELECT 1 FROM actividad.TipoActividad WHERE Nombre = 'Tour Guiado Test')
	EXEC actividad.SP_TipoActividad_Insert @Nombre = 'Tour Guiado Test';

SELECT @IDTipoActividad = ID FROM actividad.TipoActividad WHERE Nombre = 'Tour Guiado Test';

IF NOT EXISTS (SELECT 1 FROM actividad.Actividad WHERE ID_AreaProtegida = @IDParque AND Nombre = 'Mirador Test')
	EXEC actividad.SP_Actividad_Insert @ID_AreaProtegida = @IDParque, @ID_TipoActividad = @IDTipoActividad, @Nombre = 'Mirador Test', @Duracion = 90, @Costo = 0, @CupoMaximo = 10;

SELECT @IDActividad = ID FROM actividad.Actividad WHERE ID_AreaProtegida = @IDParque AND Nombre = 'Mirador Test';

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE CUIL = @CUILGuia)
	EXEC personal.SP_GuiaAutorizado_Insert @CUIL = @CUILGuia, @Nombre = 'Guia', @Apellido = 'Test', @Autorizado = 1;
ELSE
	EXEC personal.SP_GuiaAutorizado_Update @CUIL = @CUILGuia, @Autorizado = 1;

IF NOT EXISTS (SELECT 1 FROM personal.HabilitacionGuia WHERE Nombre = 'Habilitacion Test')
	EXEC personal.SP_HabilitacionGuia_Insert @Nombre = 'Habilitacion Test', @Descripcion = 'Habilitacion de prueba';

SELECT @IDHabilitacion = ID FROM personal.HabilitacionGuia WHERE Nombre = 'Habilitacion Test';

IF NOT EXISTS (SELECT 1 FROM personal.GuiaConHabilitacion WHERE CUIL_GuiaAutorizado = @CUILGuia AND ID_HabilitacionGuia = @IDHabilitacion)
	EXEC personal.SP_GuiaConHabilitacion_Insert @CUIL_GuiaAutorizado = @CUILGuia, @ID_HabilitacionGuia = @IDHabilitacion, @FechaObtenido = '2025-01-01', @FechaExpiracion = '2027-12-31';

IF NOT EXISTS (SELECT 1 FROM personal.PermisoDeTrabajo WHERE CUIL_GuiaAutorizado = @CUILGuia AND ID_AreaProtegida = @IDParque)
	EXEC personal.SP_PermisoDeTrabajo_Insert @ID_AreaProtegida = @IDParque, @CUIL_GuiaAutorizado = @CUILGuia, @FechaInicio = '2025-01-01', @FechaFin = '2027-12-31';

IF EXISTS (SELECT 1 FROM actividad.GuiaAsignadoTour WHERE ID_Actividad = @IDActividad AND CUIL_GuiaAutorizado = @CUILGuia)
	EXEC actividad.SP_GuiaAsignadoTour_Delete @ID_Actividad = @IDActividad, @CUIL_GuiaAutorizado = @CUILGuia;

PRINT('Caso exitoso: asignacion de guia');
EXEC actividad.SP_Negocio_AsignarGuiaActividad
	@ID_Actividad = @IDActividad,
	@CUIL_GuiaAutorizado = @CUILGuia,
	@FechaReferencia = '2026-06-23';

SELECT *
FROM actividad.GuiaAsignadoTour
WHERE ID_Actividad = @IDActividad AND CUIL_GuiaAutorizado = @CUILGuia;

PRINT('Caso fallido: asignacion duplicada');
BEGIN TRY
	EXEC actividad.SP_Negocio_AsignarGuiaActividad
		@ID_Actividad = @IDActividad,
		@CUIL_GuiaAutorizado = @CUILGuia,
		@FechaReferencia = '2026-06-23';
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT @Antes = COUNT(*) FROM actividad.GuiaAsignadoTour;

PRINT('Caso fallido: multiples validaciones y evidencia de rollback');
BEGIN TRY
	EXEC actividad.SP_Negocio_AsignarGuiaActividad
		@ID_Actividad = -1,
		@CUIL_GuiaAutorizado = -1,
		@FechaReferencia = NULL;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeObtenido;
END CATCH;

SELECT @Antes AS AsignacionesAntes, COUNT(*) AS AsignacionesDespues
FROM actividad.GuiaAsignadoTour;
GO


