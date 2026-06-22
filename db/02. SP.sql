
USE com2900
GO

-- AREA PROTEGIDA OPERACIONES - PROBADO: 

	-- Area Protegida: INSERT
		CREATE OR ALTER PROCEDURE [parque].[SP_AreaProtegida_Insert]
			@ID				 BIGINT,
			@TipoArea        VARCHAR(50),
			@Nombre          VARCHAR(100),
			@Superficie      DECIMAL(12,2)	= NULL,
			@Info_General    VARCHAR(250)	= NULL,
			@Info_Operativa  VARCHAR(250)	= NULL,
			@Latitud         DECIMAL(12,9)	= NULL,
			@Longitud        DECIMAL(12,9)	= NULL
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
			@TipoArea        VARCHAR(50)	= NULL,
			@Nombre          VARCHAR(100)	= NULL,
			@Superficie      DECIMAL(12,2)	= NULL,
			@Info_General    VARCHAR(250)	= NULL,
			@Info_Operativa  VARCHAR(250)	= NULL,
			@Latitud         DECIMAL(12,9)	= NULL,
			@Longitud        DECIMAL(12,9)	= NULL
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
		GO

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

-- ESQUEMA: PERSONAL
	
	-- GUIA AUTORIZADO OPERACIONES - SIN PROBAR:
		
		-- GUIA AUTORIZADO: INSERT
			CREATE OR ALTER PROCEDURE [personal].[SP_GuiaAutorizado_Insert]
				@CUIL		BIGINT,
				@Nombre		VARCHAR(100),
				@Apellido	VARCHAR(100),
				@Autorizado BIT
			AS
			BEGIN
				BEGIN TRY -- HABRIA QUE VER SI VALIDAR EL CUIL.
					INSERT INTO [personal].[GuiaAutorizado](CUIL, Nombre, Apellido, Autorizado)
					VALUES (@CUIL, @Nombre, @Apellido, @Autorizado)
				END TRY
				BEGIN CATCH
					THROW;
				END CATCH
			END
			GO

		-- GUIA AUTORIZADO: UPDATE
			CREATE OR ALTER PROCEDURE [personal].[SP_GuiaAutorizado_Update]
				@CUIL		BIGINT,
				@Nombre		VARCHAR(100) = NULL,
				@Apellido	VARCHAR(100) = NULL,
				@Autorizado BIT			 = NULL
			AS
			BEGIN
				BEGIN TRY
					UPDATE [personal].[GuiaAutorizado]
					SET
						Nombre		= ISNULL(@Nombre, Nombre),
						Apellido	= ISNULL(@Apellido, Apellido),
						Autorizado	= ISNULL(@Autorizado, Autorizado)
					WHERE CUIL = @CUIL
				END TRY
				BEGIN CATCH
					THROW;
				END CATCH
			END
			GO

		-- GUIA AUTORIZADO: DELETE
			CREATE OR ALTER PROCEDURE [personal].[SP_GuiaAutorizado_Delete]
				@CUIL BIGINT
			AS
			BEGIN
				BEGIN TRY
					DELETE FROM [personal].[GuiaAutorizado]
					WHERE CUIL = @CUIL
				END TRY
				BEGIN CATCH
					THROW;
				END CATCH
			END
			GO

	-- TITULO ACADEMICO OPERACIONES - SIN PROBAR: 
		
			-- TITULO ACADEMICO: INSERT
				CREATE OR ALTER PROCEDURE [personal].[SP_TituloAcedemico_Insert]
					@Nombre          VARCHAR(100),
					@Entidad_Otorga  VARCHAR(100),
					@Tipo			 VARCHAR(50),
					@Area			 VARCHAR(50)
				AS
				BEGIN
					BEGIN TRY
						INSERT INTO [personal].[TituloAcademico](Nombre, Entidad_Otorga, Tipo, Area)
						VALUES (@Nombre, @Entidad_Otorga, @Tipo, @Area)
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END
				GO

			-- TITULO ACADEMICO: INSERT
				CREATE OR ALTER PROCEDURE [personal].[SP_TituloAcedemico_Update]
					@ID				 INT,
					@Nombre          VARCHAR(100) = NULL,
					@Entidad_Otorga  VARCHAR(100) = NULL,
					@Tipo			 VARCHAR(50)  = NULL,
					@Area			 VARCHAR(50)  = NULL
				AS
				BEGIN
					BEGIN TRY
						UPDATE [personal].[TituloAcademico]
						SET
							Nombre			= ISNULL(@Nombre,Nombre),
							Entidad_Otorga	= ISNULL(@Entidad_Otorga,Entidad_Otorga),
							Tipo			= ISNULL(@Tipo, Tipo),
							Area			= ISNULL(@Area, Area)
						WHERE ID = @ID
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END
				GO

			-- TITULO ACADEMICO: INSERT
				CREATE OR ALTER PROCEDURE [personal].[SP_TituloAcedemico_Delete]
					@ID INT
				AS
				BEGIN
					BEGIN TRY
						DELETE FROM [personal].[TituloAcademico]
						WHERE ID = @ID
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END
				GO
		
		-- HABILITACION OPERACIONES - SIN PROBAR
			
			-- HABILITACION: INSERT
				CREATE OR ALTER PROCEDURE [personal].[SP_HabilitacionGuia_Insert]
					@Nombre      VARCHAR(50),
					@Descripcion VARCHAR(200)
				AS
				BEGIN
					BEGIN TRY
						INSERT INTO [personal].[HabilitacionGuia](Nombre, Descripcion)
						VALUES (@Nombre, @Descripcion)
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END 
				GO

			-- HABILITACION: UPDATE
				CREATE OR ALTER PROCEDURE [personal].[SP_HabilitacionGuia_Update]
					@ID          INT,
					@Nombre      VARCHAR(50)	= NULL,
					@Descripcion VARCHAR(200)	= NULL 
				AS
				BEGIN
					BEGIN TRY
						UPDATE [personal].[HabilitacionGuia]
						SET 
							Nombre		= ISNULL(@Nombre, Nombre),
							Descripcion	= ISNULL(@Descripcion, Descripcion)
						WHERE ID = @ID
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END 
				GO

			-- HABILITACION: DELETE
				CREATE OR ALTER PROCEDURE [personal].[SP_HabilitacionGuia_Delete]
					@ID INT
				AS
				BEGIN
					BEGIN TRY
						DELETE FROM [personal].[HabilitacionGuia]
						WHERE ID = @ID
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END 
				GO


		-- ESPECIALIDAD OPERACIONES - SIN PROBAR
			
			-- ESPECIALIDAD: Insert
				CREATE OR ALTER PROCEDURE [personal].[SP_EspecialidadGuia_Insert]
					@Nombre      VARCHAR(50),
					@Descripcion VARCHAR(200)
				AS
				BEGIN
					BEGIN TRY
						INSERT INTO [personal].[EspecialidadGuia](Nombre, Descripcion)
						VALUES(@Nombre, @Descripcion)
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END 
				GO

			-- ESPECIALIDAD: 
				CREATE OR ALTER PROCEDURE [personal].[SP_EspecialidadGuia_Update]
					@ID          INT,
					@Nombre      VARCHAR(50)         = NULL,
					@Descripcion VARCHAR(200)        = NULL
				AS
				BEGIN
					BEGIN TRY
						UPDATE [personal].[EspecialidadGuia]
						SET
							Nombre		= ISNULL(@Nombre, Nombre),
							Descripcion	= ISNULL(@Descripcion, Descripcion)
						WHERE ID = @ID
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END 
				GO

			-- ESPECIALIDAD: Delete
				CREATE OR ALTER PROCEDURE [personal].[SP_EspecialidadGuia_Delete]
					@ID INT
				AS
				BEGIN
					BEGIN TRY
						DELETE FROM [personal].[EspecialidadGuia]
						WHERE ID = @ID
					END TRY
					BEGIN CATCH
						THROW;
					END CATCH
				END 
				GO