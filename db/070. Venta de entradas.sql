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