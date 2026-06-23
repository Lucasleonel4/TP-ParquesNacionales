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
* Script: 070. Venta de Entradas
* Descripcion: Se crean procedimientos almacenados que realizan las transacciones del negocio relacionadas a la venta de entradas.
*/

USE com2900;
GO

-- PROCEDIMIENTO QUE REGISTRA LA VENTA DE ENTRADAS DEL MISMO TIPO: 1) GENERA EL COMPROBANTE - 2) GENERA LAS ENTRADAS
CREATE OR ALTER PROCEDURE [venta].[SP_Negocio_RegistrarVentaEntradasMismoTipo]
	@ID_PuntoDeVenta		INT,
	@COD_ISO_Divisa			CHAR(3),
	@MedioDePago			VARCHAR(30),
	@FechaHora				DATETIME,
	@ID_AreaProtegida		BIGINT,
	@ID_TipoEntrada			INT,
	@Cantidad				INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';
	DECLARE	@IDComprobante			INT;
	DECLARE @IDTipoEntradaParque	INT;
	DECLARE @Precio					DECIMAL(12,2);
	DECLARE @Total					DECIMAL(12,2) = 0;

	IF @Cantidad IS NULL OR @Cantidad <= 0
		SET @Errores += N'- La cantidad debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF @FechaHora IS NULL
		SET @Errores += N'- La fecha y hora de venta es obligatoria.' + CHAR(13) + CHAR(10);

	IF NOT EXISTS (SELECT 1 FROM [parque].[AreaProtegida] WHERE ID = @ID_AreaProtegida)
		SET @Errores += N'- El parque indicado no existe.' + CHAR(13) + CHAR(10);

	IF NOT EXISTS (SELECT 1 FROM [parque].[PuntoDeVenta] WHERE ID = @ID_PuntoDeVenta)
		SET @Errores += N'- El punto de venta indicado no existe.' + CHAR(13) + CHAR(10);
	ELSE IF NOT EXISTS (SELECT 1 FROM [parque].[PuntoDeVenta] WHERE ID = @ID_PuntoDeVenta AND ID_AreaProtegida = @ID_AreaProtegida)
		SET @Errores += N'- El punto de venta no corresponde al parque indicado.' + CHAR(13) + CHAR(10);

	IF NOT EXISTS (SELECT 1 FROM [venta].[Divisa] WHERE COD_ISO = @COD_ISO_Divisa)
		SET @Errores += N'- La divisa indicada no existe.' + CHAR(13) + CHAR(10);

	IF @MedioDePago NOT IN ('Efectivo', 'Tarjeta', 'Transferencia')
		SET @Errores += N'- El medio de pago debe ser Efectivo, Tarjeta o Transferencia.' + CHAR(13) + CHAR(10);

	IF NOT EXISTS (SELECT 1 FROM [venta].[TipoEntrada] WHERE ID = @ID_TipoEntrada)
		SET @Errores += N'- El tipo de entrada indicado no existe.' + CHAR(13) + CHAR(10);

	SELECT
		@IDTipoEntradaParque = ID,
		@Precio = Precio
	FROM [venta].[TipoEntradaParque]
	WHERE ID_AreaProtegida = @ID_AreaProtegida
	  AND ID_TipoEntrada = @ID_TipoEntrada;

	IF @IDTipoEntradaParque IS NULL
		SET @Errores += N'- El tipo de entrada no tiene precio configurado para el parque indicado.' + CHAR(13) + CHAR(10);

	IF @Precio IS NULL OR @Precio <= 0
		SET @Errores += N'- El precio de la entrada debe ser mayor que cero.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	BEGIN TRY
		BEGIN TRANSACTION;

		SET @Total = @Precio * @Cantidad;

		EXEC [venta].[SP_Comprobante_Insert]
			@ID_PuntoDeVenta = @ID_PuntoDeVenta,
			@COD_ISO_Divisa  = @COD_ISO_Divisa,
			@MedioDePago     = @MedioDePago,
			@FechaHora       = @FechaHora,
			@Total           = @Total,
			@IDComprobante	 = @IDComprobante OUTPUT;

		DECLARE @i INT = 1;

		WHILE @i <= @Cantidad
		BEGIN
			EXEC [venta].[SP_Entrada_Insert]
				@ID_TipoEntradaParque = @IDTipoEntradaParque,
				@ID_Comprobante       = @IDComprobante,
				@FechaHora            = @FechaHora,
				@PrecioCobrado        = @Precio;

			SET @i = @i + 1;
		END

		COMMIT TRANSACTION;

		SELECT @IDComprobante AS ID_Comprobante, @Total AS Total, @Cantidad AS CantidadEntradas;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO

-- PROCEDIMIENTO QUE REGISTRA LA VENTA DE ENTRADAS DE DISTINTOS TIPOS CON TABLA AUXILIAR.
-- 1) GENERA EL COMPROBANTE - 2) GENERA LAS ENTRADAS

-- TABLA AUXILIAR
	IF NOT EXISTS (SELECT 1 FROM sys.table_types WHERE name = 'TipoTablaDetalleEntradas' AND schema_id = SCHEMA_ID('venta'))
	BEGIN
		EXEC('CREATE TYPE [venta].[TipoTablaDetalleEntradas] AS TABLE (
			ID_TipoEntrada INT,
			Cantidad       INT,
			Procesado      BIT DEFAULT 0
		);');
		PRINT('OK: tipo tabla TipoTablaDetalleEntradas creada exitosamente');
	END
	ELSE PRINT('INFO: tipo tabla TipoTablaDetalleEntradas ya existe');
	GO

-- PROCEDIMIENTO
	CREATE OR ALTER PROCEDURE [venta].[SP_Negocio_RegistrarVentaEntradasDistintoTipo]
		@ID_PuntoDeVenta  INT,
		@COD_ISO_Divisa   CHAR(3),
		@MedioDePago      VARCHAR(30),
		@FechaHora        DATETIME,
		@ID_AreaProtegida BIGINT,
		@Detalle          [venta].[TipoTablaDetalleEntradas] READONLY
	AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		DECLARE @Errores NVARCHAR(MAX) = N'';
		DECLARE @IDComprobante       INT;
		DECLARE @Total               DECIMAL(12,2) = 0;
		DECLARE @ID_TipoEntrada      INT;
		DECLARE @Cantidad            INT;
		DECLARE @Precio              DECIMAL(12,2);
		DECLARE @IDTipoEntradaParque INT;
		DECLARE @i                   INT;

		IF @FechaHora IS NULL
			SET @Errores += N'- La fecha y hora de venta es obligatoria.' + CHAR(13) + CHAR(10);

		IF NOT EXISTS (SELECT 1 FROM @Detalle)
			SET @Errores += N'- El comprobante debe tener al menos un detalle de entrada.' + CHAR(13) + CHAR(10);

		IF EXISTS (SELECT 1 FROM @Detalle WHERE Cantidad IS NULL OR Cantidad <= 0)
			SET @Errores += N'- Todas las cantidades deben ser mayores que cero.' + CHAR(13) + CHAR(10);

		IF EXISTS (SELECT ID_TipoEntrada FROM @Detalle GROUP BY ID_TipoEntrada HAVING COUNT(*) > 1)
			SET @Errores += N'- El detalle no debe contener tipos de entrada duplicados.' + CHAR(13) + CHAR(10);

		IF NOT EXISTS (SELECT 1 FROM [parque].[AreaProtegida] WHERE ID = @ID_AreaProtegida)
			SET @Errores += N'- El parque indicado no existe.' + CHAR(13) + CHAR(10);

		IF NOT EXISTS (SELECT 1 FROM [parque].[PuntoDeVenta] WHERE ID = @ID_PuntoDeVenta)
			SET @Errores += N'- El punto de venta indicado no existe.' + CHAR(13) + CHAR(10);
		ELSE IF NOT EXISTS (SELECT 1 FROM [parque].[PuntoDeVenta] WHERE ID = @ID_PuntoDeVenta AND ID_AreaProtegida = @ID_AreaProtegida)
			SET @Errores += N'- El punto de venta no corresponde al parque indicado.' + CHAR(13) + CHAR(10);

		IF NOT EXISTS (SELECT 1 FROM [venta].[Divisa] WHERE COD_ISO = @COD_ISO_Divisa)
			SET @Errores += N'- La divisa indicada no existe.' + CHAR(13) + CHAR(10);

		IF @MedioDePago NOT IN ('Efectivo', 'Tarjeta', 'Transferencia')
			SET @Errores += N'- El medio de pago debe ser Efectivo, Tarjeta o Transferencia.' + CHAR(13) + CHAR(10);

		IF EXISTS (
			SELECT 1
			FROM @Detalle D
			WHERE NOT EXISTS (SELECT 1 FROM [venta].[TipoEntrada] T WHERE T.ID = D.ID_TipoEntrada)
		)
			SET @Errores += N'- Existe al menos un tipo de entrada inexistente.' + CHAR(13) + CHAR(10);

		IF EXISTS ( --¿¿
			SELECT 1
			FROM @Detalle D
			WHERE NOT EXISTS (
				SELECT 1
				FROM [venta].[TipoEntradaParque] TEP
				WHERE TEP.ID_AreaProtegida = @ID_AreaProtegida
				AND TEP.ID_TipoEntrada = D.ID_TipoEntrada
			)
		)
			SET @Errores += N'- Existe al menos un tipo de entrada sin precio para el parque indicado.' + CHAR(13) + CHAR(10);

		IF EXISTS (
			SELECT 1
			FROM @Detalle D
			JOIN [venta].[TipoEntradaParque] TEP
			ON TEP.ID_AreaProtegida = @ID_AreaProtegida
			AND TEP.ID_TipoEntrada = D.ID_TipoEntrada
			WHERE TEP.Precio IS NULL OR TEP.Precio <= 0
		)
			SET @Errores += N'- Todos los precios de entrada deben ser mayores que cero.' + CHAR(13) + CHAR(10);

		IF LEN(@Errores) > 0
			THROW 50001, @Errores, 1;

		BEGIN TRY
			BEGIN TRANSACTION;

			CREATE TABLE #Detalle (
				ID_TipoEntrada INT,
				Cantidad       INT,
				Procesado      BIT DEFAULT 0
			);

			INSERT INTO #Detalle(ID_TipoEntrada, Cantidad)
			SELECT ID_TipoEntrada, Cantidad FROM @Detalle;

			SELECT @Total = SUM(TEP.Precio * D.Cantidad)
			FROM #Detalle D
			JOIN [venta].[TipoEntradaParque] TEP
			ON TEP.ID_AreaProtegida = @ID_AreaProtegida
			AND TEP.ID_TipoEntrada = D.ID_TipoEntrada;

			EXEC [venta].[SP_Comprobante_Insert]
				@ID_PuntoDeVenta = @ID_PuntoDeVenta,
				@COD_ISO_Divisa  = @COD_ISO_Divisa,
				@MedioDePago     = @MedioDePago,
				@FechaHora       = @FechaHora,
				@Total           = @Total,
				@IDComprobante   = @IDComprobante OUTPUT;

			WHILE EXISTS (SELECT 1 FROM #Detalle WHERE Procesado = 0)
			BEGIN
				SELECT TOP 1
					@ID_TipoEntrada = ID_TipoEntrada,
					@Cantidad       = Cantidad
				FROM #Detalle
				WHERE Procesado = 0;

				SELECT
					@Precio = Precio,
					@IDTipoEntradaParque = ID
				FROM [venta].[TipoEntradaParque]
				WHERE ID_AreaProtegida = @ID_AreaProtegida
				AND ID_TipoEntrada = @ID_TipoEntrada;

				SET @i = 1;

				WHILE @i <= @Cantidad
				BEGIN
					EXEC [venta].[SP_Entrada_Insert]
						@ID_TipoEntradaParque = @IDTipoEntradaParque,
						@ID_Comprobante       = @IDComprobante,
						@FechaHora            = @FechaHora,
						@PrecioCobrado        = @Precio;

					SET @i = @i + 1;
				END

				UPDATE #Detalle
				SET Procesado = 1
				WHERE ID_TipoEntrada = @ID_TipoEntrada;
			END

			DROP TABLE #Detalle;

			COMMIT TRANSACTION;

			SELECT @IDComprobante AS ID_Comprobante, @Total AS Total;
		END TRY
		BEGIN CATCH
			IF OBJECT_ID('tempdb..#Detalle') IS NOT NULL
				DROP TABLE #Detalle;

			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;

			THROW;
		END CATCH
	END
	GO
			

-- PROCEDIMIENTO QUE REGISTRA CONJUNTAMENTE LA VENTA DE ENTRADAS DE DISTINTO TIPOS CON TABLA AUXILIAR: 1) GENERA EL COMPROBANTE - 2) GENERA LAS ENTRADAS. ADEMÁS DE LA INSCRIPCIÓN A ACTIVIDADES

	-- TABLA AUXILIAR PARA DETALLE DE ACTIVIDAD (REQUIERE LA TABLA AUXILIAR DEL SP ANTERIOR)
		IF NOT EXISTS (SELECT 1 FROM SYS.TABLE_TYPES WHERE NAME = 'TipoTablaDetalleActividad' AND schema_id = SCHEMA_ID('actividad'))
		BEGIN
			CREATE TYPE [actividad].[TipoTablaDetalleActividad] AS TABLE (
					ID_Actividad	INT,
					Cantidad		INT,
					Procesado		BIT DEFAULT 0
			)
			PRINT('OK: tipo tabla TipoTablaDetalleActividad creada exitosamente');
		END
		ELSE
			PRINT('INFO: tipo tabla TipoTablaDetalleActividad ya existe');
		GO

	-- PROCEDIMIENTO
		CREATE OR ALTER PROCEDURE [venta].[SP_Negocio_VenderEntradasYActividades]
			@ID_PuntoDeVenta  INT,
			@COD_ISO_Divisa   CHAR(3),
			@MedioDePago      VARCHAR(30),
			@FechaHora        DATETIME,
			@ID_AreaProtegida BIGINT,
			@DetalleEntrada   [venta].[TipoTablaDetalleEntradas] READONLY,
			@DetalleActividad [actividad].[TipoTablaDetalleActividad] READONLY
		AS
		BEGIN
			BEGIN TRY
				
					DECLARE @Errores NVARCHAR(MAX) = N'';
					DECLARE @IDComprobante       INT
					DECLARE @Total               DECIMAL(12,2) = 0
					DECLARE @ID_TipoEntrada      INT
					DECLARE @ID_Actividad		 INT
					DECLARE @Cantidad            INT
					DECLARE @Precio              DECIMAL(12,2)
					DECLARE @IDTipoEntradaParque INT
					DECLARE @i                   INT

					IF @FechaHora IS NULL
						SET @Errores += N'- La fecha y hora de venta es obligatoria.' + CHAR(13) + CHAR(10);

					IF NOT EXISTS (SELECT 1 FROM [parque].[AreaProtegida] WHERE ID = @ID_AreaProtegida)
						SET @Errores += N'- El parque indicado no existe.' + CHAR(13) + CHAR(10);

					IF NOT EXISTS (SELECT 1 FROM [parque].[PuntoDeVenta] WHERE ID = @ID_PuntoDeVenta)
						SET @Errores += N'- El punto de venta indicado no existe.' + CHAR(13) + CHAR(10);
					ELSE IF NOT EXISTS (SELECT 1 FROM [parque].[PuntoDeVenta] WHERE ID = @ID_PuntoDeVenta AND ID_AreaProtegida = @ID_AreaProtegida)
						SET @Errores += N'- El punto de venta no corresponde al parque indicado.' + CHAR(13) + CHAR(10);

					IF NOT EXISTS (SELECT 1 FROM [venta].[Divisa] WHERE COD_ISO = @COD_ISO_Divisa)
						SET @Errores += N'- La divisa indicada no existe.' + CHAR(13) + CHAR(10);

					IF @MedioDePago NOT IN ('Efectivo', 'Tarjeta', 'Transferencia')
						SET @Errores += N'- El medio de pago debe ser Efectivo, Tarjeta o Transferencia.' + CHAR(13) + CHAR(10);

					IF NOT EXISTS (SELECT 1 FROM @DetalleEntrada) AND NOT EXISTS (SELECT 1 FROM @DetalleActividad)
						SET @Errores += N'- No existen datos para registrar.' + CHAR(13) + CHAR(10);

					IF LEN(@Errores) > 0
						THROW 50001, @Errores, 1;

				BEGIN TRANSACTION

					IF EXISTS (SELECT 1 FROM @DetalleEntrada)
					BEGIN
						CREATE TABLE #DetalleEntrada (
							ID_TipoEntrada INT,
							Cantidad       INT,
							Procesado      BIT DEFAULT 0
						)
						INSERT INTO #DetalleEntrada(ID_TipoEntrada, Cantidad)
						SELECT ID_TipoEntrada, Cantidad FROM @DetalleEntrada
						
						-- Calcula el total
						SELECT @Total = @Total + [venta].[FN_TipoEntradaParque_ObtenerPrecio](@ID_AreaProtegida, ID_TipoEntrada) * Cantidad
						FROM #DetalleEntrada
					END
					
					IF EXISTS (SELECT 1 FROM @DetalleActividad)
					BEGIN
						CREATE TABLE #DetalleActividad(
							ID_Actividad	INT,
							Cantidad		INT,
							Procesado		BIT DEFAULT 0
						)
						INSERT INTO #DetalleActividad(ID_Actividad, Cantidad)
						SELECT ID_ACTIVIDAD, CANTIDAD FROM @DetalleActividad

						-- Calcula el total
						SELECT @Total = @Total + [actividad].[FN_Actividad_ObtenerPrecio](ID_Actividad) * Cantidad
						FROM #DetalleActividad
					END
					
					-- Creo el comprobante
					EXEC [venta].[SP_Comprobante_Insert]
						@ID_PuntoDeVenta = @ID_PuntoDeVenta,
						@COD_ISO_Divisa  = @COD_ISO_Divisa,
						@MedioDePago     = @MedioDePago,
						@FechaHora       = @FechaHora,
						@Total           = @Total,
						@IDComprobante   = @IDComprobante OUTPUT
					
					-- Itera registrando las entradas:
					IF EXISTS (SELECT 1 FROM @DetalleEntrada)
					BEGIN
						WHILE EXISTS (SELECT 1 FROM #DetalleEntrada WHERE Procesado = 0)
						BEGIN
							SELECT TOP 1
								@ID_TipoEntrada = ID_TipoEntrada,
								@Cantidad       = Cantidad
							FROM #DetalleEntrada
							WHERE Procesado = 0

							SET @Precio              = [venta].[FN_TipoEntradaParque_ObtenerPrecio](@ID_AreaProtegida, @ID_TipoEntrada)
							SET @IDTipoEntradaParque = [venta].[FN_TipoEntradaParque_ObtenerID](@ID_AreaProtegida, @ID_TipoEntrada)
							SET @i = 1

							-- Inserto N entradas del tipo actual
							WHILE @i <= @Cantidad
							BEGIN
								EXEC [venta].[SP_Entrada_Insert]
									@ID_TipoEntradaParque = @IDTipoEntradaParque,
									@ID_Comprobante       = @IDComprobante,
									@FechaHora            = @FechaHora,
									@PrecioCobrado        = @Precio

								SET @i = @i + 1
							END

							UPDATE #DetalleEntrada SET Procesado = 1 WHERE ID_TipoEntrada = @ID_TipoEntrada
						END
					END
					-- Itera registrando la inscripcion a actividad:
					IF EXISTS (SELECT 1 FROM @DetalleActividad)
					BEGIN
						WHILE EXISTS (SELECT 1 FROM #DetalleActividad WHERE Procesado = 0)
						BEGIN
							SELECT TOP 1
								@ID_Actividad = ID_Actividad,
								@Cantidad	  = Cantidad
							FROM #DetalleActividad 
							WHERE Procesado = 0

							SET @Errores = N''

							IF [actividad].[FN_Actividad_TieneCupo](@ID_Actividad, @Cantidad) = 0
								SET @Errores += N'- No hay cupo suficiente para la actividad.' + CHAR(13) + CHAR(10);

							IF LEN(@Errores) > 0
								THROW 50001, @Errores, 1;

							SET @Precio = [actividad].[FN_Actividad_ObtenerPrecio](@ID_Actividad)
							SET @i = 1

							-- Inserto N entradas del tipo actual
							WHILE @i <= @Cantidad
							BEGIN
								EXEC [actividad].[SP_InscripcionActividad_Insert]
									@ID_Actividad    = @ID_Actividad,
									@ID_Comprobante  = @IDComprobante,
									@FechaHora       = @FechaHora,
									@PrecioCobrado   = @Precio

								SET @i = @i + 1
							END

							UPDATE #DetalleActividad SET Procesado = 1 WHERE ID_Actividad = @ID_Actividad
						END
					END
					IF OBJECT_ID('tempdb..#DetalleEntrada') IS NOT NULL DROP TABLE #DetalleEntrada
					IF OBJECT_ID('tempdb..#DetalleActividad') IS NOT NULL DROP TABLE #DetalleActividad
				COMMIT
			END TRY
			BEGIN CATCH
				IF OBJECT_ID('tempdb..#DetalleEntrada') IS NOT NULL BEGIN DROP TABLE #DetalleEntrada END;
				IF OBJECT_ID('tempdb..#DetalleActividad') IS NOT NULL BEGIN DROP TABLE #DetalleActividad END;
				IF @@TRANCOUNT > 0
					ROLLBACK TRANSACTION;
				THROW;
			END CATCH
		END
		GO

	-- EJEMPLO DE USO
		/*
			EJEMPLO CON ENTRADAS Y ACTIVIDADES:

				DECLARE @entradas  [venta].[TipoTablaDetalleEntradas]
				DECLARE @actividades [actividad].[TipoTablaDetalleActividad]

				-- 2 entradas residentes, 1 entrada extranjero
				INSERT INTO @entradas(ID_TipoEntrada, Cantidad) VALUES (1, 2)
				INSERT INTO @entradas(ID_TipoEntrada, Cantidad) VALUES (2, 1)

				-- 3 inscripciones al tour de avistaje, 2 al trekking
				INSERT INTO @actividades(ID_Actividad, Cantidad) VALUES (5, 3)
				INSERT INTO @actividades(ID_Actividad, Cantidad) VALUES (8, 2)

				EXEC [venta].[SP_Negocio_VenderEntradasYActividades]
					@ID_PuntoDeVenta  = 1,
					@COD_ISO_Divisa   = 'ARS',
					@MedioDePago      = 'Tarjeta',
					@FechaHora        = GETDATE(),
					@ID_AreaProtegida = 6,
					@DetalleEntrada   = @entradas,
					@DetalleActividad = @actividades

			EJEMPLO CON ENTRADAS (SIN ACTIVIDADES):

				DECLARE @entradas2    [venta].[TipoTablaDetalleEntradas]
				DECLARE @Actividad [actividad].[TipoTablaDetalleActividad] -- vacía

				INSERT INTO @entradas2(ID_TipoEntrada, Cantidad) VALUES (1, 4)

				EXEC [venta].[SP_Negocio_VenderEntradasYActividades]
					@ID_PuntoDeVenta  = 1,
					@COD_ISO_Divisa   = 'ARS',
					@MedioDePago      = 'Efectivo',
					@FechaHora        = GETDATE(),
					@ID_AreaProtegida = 6,
					@DetalleEntrada   = @entradas2,
					@DetalleActividad = @Actividad  -- tabla vacía, el IF no entra
		*/
