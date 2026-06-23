/*
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Script: 070. Venta de Entradas
 * Descripción: Se crean procedimientos almacenados que realizan las trasnsacciones del negocio relacionadas a la venta de entradas.
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
		BEGIN TRY
			BEGIN TRANSACTION 
				DECLARE	@IDComprobante			INT
				DECLARE @IDTipoEntradaParque	INT
				DECLARE @Precio					DECIMAL(12,2)
				DECLARE @Total					DECIMAL(12,2) = 0

				SET @Precio					= [venta].[FN_TipoEntradaParque_ObtenerPrecio](@ID_AreaProtegida, @ID_TipoEntrada)
				SET @Total					= @Precio * @Cantidad
				SET @IDTipoEntradaParque	= [venta].[FN_TipoEntradaParque_ObtenerID](@ID_AreaProtegida, @ID_TipoEntrada)

				-- CREO EL COMPROBANTE
				EXEC [venta].[SP_Comprobante_Insert]
					@ID_PuntoDeVenta = @ID_PuntoDeVenta,
					@COD_ISO_Divisa  = @COD_ISO_Divisa,
					@MedioDePago     = @MedioDePago,
					@FechaHora       = @FechaHora,
					@Total           = @Total,
					@IDComprobante	 = @IDComprobante OUTPUT
			
				-- CREO LA ENTRADA USANDO SP DE INSERCION DE ENTRADAS
					DECLARE @i INT = 1

					WHILE @i <= @Cantidad
					BEGIN
						EXEC [venta].[SP_Entrada_Insert]
							@ID_TipoEntradaParque = @IDTipoEntradaParque,
							@ID_Comprobante       = @IDComprobante,
							@FechaHora            = @FechaHora,
							@PrecioCobrado        = @Precio

						SET @i = @i + 1
					END
				COMMIT
		END TRY
		BEGIN CATCH
			ROLLBACK;
			THROW;
		END CATCH
	END
	GO

	-- FORMA DE LLAMADO DE EJEMPLO
		/*
		EXEC [venta].[SP_Negocio_RegistrarVentaEntradasMismoTipo]
			@ID_PuntoDeVenta  = 1,
			@COD_ISO_Divisa   = 'ARS',
			@MedioDePago      = 'Efectivo',
			@FechaHora        = GETDATE(),
			@ID_AreaProtegida = 6,
			@ID_TipoEntrada	  = 1,
			@Cantidad		  = 3
		*/
	
-- PROCEDIMIENTO QUE REGISTRA LA VENTA DE ENTRADAS DE DISTINTO TIPOS CON TABLA AUXILIAR: 1) GENERA EL COMPROBANTE - 2) GENERA LAS ENTRADAS

	-- TABLA AUXILIAR
		IF NOT EXISTS (SELECT 1 FROM sys.table_types WHERE name = 'TipoTablaDetalleEntradas' AND schema_id = SCHEMA_ID('venta'))
		BEGIN
			CREATE TYPE [venta].[TipoTablaDetalleEntradas] AS TABLE (
				ID_TipoEntrada INT,
				Cantidad       INT,
				Procesado      BIT DEFAULT 0
			)
			PRINT('OK: tipo tabla TipoTablaDetalleEntradas creada exitosamente');
		END
		ELSE PRINT('INFO: tipo tabla TipoTablaDetalleEntradas ya existe');
		GO

	-- PROCEDIMIENTO ALMACENADO
		CREATE OR ALTER PROCEDURE [venta].[SP_Negocio_RegistrarVentaEntradasDistintoTipo]
			@ID_PuntoDeVenta  INT,
			@COD_ISO_Divisa   CHAR(3),
			@MedioDePago      VARCHAR(30),
			@FechaHora        DATETIME,
			@ID_AreaProtegida BIGINT,
			@Detalle          [venta].[TipoTablaDetalleEntradas] READONLY
		AS
		BEGIN
			BEGIN TRY
				BEGIN TRANSACTION

					DECLARE @IDComprobante       INT
					DECLARE @Total               DECIMAL(12,2) = 0
					DECLARE @ID_TipoEntrada      INT
					DECLARE @Cantidad            INT
					DECLARE @Precio              DECIMAL(12,2)
					DECLARE @IDTipoEntradaParque INT
					DECLARE @i                   INT

					CREATE TABLE #Detalle (
						ID_TipoEntrada INT,
						Cantidad       INT,
						Procesado      BIT DEFAULT 0
					)
					INSERT INTO #Detalle(ID_TipoEntrada, Cantidad)
					SELECT ID_TipoEntrada, Cantidad FROM @Detalle

					-- Calculo total sumando precio * cantidad de cada tipo
					SELECT @Total = @Total + [venta].[FN_TipoEntradaParque_ObtenerPrecio](@ID_AreaProtegida, ID_TipoEntrada) * Cantidad
					FROM #Detalle

					-- Creo el comprobante
					EXEC [venta].[SP_Comprobante_Insert]
						@ID_PuntoDeVenta = @ID_PuntoDeVenta,
						@COD_ISO_Divisa  = @COD_ISO_Divisa,
						@MedioDePago     = @MedioDePago,
						@FechaHora       = @FechaHora,
						@Total           = @Total,
						@IDComprobante   = @IDComprobante OUTPUT

					-- Itero por cada tipo de entrada
					WHILE EXISTS (SELECT 1 FROM #Detalle WHERE Procesado = 0)
					BEGIN
						SELECT TOP 1
							@ID_TipoEntrada = ID_TipoEntrada,
							@Cantidad       = Cantidad
						FROM #Detalle
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

						UPDATE #Detalle SET Procesado = 1 WHERE ID_TipoEntrada = @ID_TipoEntrada
					END
					DROP TABLE #Detalle
				COMMIT
			END TRY
			BEGIN CATCH
				IF OBJECT_ID('tempdb..#Detalle') IS NOT NULL
				BEGIN
					DROP TABLE #Detalle
				END;
				ROLLBACK;
				THROW;
			END CATCH
		END
		GO

	-- FORMA DE LLAMADO DE EJEMPLO
		/*
			DECLARE @detalle [venta].[TipoTablaDetalleEntradas]
			-- 3 entradas de tipo 1 (p.ej: residente) y 2 de tipo 2 (p.ej: extranjero)
			INSERT INTO @detalle(ID_TipoEntrada, Cantidad) VALUES (1, 3)
			INSERT INTO @detalle(ID_TipoEntrada, Cantidad) VALUES (2, 2)

			EXEC [venta].[SP_Negocio_RegistrarVentaMultipleEntradas]
				@ID_PuntoDeVenta  = 1,
				@COD_ISO_Divisa   = 'ARS',
				@MedioDePago      = 'Efectivo',
				@FechaHora        = GETDATE(),
				@ID_AreaProtegida = 6,
				@Detalle          = @detalle
		*/


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
				BEGIN TRANSACTION

					DECLARE @IDComprobante       INT
					DECLARE @Total               DECIMAL(12,2) = 0
					DECLARE @ID_TipoEntrada      INT
					DECLARE @ID_Actividad		 INT
					DECLARE @Cantidad            INT
					DECLARE @Precio              DECIMAL(12,2)
					DECLARE @IDTipoEntradaParque INT
					DECLARE @i                   INT

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

							IF [actividad].[FN_Actividad_TieneCupo](@ID_Actividad, @Cantidad) = 0
								RAISERROR('No hay cupo suficiente para la actividad %d.', 16, 1, @ID_Actividad)

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
				ROLLBACK;
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