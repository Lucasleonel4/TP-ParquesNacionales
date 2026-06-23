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
* Script: 090. Asignacion de guias
* Descripción: Procedimientos de negocio para asignar guias autorizados a actividades/tours.
*/

USE com2900;
GO

CREATE OR ALTER PROCEDURE [actividad].[SP_Negocio_AsignarGuiaActividad]
	@ID_Actividad        INT,
	@CUIL_GuiaAutorizado BIGINT,
	@FechaReferencia     DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';
	DECLARE @ID_AreaProtegida BIGINT;
	DECLARE @Autorizado BIT;
	DECLARE @FechaControl DATE = ISNULL(@FechaReferencia, CONVERT(DATE, GETDATE()));

	SELECT @ID_AreaProtegida = ID_AreaProtegida
	FROM actividad.Actividad
	WHERE ID = @ID_Actividad;

	SELECT @Autorizado = Autorizado
	FROM personal.GuiaAutorizado
	WHERE CUIL = @CUIL_GuiaAutorizado;

	IF @ID_Actividad IS NULL
		SET @Errores += N'- La actividad es obligatoria.' + CHAR(13) + CHAR(10);

	IF @CUIL_GuiaAutorizado IS NULL
		SET @Errores += N'- El CUIL del guia es obligatorio.' + CHAR(13) + CHAR(10);

	IF @FechaControl IS NULL
		SET @Errores += N'- La fecha de referencia es obligatoria.' + CHAR(13) + CHAR(10);

	IF @ID_AreaProtegida IS NULL AND @ID_Actividad IS NOT NULL
		SET @Errores += N'- La actividad indicada no existe.' + CHAR(13) + CHAR(10);

	IF @Autorizado IS NULL AND @CUIL_GuiaAutorizado IS NOT NULL
		SET @Errores += N'- El guia indicado no existe.' + CHAR(13) + CHAR(10);

	IF @Autorizado = 0
		SET @Errores += N'- El guia no se encuentra autorizado/activo.' + CHAR(13) + CHAR(10);

	IF EXISTS (
		SELECT 1
		FROM actividad.GuiaAsignadoTour
		WHERE ID_Actividad = @ID_Actividad
		  AND CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
	)
		SET @Errores += N'- El guia ya esta asignado a la actividad.' + CHAR(13) + CHAR(10);

	IF @ID_AreaProtegida IS NOT NULL AND @CUIL_GuiaAutorizado IS NOT NULL
	   AND NOT EXISTS (
			SELECT 1
			FROM personal.PermisoDeTrabajo
			WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
			  AND ID_AreaProtegida = @ID_AreaProtegida
			  AND FechaInicio <= @FechaControl
			  AND (FechaFin IS NULL OR FechaFin >= @FechaControl)
		)
		SET @Errores += N'- El guia no posee permiso de trabajo vigente para el parque de la actividad.' + CHAR(13) + CHAR(10);

	IF @CUIL_GuiaAutorizado IS NOT NULL
	   AND NOT EXISTS (
			SELECT 1
			FROM personal.GuiaConHabilitacion
			WHERE CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado
			  AND FechaObtenido <= @FechaControl
			  AND FechaExpiracion >= @FechaControl
		)
		SET @Errores += N'- El guia no posee habilitacion vigente.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		EXEC actividad.SP_GuiaAsignadoTour_Insert
			@ID_Actividad = @ID_Actividad,
			@CUIL_GuiaAutorizado = @CUIL_GuiaAutorizado;

		COMMIT TRANSACTION;

		SELECT @ID_Actividad AS ID_Actividad, @CUIL_GuiaAutorizado AS CUIL_GuiaAutorizado;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO


