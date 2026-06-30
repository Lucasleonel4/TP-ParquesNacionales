/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Mancilla Muñoz, Emmanuel Américo
*  - Ruiz Carletti, Emiliano
*  - Costilla, Lucas Leonel
* Fecha: 30/06/2026
* Script: 130. Encriptado de Campos
* Descripción: Se crean funciones y modifican procedimientos para encriptar en un campo auxiliar, el campo secreto CUIL de la tabla guardaparques y guia autorizado.
*/

USE com2900;
GO

-- ============================================================
-- Esquema para Encapsular Funciones de Encriptado
-- ============================================================
	IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'encriptado')
		BEGIN TRY
			EXEC('CREATE SCHEMA encriptado')
			PRINT('OK: Esquema encriptado creado exitosamente');
		END TRY
		BEGIN CATCH
			PRINT('ERROR: No se pudo crear el esquema encriptado');
			THROW
		END CATCH
	ELSE PRINT('INFO: El esquema encriptado ya existe');
	GO

-- ================================================================
-- Funciones Envoltorio para Encriptado de CUIL: 
	-- Se definen funciones genericas para encriptar y desencriptar el CUIL de Guardaparques y Guias Autorizados con la misma frase default. Varía el salt.
-- ================================================================
	CREATE OR ALTER FUNCTION encriptado.Encriptar
	(
		@Valor NVARCHAR(MAX),
		@FraseClave NVARCHAR(128)	= NULL,
		@Salt VARBINARY(256)		= NULL --Salt Opcional. Es un VARBINARY que se envía como encriptar(...,...,convert(varbinary, campoConvertir)), puede ser encriptar(..., null, null) == encriptar(...)
	)
	RETURNS VARBINARY(256)
	AS
	BEGIN
		RETURN EncryptByPassPhrase(COALESCE(@FraseClave,'ClavePorDefectoEncriptado@Supersecreta'), @Valor, 1, COALESCE(@Salt, CONVERT(VARBINARY(256), 0)));
	END;
	GO

	CREATE OR ALTER FUNCTION encriptado.Desencriptar
	(
		@ValorCifrado VARBINARY(256),
		@FraseClave NVARCHAR(128)		= NULL,
		@Salt VARBINARY(256)			= NULL --Si se definió un salt para encriptar, necesariamente se debera usar el mismo salt para desencriptar
	)
	RETURNS NVARCHAR(MAX)
	AS
	BEGIN
		RETURN CONVERT(NVARCHAR(MAX),
			DecryptByPassPhrase(COALESCE(@FraseClave,'ClavePorDefectoEncriptado@Supersecreta'), @ValorCifrado, 1, COALESCE(@Salt, CONVERT(VARBINARY(256), 0)))
		);
	END;	   
	GO

-- ==================================================================================
-- Modifiación sobre Tabla Guardaparques y Guia Autorizado Agregando CUIL Encriptado
-- ==================================================================================
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'personal' AND TABLE_NAME = 'guardaparques' AND COLUMN_NAME = 'CUIL_Cifrado' )
	BEGIN
		ALTER TABLE [personal].[Guardaparques]
		ADD CUIL_Cifrado VARBINARY(256);
		PRINT('OK: La columna CUIL_Cifrado en la tabla [personal].[Guardaparques] fue creada');
	END
	ELSE PRINT('INFO: La columna CUIL_Cifrado en la tabla [personal].[Guardaparques] ya existe');
	
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'personal' AND TABLE_NAME = 'guardaparques' AND COLUMN_NAME = 'CUIL_Cifrado' )
	BEGIN
		ALTER TABLE [personal].[GuiaAutorizado]
		ADD CUIL_Cifrado VARBINARY(256);
		PRINT('OK: La columna CUIL_Cifrado en la tabla [personal].[GuiaAutorizado] fue creada');
	END
	ELSE PRINT('INFO: La columna CUIL_Cifrado en la tabla [personal].[GuiaAutorizado] ya existe');
	GO

-- ==============================================================================
-- Cifrado de CUIL en Campo Auxiliar sobre Tabla Guardaparques y Guia Autorizado 
-- ==============================================================================
	UPDATE [personal].[Guardaparques]
	SET CUIL_Cifrado = encriptado.Encriptar(CONVERT(NVARCHAR(MAX), CUIL),null,CONVERT(VARBINARY(256), Nombre))
	GO

	UPDATE [personal].[GuiaAutorizado]
	SET CUIL_Cifrado = encriptado.Encriptar(CONVERT(NVARCHAR(MAX), CUIL),null,CONVERT(VARBINARY(256), Nombre))
	GO

-- ==============================================================================
-- Consulta Obteniendo CUIL Descifrado 
-- ==============================================================================	
	SELECT CUIL, Nombre, Apellido, FechaNacimiento, FechaIngreso, FechaEgreso, MotivoEgreso, CUIL_Cifrado, encriptado.Desencriptar(CUIL_Cifrado, null, CONVERT(VARBINARY(256), Nombre)) AS CUIL_Descifrado
	FROM [personal].[Guardaparques]

	SELECT CUIL, Nombre, Apellido, Autorizado, CUIL_Cifrado, encriptado.Desencriptar(CUIL_Cifrado, null, CONVERT(VARBINARY(256), Nombre)) AS CUIL_Descifrado
	FROM [personal].[GuiaAutorizado]
	GO

-- ==============================================================================
-- Modificación de SP ABM de Guardaparques para cifrar campo adicional 
-- ==============================================================================	
	CREATE OR ALTER PROCEDURE [personal].[GuardaparquesAlta]
		@CUIL            BIGINT,
		@Nombre          VARCHAR(100),
		@Apellido        VARCHAR(100),
		@FechaNacimiento DATE,
		@FechaIngreso    DATE,
		@FechaEgreso     DATE         = NULL,
		@MotivoEgreso    VARCHAR(255) = NULL
	AS
	BEGIN
		BEGIN TRY
			INSERT INTO [personal].[Guardaparques](CUIL, Nombre, Apellido, FechaNacimiento, FechaIngreso, FechaEgreso, MotivoEgreso, CUIL_Cifrado)
			VALUES (@CUIL, @Nombre, @Apellido, @FechaNacimiento, @FechaIngreso, @FechaEgreso, @MotivoEgreso,encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL),null,CONVERT(VARBINARY(256), @Nombre)))
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END
	GO

	CREATE OR ALTER PROCEDURE [personal].[GuardaparquesModificacion]
		@CUIL            BIGINT       = NULL,
		@Nombre          VARCHAR(100) = NULL,
		@Apellido        VARCHAR(100) = NULL,
		@FechaNacimiento DATE         = NULL,
		@FechaIngreso    DATE         = NULL,
		@FechaEgreso     DATE         = NULL,
		@MotivoEgreso    VARCHAR(255) = NULL
	AS
	BEGIN
		BEGIN TRY
			UPDATE [personal].[Guardaparques]
			SET
				Nombre          = ISNULL(@Nombre, Nombre),
				Apellido        = ISNULL(@Apellido, Apellido),
				FechaNacimiento = ISNULL(@FechaNacimiento, FechaNacimiento),
				FechaIngreso    = ISNULL(@FechaIngreso, FechaIngreso),
				FechaEgreso     = ISNULL(@FechaEgreso, FechaEgreso),
				MotivoEgreso    = ISNULL(@MotivoEgreso, MotivoEgreso),
				CUIL_Cifrado	= encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL),null,CONVERT(VARBINARY(256), ISNULL(@Nombre, Nombre)))
			WHERE CUIL = @CUIL
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END
	GO

-- ==============================================================================
-- Modificación de SP ABM de Guia Autorizado para cifrar campo adicional 
-- ==============================================================================	
	CREATE OR ALTER PROCEDURE [personal].[GuiaAutorizadoAlta]
		@CUIL		BIGINT,
		@Nombre		VARCHAR(100),
		@Apellido	VARCHAR(100),
		@Autorizado BIT
	AS
		INSERT INTO [personal].[GuiaAutorizado](CUIL, Nombre, Apellido, Autorizado, CUIL_Cifrado)
		VALUES (@CUIL, @Nombre, @Apellido, @Autorizado, encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL),null,CONVERT(VARBINARY(256), @Nombre)))
	GO


	CREATE OR ALTER PROCEDURE [personal].[GuiaAutorizadoModificacion]
	@CUIL		BIGINT,
	@Nombre		VARCHAR(100) = NULL,
	@Apellido	VARCHAR(100) = NULL,
	@Autorizado BIT			 = NULL
	AS
	UPDATE [personal].[GuiaAutorizado]
	SET
		Nombre			= ISNULL(@Nombre, Nombre),
		Apellido		= ISNULL(@Apellido, Apellido),
		Autorizado		= ISNULL(@Autorizado, Autorizado),
		CUIL_Cifrado	= encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL),null,CONVERT(VARBINARY(256), ISNULL(@Nombre, Nombre)))
	WHERE CUIL = @CUIL
	GO