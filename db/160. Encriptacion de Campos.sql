/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Mancilla Muñoz, Emmanuel Américo
*  - Ruiz Carletti, Emiliano
*  - Costilla, Lucas Leonel
*  - Perla, Gustavo
* Fecha: 30/06/2026
* Script: 160. Encriptacion de Campos
* Descripción: Agrega cifrado auxiliar para CUIL de guardaparques y guias autorizados, y adapta sus ABM.
*/

USE com2900;
GO

IF SCHEMA_ID('encriptado') IS NULL
BEGIN
	EXEC('CREATE SCHEMA encriptado');
	PRINT('OK: Esquema encriptado creado exitosamente');
END
ELSE PRINT('INFO: El esquema encriptado ya existe');
GO

CREATE OR ALTER FUNCTION encriptado.Encriptar
(
	@Valor NVARCHAR(MAX),
	@FraseClave NVARCHAR(128) = NULL,
	@Salt VARBINARY(256) = NULL
)
RETURNS VARBINARY(256)
AS
BEGIN
	RETURN EncryptByPassPhrase(
		COALESCE(@FraseClave, 'ClavePorDefectoEncriptado@Supersecreta'),
		@Valor,
		1,
		COALESCE(@Salt, CONVERT(VARBINARY(256), 0))
	);
END;
GO

CREATE OR ALTER FUNCTION encriptado.Desencriptar
(
	@ValorCifrado VARBINARY(256),
	@FraseClave NVARCHAR(128) = NULL,
	@Salt VARBINARY(256) = NULL
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	RETURN CONVERT(NVARCHAR(MAX),
		DecryptByPassPhrase(
			COALESCE(@FraseClave, 'ClavePorDefectoEncriptado@Supersecreta'),
			@ValorCifrado,
			1,
			COALESCE(@Salt, CONVERT(VARBINARY(256), 0))
		)
	);
END;
GO

IF COL_LENGTH('personal.Guardaparques', 'CUIL_Cifrado') IS NULL
BEGIN
	ALTER TABLE personal.Guardaparques
	ADD CUIL_Cifrado VARBINARY(256) NULL;
	PRINT('OK: La columna CUIL_Cifrado en personal.Guardaparques fue creada');
END
ELSE PRINT('INFO: La columna CUIL_Cifrado en personal.Guardaparques ya existe');
GO

IF COL_LENGTH('personal.GuiaAutorizado', 'CUIL_Cifrado') IS NULL
BEGIN
	ALTER TABLE personal.GuiaAutorizado
	ADD CUIL_Cifrado VARBINARY(256) NULL;
	PRINT('OK: La columna CUIL_Cifrado en personal.GuiaAutorizado fue creada');
END
ELSE PRINT('INFO: La columna CUIL_Cifrado en personal.GuiaAutorizado ya existe');
GO

UPDATE personal.Guardaparques
SET CUIL_Cifrado = encriptado.Encriptar(CONVERT(NVARCHAR(MAX), CUIL), NULL, CONVERT(VARBINARY(256), Nombre))
WHERE CUIL_Cifrado IS NULL;
GO

UPDATE personal.GuiaAutorizado
SET CUIL_Cifrado = encriptado.Encriptar(CONVERT(NVARCHAR(MAX), CUIL), NULL, CONVERT(VARBINARY(256), Nombre))
WHERE CUIL_Cifrado IS NULL;
GO

CREATE OR ALTER PROCEDURE personal.GuardaparquesAlta
	@CUIL            BIGINT,
	@Nombre          VARCHAR(100),
	@Apellido        VARCHAR(100),
	@FechaNacimiento DATE,
	@FechaIngreso    DATE,
	@FechaEgreso     DATE         = NULL,
	@MotivoEgreso    VARCHAR(255) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO personal.Guardaparques(CUIL, Nombre, Apellido, FechaNacimiento, FechaIngreso, FechaEgreso, MotivoEgreso, CUIL_Cifrado)
	VALUES (
		@CUIL,
		@Nombre,
		@Apellido,
		@FechaNacimiento,
		@FechaIngreso,
		@FechaEgreso,
		@MotivoEgreso,
		encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL), NULL, CONVERT(VARBINARY(256), @Nombre))
	);
END;
GO

CREATE OR ALTER PROCEDURE personal.GuardaparquesModificacion
	@CUIL            BIGINT,
	@Nombre          VARCHAR(100) = NULL,
	@Apellido        VARCHAR(100) = NULL,
	@FechaNacimiento DATE         = NULL,
	@FechaIngreso    DATE         = NULL,
	@FechaEgreso     DATE         = NULL,
	@MotivoEgreso    VARCHAR(255) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE personal.Guardaparques
	SET
		Nombre          = ISNULL(@Nombre, Nombre),
		Apellido        = ISNULL(@Apellido, Apellido),
		FechaNacimiento = ISNULL(@FechaNacimiento, FechaNacimiento),
		FechaIngreso    = ISNULL(@FechaIngreso, FechaIngreso),
		FechaEgreso     = ISNULL(@FechaEgreso, FechaEgreso),
		MotivoEgreso    = ISNULL(@MotivoEgreso, MotivoEgreso),
		CUIL_Cifrado    = encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL), NULL, CONVERT(VARBINARY(256), ISNULL(@Nombre, Nombre)))
	WHERE CUIL = @CUIL;
END;
GO

CREATE OR ALTER PROCEDURE personal.GuiaAutorizadoAlta
	@CUIL       BIGINT,
	@Nombre     VARCHAR(100),
	@Apellido   VARCHAR(100),
	@Autorizado BIT
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO personal.GuiaAutorizado(CUIL, Nombre, Apellido, Autorizado, CUIL_Cifrado)
	VALUES (
		@CUIL,
		@Nombre,
		@Apellido,
		@Autorizado,
		encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL), NULL, CONVERT(VARBINARY(256), @Nombre))
	);
END;
GO

CREATE OR ALTER PROCEDURE personal.GuiaAutorizadoModificacion
	@CUIL       BIGINT,
	@Nombre     VARCHAR(100) = NULL,
	@Apellido   VARCHAR(100) = NULL,
	@Autorizado BIT          = NULL
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE personal.GuiaAutorizado
	SET
		Nombre       = ISNULL(@Nombre, Nombre),
		Apellido     = ISNULL(@Apellido, Apellido),
		Autorizado   = ISNULL(@Autorizado, Autorizado),
		CUIL_Cifrado = encriptado.Encriptar(CONVERT(NVARCHAR(MAX), @CUIL), NULL, CONVERT(VARBINARY(256), ISNULL(@Nombre, Nombre)))
	WHERE CUIL = @CUIL;
END;
GO

PRINT('INFO: Para verificar el cifrado, consultar CUIL_Cifrado y usar encriptado.Desencriptar con el mismo salt utilizado.');
GO
