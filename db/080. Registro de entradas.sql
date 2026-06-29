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
* Script: 080. Registro de actividades
* Descripción: Procedimientos de negocio para registrar/contratar actividades dentro de un parque.
*/

USE com2900;
GO

CREATE OR ALTER PROCEDURE [actividad].[ActividadRegistrar]
	@ID_AreaProtegida BIGINT,
	@ID_Actividad     INT,
	@ID_Comprobante   INT = NULL,
	@FechaHora        DATETIME,
	@Cantidad         INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';
	DECLARE @Costo DECIMAL(12,2);
	DECLARE @CupoMaximo INT;
	DECLARE @Inscriptos INT;
	DECLARE @i INT = 1;

	IF @Cantidad IS NULL OR @Cantidad <= 0
		SET @Errores += N'- La cantidad debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF @FechaHora IS NULL
		SET @Errores += N'- La fecha y hora de actividad es obligatoria.' + CHAR(13) + CHAR(10);

	IF @FechaHora IS NOT NULL AND @FechaHora < '2000-01-01'
		SET @Errores += N'- La fecha de actividad no es valida.' + CHAR(13) + CHAR(10);

	IF NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @ID_AreaProtegida)
		SET @Errores += N'- El parque indicado no existe.' + CHAR(13) + CHAR(10);

	SELECT
		@Costo = Costo,
		@CupoMaximo = CupoMaximo
	FROM actividad.Actividad
	WHERE ID = @ID_Actividad;

	IF @Costo IS NULL AND NOT EXISTS (SELECT 1 FROM actividad.Actividad WHERE ID = @ID_Actividad)
		SET @Errores += N'- La actividad indicada no existe.' + CHAR(13) + CHAR(10);

	IF EXISTS (SELECT 1 FROM actividad.Actividad WHERE ID = @ID_Actividad AND ID_AreaProtegida <> @ID_AreaProtegida)
		SET @Errores += N'- La actividad no corresponde al parque indicado.' + CHAR(13) + CHAR(10);

	IF @Costo IS NOT NULL AND @Costo < 0
		SET @Errores += N'- El costo de la actividad no puede ser negativo.' + CHAR(13) + CHAR(10);

	IF @Costo IS NOT NULL AND @Costo > 0 AND @ID_Comprobante IS NULL
		SET @Errores += N'- Las actividades pagas deben asociarse a un comprobante.' + CHAR(13) + CHAR(10);

	IF @ID_Comprobante IS NOT NULL AND NOT EXISTS (SELECT 1 FROM venta.Comprobante WHERE ID = @ID_Comprobante)
		SET @Errores += N'- El comprobante indicado no existe.' + CHAR(13) + CHAR(10);

	SELECT @Inscriptos = COUNT(*)
	FROM actividad.InscripcionActividad
	WHERE ID_Actividad = @ID_Actividad;

	IF @CupoMaximo IS NOT NULL AND @Cantidad IS NOT NULL AND (@Inscriptos + @Cantidad) > @CupoMaximo
		SET @Errores += N'- La cantidad solicitada supera el cupo disponible.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE @i <= @Cantidad
		BEGIN
			EXEC actividad.InscripcionActividadAlta
				@ID_Actividad = @ID_Actividad,
				@ID_Comprobante = @ID_Comprobante,
				@FechaHora = @FechaHora,
				@PrecioCobrado = @Costo;

			SET @i += 1;
		END

		COMMIT TRANSACTION;

		SELECT @ID_Actividad AS ID_Actividad, @Cantidad AS CantidadRegistrada;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO

