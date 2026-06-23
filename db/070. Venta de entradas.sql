-- PUNTO DE VENTA OPERACIONES - SIN PROBAR:

-- PUNTO DE VENTA: INSERT
CREATE OR ALTER PROCEDURE [parque].[SP_PuntoDeVenta_Insert]
	@ID_AreaProtegida	BIGINT,
	@Descripcion		VARCHAR(100) = NULL
AS
BEGIN
	BEGIN TRY 
		INSERT INTO [parque].[PuntoDeVenta](ID_AreaProtegida, Descripcion)
		VALUES (@ID_AreaProtegida, @Descripcion)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- PUNTO DE VENTA: UPDATE
CREATE OR ALTER PROCEDURE [parque].[SP_PuntoDeVenta_Update]
	@ID					INT,
	@ID_AreaProtegida	BIGINT			=	NULL,
	@Descripcion		VARCHAR(100)	=	NULL
AS
BEGIN
	BEGIN TRY
		UPDATE [parque].[PuntoDeVenta]
		SET
			ID_AreaProtegida	= ISNULL(@ID_AreaProtegida, ID_AreaProtegida),
			Descripcion			= CASE
										WHEN @Descripcion = 'SD' THEN NULL
										ELSE ISNULL(@Descripcion, Descripcion)
								  END
		WHERE ID = @ID
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

-- PUNTO DE VENTA: DELETE
CREATE OR ALTER PROCEDURE [parque].[SP_PuntoDeVenta_Delete]
	@ID INT
AS
BEGIN
	BEGIN TRY
		DELETE FROM [parque].[PuntoDeVenta]
		WHERE ID = @ID
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO