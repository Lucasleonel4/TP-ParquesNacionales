USE com2900;
GO

CREATE OR ALTER PROCEDURE [venta].[SP_VentaEntradas]
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
			DECLARE @Total					DECIMAL(12,2)

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
						@PrecioCobrado        = @Total

					SET @i = @i + 1
				END
			COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END