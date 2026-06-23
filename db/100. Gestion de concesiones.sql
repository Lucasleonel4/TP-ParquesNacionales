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
* Script: 100. Gestion de concesiones
* Descripcion: Procedimientos de negocio para gestionar concesiones con operaciones transaccionales.
*/

USE com2900;
GO

CREATE OR ALTER PROCEDURE [concesion].[sp_Negocio_AltaIntegralConcesion]
	@ID_AreaProtegida       BIGINT,
	@CUIT_Empresa           BIGINT,
	@NombreEmpresa          VARCHAR(150),
	@NombreActividadFiscal  VARCHAR(100),
	@NombreTipoConcesion    VARCHAR(100),
	@FechaInicio            DATE,
	@FechaFin               DATE,
	@Canon                  DECIMAL(20,2),
	@FechaEmisionFactura    DATE,
	@FechaVencimientoFactura DATE
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';
	DECLARE @ID_ActividadFiscal INT;
	DECLARE @ID_TipoConcesion INT;
	DECLARE @ID_Concesion INT;
	DECLARE @MontoFactura DECIMAL(20,2);

	IF NOT EXISTS (SELECT 1 FROM parque.AreaProtegida WHERE ID = @ID_AreaProtegida)
		SET @Errores += N'- El area protegida no existe.' + CHAR(13) + CHAR(10);

	IF @CUIT_Empresa IS NULL OR @CUIT_Empresa <= 0
		SET @Errores += N'- El CUIT de la empresa es obligatorio y debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF NULLIF(LTRIM(RTRIM(@NombreEmpresa)), '') IS NULL
		SET @Errores += N'- El nombre de la empresa es obligatorio.' + CHAR(13) + CHAR(10);

	IF NULLIF(LTRIM(RTRIM(@NombreActividadFiscal)), '') IS NULL
		SET @Errores += N'- La actividad fiscal es obligatoria.' + CHAR(13) + CHAR(10);

	IF NULLIF(LTRIM(RTRIM(@NombreTipoConcesion)), '') IS NULL
		SET @Errores += N'- El tipo de concesion es obligatorio.' + CHAR(13) + CHAR(10);

	IF @FechaInicio IS NULL OR @FechaFin IS NULL OR @FechaFin < @FechaInicio
		SET @Errores += N'- Las fechas de concesion son obligatorias y la fecha de fin debe ser posterior o igual al inicio.' + CHAR(13) + CHAR(10);

	IF @Canon IS NULL OR @Canon <= 0
		SET @Errores += N'- El canon debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF @FechaEmisionFactura IS NULL OR @FechaVencimientoFactura IS NULL OR @FechaVencimientoFactura < @FechaEmisionFactura
		SET @Errores += N'- Las fechas de factura son obligatorias y el vencimiento debe ser posterior o igual a la emision.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		IF NOT EXISTS (SELECT 1 FROM concesion.Empresa WHERE CUIT = @CUIT_Empresa)
			INSERT INTO concesion.Empresa (CUIT, Nombre)
			VALUES (@CUIT_Empresa, @NombreEmpresa);
		ELSE
			UPDATE concesion.Empresa
			SET Nombre = ISNULL(@NombreEmpresa, Nombre)
			WHERE CUIT = @CUIT_Empresa;

		SELECT @ID_ActividadFiscal = ID
		FROM concesion.ActividadFiscal
		WHERE Nombre = @NombreActividadFiscal;

		IF @ID_ActividadFiscal IS NULL
		BEGIN
			INSERT INTO concesion.ActividadFiscal (Nombre)
			VALUES (@NombreActividadFiscal);

			SET @ID_ActividadFiscal = SCOPE_IDENTITY();
		END

		IF NOT EXISTS (
			SELECT 1
			FROM concesion.ActividadFiscalInscriptaEmpresa
			WHERE CUIT_Empresa = @CUIT_Empresa
			  AND ID_ActividadFiscal = @ID_ActividadFiscal
		)
			INSERT INTO concesion.ActividadFiscalInscriptaEmpresa (CUIT_Empresa, ID_ActividadFiscal, Principal)
			VALUES (@CUIT_Empresa, @ID_ActividadFiscal, 0);

		SELECT @ID_TipoConcesion = ID
		FROM concesion.TipoConcesion
		WHERE ID_ActividadFiscal = @ID_ActividadFiscal
		  AND Nombre = @NombreTipoConcesion;

		IF @ID_TipoConcesion IS NULL
		BEGIN
			INSERT INTO concesion.TipoConcesion (ID_ActividadFiscal, Nombre)
			VALUES (@ID_ActividadFiscal, @NombreTipoConcesion);

			SET @ID_TipoConcesion = SCOPE_IDENTITY();
		END

		INSERT INTO concesion.Concesion (ID_AreaProtegida, CUIT_Empresa, ID_TipoConcesion, FechaInicio, FechaFin, Canon)
		VALUES (@ID_AreaProtegida, @CUIT_Empresa, @ID_TipoConcesion, @FechaInicio, @FechaFin, @Canon);

		SET @ID_Concesion = SCOPE_IDENTITY();
		SET @MontoFactura = @Canon;

		INSERT INTO concesion.FacturaConcesion (ID_Concesion, FechaEmision, FechaVencimiento, MontoEsperado)
		VALUES (@ID_Concesion, @FechaEmisionFactura, @FechaVencimientoFactura, @MontoFactura);

		COMMIT TRANSACTION;

		SELECT @ID_Concesion AS ID_Concesion, @ID_TipoConcesion AS ID_TipoConcesion, @ID_ActividadFiscal AS ID_ActividadFiscal;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO
