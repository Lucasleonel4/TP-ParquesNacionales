
USE com2900
GO

-- AREA PROTEGIDA OPERACIONES: 

	-- Area Protegida: INSERT
		CREATE OR ALTER PROCEDURE [parque].[SP_AreaProtegida_Insert]
			@ID				 BIGINT,
			@TipoArea        varchar(50),
			@Nombre          VARCHAR(100),
			@Superficie      DECIMAL(12,2),
			@Info_General    VARCHAR(250),
			@Info_Operativa  VARCHAR(250),
			@Latitud         DECIMAL(12,9),
			@Longitud        DECIMAL(12,9)
		AS
		BEGIN
			BEGIN TRY
				INSERT INTO [parque].[AreaProtegida](ID, TipoArea, Nombre, Superficie, Info_General, Info_Operativa, Latitud, Longitud)
				VALUES(@ID, @TipoArea, @Nombre, @Superficie, @Info_General, @Info_Operativa, @Latitud, @Longitud)
			END TRY
			BEGIN CATCH
				THROW;
			END CATCH
		END
		GO
	
	--  Area Protegida: UPDATE
		CREATE OR ALTER PROCEDURE [parque].[SP_AreaProtegida_Update]
			@ID				 BIGINT,
			@TipoArea        VARCHAR(50),
			@Nombre          VARCHAR(100),
			@Superficie      DECIMAL(12,2),
			@Info_General    VARCHAR(250),
			@Info_Operativa  VARCHAR(250),
			@Latitud         DECIMAL(12,9),
			@Longitud        DECIMAL(12,9)
		AS
		BEGIN
			BEGIN TRY
				UPDATE [parque].[AreaProtegida]
				SET 
					TipoArea       = ISNULL(@TipoArea, TipoArea),
					Nombre	       = ISNULL(@Nombre, Nombre),

					Superficie     = CASE
										WHEN @Superficie = -1 THEN NULL
										ELSE ISNULL(@Superficie, Superficie)
									 END,
				
					Info_General   = CASE
							 			WHEN @Info_General = 'SD' THEN NULL
							    		ELSE ISNULL(@Info_General, Info_General)
									 END,
				
					Info_Operativa = CASE
										WHEN @Info_Operativa = 'SD' THEN NULL
										ELSE ISNULL(@Info_Operativa, Info_Operativa)
									 END,

					Latitud		   = CASE
										WHEN @Latitud = 0 THEN NULL
										ELSE ISNULL(@Latitud, Latitud)
									 END,

					Longitud	   = CASE
										WHEN @Longitud = 0 THEN NULL
										ELSE ISNULL(@Longitud, Longitud)
									 END
				WHERE ID = @ID;
			END TRY
			BEGIN CATCH
				THROW;
			END CATCH
		END
		GO

	--  Area Protegida: DELETE
		CREATE OR ALTER PROCEDURE [parque].[SP_AreaProtegida_Delete]
			@ID BIGINT
		AS
		BEGIN
			BEGIN TRY
				DELETE FROM [parque].[AreaProtegida]
				WHERE ID = @ID;
			END TRY
			BEGIN CATCH
				THROW;
			END CATCH
		END