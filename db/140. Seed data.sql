/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emmanuel Américo
*  - Perla, Gustavo
*  - Ruiz Carletti, Emiliano
* Fecha: 29/06/2026
* Script: 140. Seed data
* Descripción: Carga datos de prueba idempotentes para reportes, defensa y criterios de aceptación del TP.
*/

USE com2900;
GO

SET NOCOUNT ON;

PRINT('Seed: provincias, parques y puntos de venta');

DECLARE @ProvinciasSeed TABLE (ID INT PRIMARY KEY, Nombre VARCHAR(200));
INSERT INTO @ProvinciasSeed(ID, Nombre)
VALUES
	(1, 'Buenos Aires'), (2, 'Catamarca'), (3, 'Chaco'), (4, 'Chubut'), (5, 'Cordoba'),
	(6, 'Corrientes'), (7, 'Entre Rios'), (8, 'Formosa'), (9, 'Jujuy'), (10, 'La Pampa'),
	(11, 'La Rioja'), (12, 'Mendoza'), (13, 'Misiones'), (14, 'Neuquen'), (15, 'Rio Negro'),
	(16, 'Salta'), (17, 'San Juan'), (18, 'San Luis'), (19, 'Santa Cruz'), (20, 'Tierra del Fuego');

INSERT INTO parque.Provincia(ID, Nombre)
SELECT S.ID, S.Nombre
FROM @ProvinciasSeed S
WHERE NOT EXISTS (SELECT 1 FROM parque.Provincia P WHERE P.ID = S.ID);

DECLARE @ParquesSeed TABLE (
	ID BIGINT PRIMARY KEY,
	ID_Provincia INT,
	TipoArea VARCHAR(50),
	Nombre VARCHAR(100),
	Superficie DECIMAL(12,2),
	Latitud DECIMAL(12,9),
	Longitud DECIMAL(12,9)
);

INSERT INTO @ParquesSeed(ID, ID_Provincia, TipoArea, Nombre, Superficie, Latitud, Longitud)
VALUES
	(910001, 13, 'Parque Nacional', 'PN Seed Iguazu', 676.20, -25.695259000, -54.436666000),
	(910002, 15, 'Parque Nacional', 'PN Seed Nahuel Huapi', 7172.61, -41.134000000, -71.310000000),
	(910003, 19, 'Parque Nacional', 'PN Seed Los Glaciares', 7269.27, -49.331494000, -72.886328000),
	(910004, 20, 'Parque Nacional', 'PN Seed Tierra del Fuego', 689.09, -54.642256999, -68.485974089),
	(910005, 6, 'Parque Nacional', 'PN Seed Ibera', 1835.00, -28.536000000, -57.170000000),
	(910006, 14, 'Parque Nacional', 'PN Seed Lanin', 2169.93, -39.715000000, -71.500000000),
	(910007, 4, 'Parque Nacional', 'PN Seed Los Alerces', 1883.79, -42.861000000, -71.878000000),
	(910008, 16, 'Parque Nacional', 'PN Seed Baritu', 724.39, -22.470000000, -64.740000000),
	(910009, 3, 'Parque Nacional', 'PN Seed Chaco', 149.81, -26.807000000, -59.608000000),
	(910010, 18, 'Parque Nacional', 'PN Seed Sierra de las Quijadas', 735.34, -32.474000000, -67.018000000);

INSERT INTO parque.AreaProtegida(ID, TipoArea, Nombre, Superficie, Info_General, Info_Operativa, Calle_Entrada, Nro_Entrada, Latitud, Longitud)
SELECT S.ID, S.TipoArea, S.Nombre, S.Superficie,
	'Parque cargado por seed para pruebas integrales.',
	'Abierto con servicios turisticos y actividades programadas.',
	'Acceso principal', 'S/N', S.Latitud, S.Longitud
FROM @ParquesSeed S
WHERE NOT EXISTS (SELECT 1 FROM parque.AreaProtegida A WHERE A.ID = S.ID);

INSERT INTO parque.ProvinciaContieneParque(ID_Provincia, ID_AreaProtegida)
SELECT S.ID_Provincia, S.ID
FROM @ParquesSeed S
WHERE NOT EXISTS (
	SELECT 1
	FROM parque.ProvinciaContieneParque PCP
	WHERE PCP.ID_Provincia = S.ID_Provincia
	  AND PCP.ID_AreaProtegida = S.ID
);

INSERT INTO parque.PuntoDeVenta(ID_AreaProtegida, Descripcion)
SELECT S.ID, 'Boleteria Seed'
FROM @ParquesSeed S
WHERE NOT EXISTS (
	SELECT 1
	FROM parque.PuntoDeVenta PV
	WHERE PV.ID_AreaProtegida = S.ID
	  AND PV.Descripcion = 'Boleteria Seed'
);

PRINT('Seed: divisas, tipos de entrada y precios por parque');

IF NOT EXISTS (SELECT 1 FROM venta.Divisa WHERE COD_ISO = 'ARS')
	INSERT INTO venta.Divisa(COD_ISO, Pais, ValorEnPesos) VALUES ('ARS', 'Argentina', 1);

IF NOT EXISTS (SELECT 1 FROM venta.Divisa WHERE COD_ISO = 'USD')
	INSERT INTO venta.Divisa(COD_ISO, Pais, ValorEnPesos) VALUES ('USD', 'Estados Unidos', 1200);

DECLARE @TiposEntradaSeed TABLE (Nombre VARCHAR(100) PRIMARY KEY);
INSERT INTO @TiposEntradaSeed(Nombre)
VALUES ('Residente Seed'), ('Extranjero Seed'), ('Estudiante Seed');

INSERT INTO venta.TipoEntrada(Nombre)
SELECT S.Nombre
FROM @TiposEntradaSeed S
WHERE NOT EXISTS (SELECT 1 FROM venta.TipoEntrada T WHERE T.Nombre = S.Nombre);

INSERT INTO venta.TipoEntradaParque(ID_AreaProtegida, ID_TipoEntrada, Precio)
SELECT
	P.ID,
	T.ID,
	CASE T.Nombre
		WHEN 'Extranjero Seed' THEN 15000
		WHEN 'Estudiante Seed' THEN 2500
		ELSE 6000
	END
FROM @ParquesSeed P
CROSS JOIN venta.TipoEntrada T
WHERE T.Nombre IN ('Residente Seed', 'Extranjero Seed', 'Estudiante Seed')
  AND NOT EXISTS (
		SELECT 1
		FROM venta.TipoEntradaParque TEP
		WHERE TEP.ID_AreaProtegida = P.ID
		  AND TEP.ID_TipoEntrada = T.ID
  );

PRINT('Seed: actividades y tours');

DECLARE @TiposActividadSeed TABLE (Nombre VARCHAR(50) PRIMARY KEY);
INSERT INTO @TiposActividadSeed(Nombre)
VALUES ('Trekking Seed'), ('Navegacion Seed'), ('Avistaje Seed'), ('Centro Interpretacion Seed'), ('Tour Guiado Seed');

INSERT INTO actividad.TipoActividad(Nombre)
SELECT S.Nombre
FROM @TiposActividadSeed S
WHERE NOT EXISTS (SELECT 1 FROM actividad.TipoActividad T WHERE T.Nombre = S.Nombre);

DECLARE @ActividadesSeed TABLE (
	ID_AreaProtegida BIGINT,
	TipoActividad VARCHAR(50),
	Nombre VARCHAR(50),
	Duracion INT,
	Costo DECIMAL(12,2),
	CupoMaximo INT
);

INSERT INTO @ActividadesSeed(ID_AreaProtegida, TipoActividad, Nombre, Duracion, Costo, CupoMaximo)
VALUES
	(910001, 'Tour Guiado Seed', 'Tour Garganta Seed', 120, 3500, 20),
	(910001, 'Avistaje Seed', 'Avistaje Selva Seed', 90, 1800, 15),
	(910001, 'Centro Interpretacion Seed', 'Centro Yaguarete Seed', 60, 0, 40),
	(910002, 'Trekking Seed', 'Trekking Arrayanes Seed', 180, 4200, 18),
	(910002, 'Navegacion Seed', 'Navegacion Lago Seed', 150, 8000, 25),
	(910002, 'Tour Guiado Seed', 'Tour Mirador Seed', 75, 2500, 5),
	(910003, 'Trekking Seed', 'Trekking Glaciar Seed', 240, 9500, 12),
	(910003, 'Tour Guiado Seed', 'Tour Pasarelas Seed', 120, 3000, 30),
	(910003, 'Avistaje Seed', 'Avistaje Condor Seed', 80, 1600, 14),
	(910004, 'Trekking Seed', 'Trekking Bahia Seed', 160, 4500, 16),
	(910004, 'Navegacion Seed', 'Navegacion Canal Seed', 180, 11000, 20),
	(910004, 'Centro Interpretacion Seed', 'Centro Austral Seed', 55, 0, 35),
	(910005, 'Avistaje Seed', 'Avistaje Esteros Seed', 100, 2600, 18),
	(910005, 'Navegacion Seed', 'Navegacion Ibera Seed', 130, 7000, 22),
	(910005, 'Tour Guiado Seed', 'Tour Portal Seed', 90, 2800, 20),
	(910006, 'Trekking Seed', 'Trekking Volcan Seed', 220, 6500, 15),
	(910006, 'Tour Guiado Seed', 'Tour Bosque Seed', 100, 2400, 25),
	(910006, 'Avistaje Seed', 'Avistaje Huemul Seed', 80, 1500, 12),
	(910007, 'Trekking Seed', 'Trekking Alerzal Seed', 210, 5900, 14),
	(910007, 'Navegacion Seed', 'Navegacion Futalaufquen Seed', 140, 7500, 18),
	(910007, 'Centro Interpretacion Seed', 'Centro Alerces Seed', 60, 0, 30),
	(910008, 'Trekking Seed', 'Trekking Yungas Seed', 200, 5200, 12),
	(910008, 'Avistaje Seed', 'Avistaje Tucan Seed', 85, 1700, 16),
	(910008, 'Tour Guiado Seed', 'Tour Frontera Seed', 110, 3100, 15),
	(910009, 'Trekking Seed', 'Trekking Quebrachal Seed', 120, 2200, 20),
	(910009, 'Avistaje Seed', 'Avistaje Laguna Seed', 90, 1600, 20),
	(910009, 'Centro Interpretacion Seed', 'Centro Chaco Seed', 50, 0, 40),
	(910010, 'Trekking Seed', 'Trekking Farallones Seed', 180, 4800, 16),
	(910010, 'Tour Guiado Seed', 'Tour Huellas Seed', 105, 2900, 20),
	(910010, 'Avistaje Seed', 'Avistaje Guanaco Seed', 75, 1400, 18);

INSERT INTO actividad.Actividad(ID_AreaProtegida, ID_TipoActividad, Nombre, Duracion, Costo, CupoMaximo, CupoLibre)
SELECT A.ID_AreaProtegida, TA.ID, A.Nombre, A.Duracion, A.Costo, A.CupoMaximo, A.CupoMaximo
FROM @ActividadesSeed A
JOIN actividad.TipoActividad TA ON TA.Nombre = A.TipoActividad
WHERE NOT EXISTS (
	SELECT 1
	FROM actividad.Actividad X
	WHERE X.ID_AreaProtegida = A.ID_AreaProtegida
	  AND X.Nombre = A.Nombre
);

PRINT('Seed: guias, habilitaciones, permisos y asignaciones');

IF NOT EXISTS (SELECT 1 FROM personal.HabilitacionGuia WHERE Nombre = 'Habilitacion General Seed')
	INSERT INTO personal.HabilitacionGuia(Nombre, Descripcion)
	VALUES ('Habilitacion General Seed', 'Habilitacion de guia para actividades turisticas.');

IF NOT EXISTS (SELECT 1 FROM personal.EspecialidadGuia WHERE Nombre = 'Interpretacion Ambiental Seed')
	INSERT INTO personal.EspecialidadGuia(Nombre, Descripcion)
	VALUES ('Interpretacion Ambiental Seed', 'Especialidad cargada para seed data.');

IF NOT EXISTS (SELECT 1 FROM personal.TituloAcademico WHERE Nombre = 'Guia de Turismo Seed' AND Entidad_Otorga = 'Instituto Seed')
	INSERT INTO personal.TituloAcademico(Nombre, Entidad_Otorga, Tipo, Area)
	VALUES ('Guia de Turismo Seed', 'Instituto Seed', 'Tecnicatura', 'Turismo');

DECLARE @IDHabilitacion INT = (SELECT ID FROM personal.HabilitacionGuia WHERE Nombre = 'Habilitacion General Seed');
DECLARE @IDEspecialidad INT = (SELECT ID FROM personal.EspecialidadGuia WHERE Nombre = 'Interpretacion Ambiental Seed');
DECLARE @IDTitulo INT = (SELECT ID FROM personal.TituloAcademico WHERE Nombre = 'Guia de Turismo Seed' AND Entidad_Otorga = 'Instituto Seed');

DECLARE @n INT = 1;
WHILE @n <= 20
BEGIN
	DECLARE @CUILGuia BIGINT = 27000000000 + @n;
	DECLARE @IDParqueGuia BIGINT = 910000 + (((@n - 1) % 10) + 1);

	IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE CUIL = @CUILGuia)
		INSERT INTO personal.GuiaAutorizado(CUIL, Nombre, Apellido, Autorizado)
		VALUES (@CUILGuia, CONCAT('GuiaSeed', @n), CONCAT('ApellidoSeed', @n), 1);

	IF NOT EXISTS (SELECT 1 FROM personal.GuiaConHabilitacion WHERE CUIL_GuiaAutorizado = @CUILGuia AND ID_HabilitacionGuia = @IDHabilitacion)
		INSERT INTO personal.GuiaConHabilitacion(CUIL_GuiaAutorizado, ID_HabilitacionGuia, FechaObtenido, FechaExpiracion)
		VALUES (@CUILGuia, @IDHabilitacion, '2024-01-01', '2028-12-31');

	IF NOT EXISTS (SELECT 1 FROM personal.GuiaConEspecialidad WHERE CUIL_GuiaAutorizado = @CUILGuia AND ID_EspecialidadGuia = @IDEspecialidad)
		INSERT INTO personal.GuiaConEspecialidad(CUIL_GuiaAutorizado, ID_EspecialidadGuia, FechaObtenida)
		VALUES (@CUILGuia, @IDEspecialidad, '2024-01-01');

	IF NOT EXISTS (SELECT 1 FROM personal.GuiaConTitulo WHERE CUIL_GuiaAutorizado = @CUILGuia AND ID_TituloAcademico = @IDTitulo)
		INSERT INTO personal.GuiaConTitulo(CUIL_GuiaAutorizado, ID_TituloAcademico, FechaObtenido)
		VALUES (@CUILGuia, @IDTitulo, '2023-12-01');

	IF NOT EXISTS (SELECT 1 FROM personal.PermisoDeTrabajo WHERE CUIL_GuiaAutorizado = @CUILGuia AND ID_AreaProtegida = @IDParqueGuia)
		INSERT INTO personal.PermisoDeTrabajo(ID_AreaProtegida, CUIL_GuiaAutorizado, FechaInicio, FechaFin)
		VALUES (@IDParqueGuia, @CUILGuia, '2024-01-01', '2028-12-31');

	SET @n += 1;
END;

;WITH ActividadesNumeradas AS (
	SELECT ID, ID_AreaProtegida
	FROM actividad.Actividad
	WHERE Nombre LIKE '% Seed'
)
INSERT INTO actividad.GuiaAsignadoTour(ID_Actividad, CUIL_GuiaAutorizado)
SELECT A.ID, 27000000000 + CAST(A.ID_AreaProtegida - 910000 AS INT)
FROM ActividadesNumeradas A
JOIN actividad.Actividad ACT ON ACT.ID = A.ID
JOIN personal.PermisoDeTrabajo PT ON PT.CUIL_GuiaAutorizado = 27000000000 + CAST(A.ID_AreaProtegida - 910000 AS INT)
	AND PT.ID_AreaProtegida = ACT.ID_AreaProtegida
WHERE NOT EXISTS (
	SELECT 1
	FROM actividad.GuiaAsignadoTour G
	WHERE G.ID_Actividad = A.ID
	  AND G.CUIL_GuiaAutorizado = 27000000000 + CAST(A.ID_AreaProtegida - 910000 AS INT)
);

PRINT('Seed: guardaparques y contratos');

SET @n = 1;
WHILE @n <= 20
BEGIN
	DECLARE @CUILGuardaparque BIGINT = 23000000000 + @n;
	DECLARE @IDParqueGuardaparque BIGINT = 910000 + (((@n - 1) % 10) + 1);

	IF NOT EXISTS (SELECT 1 FROM personal.Guardaparques WHERE CUIL = @CUILGuardaparque)
		INSERT INTO personal.Guardaparques(CUIL, Nombre, Apellido, FechaNacimiento, FechaIngreso, FechaEgreso, MotivoEgreso)
		VALUES (@CUILGuardaparque, CONCAT('GuardaparqueSeed', @n), CONCAT('ApellidoSeed', @n), DATEFROMPARTS(1980 + (@n % 12), 1, 15), '2020-01-01', NULL, NULL);

	IF NOT EXISTS (SELECT 1 FROM personal.ContratoTrabajo WHERE CUIL_Guardaparques = @CUILGuardaparque AND ID_AreaProtegida = @IDParqueGuardaparque)
		INSERT INTO personal.ContratoTrabajo(ID_AreaProtegida, CUIL_Guardaparques, FechaInicio, FechaFin)
		VALUES (@IDParqueGuardaparque, @CUILGuardaparque, '2020-01-01', NULL);

	SET @n += 1;
END;

PRINT('Seed: historial de ventas e inscripciones');

DECLARE @VentaSeed TABLE (
	ID INT IDENTITY(1,1),
	ID_AreaProtegida BIGINT,
	FechaHora DATETIME,
	TipoEntrada VARCHAR(100),
	Cantidad INT,
	MedioDePago VARCHAR(20)
);

SET @n = 1;
WHILE @n <= 60
BEGIN
	INSERT INTO @VentaSeed(ID_AreaProtegida, FechaHora, TipoEntrada, Cantidad, MedioDePago)
	VALUES (
		910000 + (((@n - 1) % 10) + 1),
		DATEADD(DAY, @n * 7, '2025-01-04T10:00:00'),
		CASE WHEN @n % 3 = 0 THEN 'Extranjero Seed' WHEN @n % 3 = 1 THEN 'Residente Seed' ELSE 'Estudiante Seed' END,
		CASE WHEN @n % 4 = 0 THEN 4 WHEN @n % 4 = 1 THEN 2 ELSE 3 END,
		CASE WHEN @n % 3 = 0 THEN 'Tarjeta' WHEN @n % 3 = 1 THEN 'Efectivo' ELSE 'Transferencia' END
	);

	SET @n += 1;
END;

DECLARE @VentaActual INT = 1;
DECLARE @VentaMax INT = (SELECT MAX(ID) FROM @VentaSeed);

WHILE @VentaActual <= @VentaMax
BEGIN
	DECLARE @IDAreaVenta BIGINT;
	DECLARE @FechaVenta DATETIME;
	DECLARE @TipoEntradaVenta VARCHAR(100);
	DECLARE @CantidadVenta INT;
	DECLARE @MedioPagoVenta VARCHAR(20);
	DECLARE @IDPuntoVenta INT;
	DECLARE @IDTipoEntrada INT;
	DECLARE @IDTipoEntradaParque INT;
	DECLARE @PrecioEntrada DECIMAL(12,2);
	DECLARE @TotalVenta DECIMAL(12,2);
	DECLARE @IDComprobante INT;

	SELECT
		@IDAreaVenta = ID_AreaProtegida,
		@FechaVenta = FechaHora,
		@TipoEntradaVenta = TipoEntrada,
		@CantidadVenta = Cantidad,
		@MedioPagoVenta = MedioDePago
	FROM @VentaSeed
	WHERE ID = @VentaActual;

	SELECT TOP 1 @IDPuntoVenta = ID
	FROM parque.PuntoDeVenta
	WHERE ID_AreaProtegida = @IDAreaVenta
	ORDER BY ID;

	SELECT @IDTipoEntrada = ID
	FROM venta.TipoEntrada
	WHERE Nombre = @TipoEntradaVenta;

	SELECT @IDTipoEntradaParque = ID, @PrecioEntrada = Precio
	FROM venta.TipoEntradaParque
	WHERE ID_AreaProtegida = @IDAreaVenta
	  AND ID_TipoEntrada = @IDTipoEntrada;

	SET @TotalVenta = @PrecioEntrada * @CantidadVenta;

	SELECT @IDComprobante = ID
	FROM venta.Comprobante
	WHERE ID_PuntoDeVenta = @IDPuntoVenta
	  AND FechaHora = @FechaVenta
	  AND Total = @TotalVenta;

	IF @IDComprobante IS NULL
	BEGIN
		INSERT INTO venta.Comprobante(ID_PuntoDeVenta, COD_ISO_Divisa, MedioDePago, FechaHora, Total)
		VALUES (@IDPuntoVenta, 'ARS', @MedioPagoVenta, @FechaVenta, @TotalVenta);

		SET @IDComprobante = SCOPE_IDENTITY();
	END;

	WHILE (SELECT COUNT(*) FROM venta.Entrada WHERE ID_Comprobante = @IDComprobante) < @CantidadVenta
	BEGIN
		INSERT INTO venta.Entrada(ID_TipoEntradaParque, ID_Comprobante, FechaHora, PrecioCobrado)
		VALUES (@IDTipoEntradaParque, @IDComprobante, @FechaVenta, @PrecioEntrada);
	END;

	SET @VentaActual += 1;
END;

DECLARE @ActividadCompleta INT = (SELECT ID FROM actividad.Actividad WHERE Nombre = 'Tour Mirador Seed');
DECLARE @ComprobanteActividad INT = (
	SELECT TOP 1 C.ID
	FROM venta.Comprobante C
	JOIN parque.PuntoDeVenta PV ON PV.ID = C.ID_PuntoDeVenta
	WHERE PV.ID_AreaProtegida = 910002
	ORDER BY C.FechaHora
);

IF @ActividadCompleta IS NOT NULL
BEGIN
	WHILE (SELECT COUNT(*) FROM actividad.InscripcionActividad WHERE ID_Actividad = @ActividadCompleta) < 5
	BEGIN
		INSERT INTO actividad.InscripcionActividad(ID_Actividad, ID_Comprobante, FechaHora, PrecioCobrado)
		VALUES (@ActividadCompleta, @ComprobanteActividad, '2025-02-15T12:00:00', 2500);
	END;

	UPDATE actividad.Actividad
	SET CupoLibre = 0
	WHERE ID = @ActividadCompleta;
END;

INSERT INTO actividad.InscripcionActividad(ID_Actividad, ID_Comprobante, FechaHora, PrecioCobrado)
SELECT A.ID, C.ID, DATEADD(HOUR, 2, C.FechaHora), A.Costo
FROM actividad.Actividad A
JOIN parque.PuntoDeVenta PV ON PV.ID_AreaProtegida = A.ID_AreaProtegida
JOIN venta.Comprobante C ON C.ID_PuntoDeVenta = PV.ID
WHERE A.Nombre LIKE '% Seed'
  AND A.Costo > 0
  AND C.ID = (
		SELECT TOP 1 C2.ID
		FROM venta.Comprobante C2
		WHERE C2.ID_PuntoDeVenta = PV.ID
		ORDER BY C2.FechaHora
  )
  AND NOT EXISTS (
		SELECT 1
		FROM actividad.InscripcionActividad IA
		WHERE IA.ID_Actividad = A.ID
  );

PRINT('Seed: concesiones, facturas y pagos');

DECLARE @ConcesionesSeed TABLE (
	ID_AreaProtegida BIGINT,
	CUIT BIGINT,
	Empresa VARCHAR(150),
	ActividadFiscal VARCHAR(100),
	TipoConcesion VARCHAR(100),
	FechaInicio DATE,
	FechaFin DATE,
	Canon DECIMAL(20,2),
	Pagada BIT
);

INSERT INTO @ConcesionesSeed(ID_AreaProtegida, CUIT, Empresa, ActividadFiscal, TipoConcesion, FechaInicio, FechaFin, Canon, Pagada)
VALUES
	(910001, 30910000001, 'Empresa Seed Selva SRL', 'Gastronomia Seed', 'Restaurante Seed', '2025-01-01', '2027-12-31', 180000, 1),
	(910002, 30910000002, 'Empresa Seed Lagos SA', 'Turismo Seed', 'Excursiones Seed', '2025-02-01', '2027-12-31', 220000, 1),
	(910003, 30910000003, 'Empresa Seed Hielo SRL', 'Gastronomia Seed', 'Cafeteria Seed', '2024-01-01', '2025-12-31', 160000, 0),
	(910004, 30910000004, 'Empresa Seed Austral SA', 'Transporte Seed', 'Traslados Seed', '2025-03-01', '2028-02-28', 240000, 1),
	(910005, 30910000005, 'Empresa Seed Esteros SRL', 'Turismo Seed', 'Navegacion Seed', '2024-06-01', '2026-05-31', 150000, 0),
	(910006, 30910000006, 'Empresa Seed Bosque SA', 'Gastronomia Seed', 'Kiosco Seed', '2025-01-01', '2027-01-31', 90000, 1),
	(910007, 30910000007, 'Empresa Seed Alerce SRL', 'Turismo Seed', 'Alquiler Equipos Seed', '2025-04-01', '2027-03-31', 130000, 1),
	(910008, 30910000008, 'Empresa Seed Yungas SA', 'Gastronomia Seed', 'Parador Seed', '2023-01-01', '2024-12-31', 100000, 0),
	(910009, 30910000009, 'Empresa Seed Chaco SRL', 'Servicios Seed', 'Tienda Regional Seed', '2025-05-01', '2026-12-31', 110000, 1),
	(910010, 30910000010, 'Empresa Seed Sierras SA', 'Turismo Seed', 'Visitas Guiadas Seed', '2024-02-01', '2026-01-31', 125000, 0);

INSERT INTO concesion.Empresa(CUIT, Nombre)
SELECT S.CUIT, S.Empresa
FROM @ConcesionesSeed S
WHERE NOT EXISTS (SELECT 1 FROM concesion.Empresa E WHERE E.CUIT = S.CUIT);

INSERT INTO concesion.ActividadFiscal(Nombre)
SELECT DISTINCT S.ActividadFiscal
FROM @ConcesionesSeed S
WHERE NOT EXISTS (SELECT 1 FROM concesion.ActividadFiscal AF WHERE AF.Nombre = S.ActividadFiscal);

INSERT INTO concesion.ActividadFiscalInscriptaEmpresa(CUIT_Empresa, ID_ActividadFiscal, Principal)
SELECT S.CUIT, AF.ID, 1
FROM @ConcesionesSeed S
JOIN concesion.ActividadFiscal AF ON AF.Nombre = S.ActividadFiscal
WHERE NOT EXISTS (
	SELECT 1
	FROM concesion.ActividadFiscalInscriptaEmpresa AFE
	WHERE AFE.CUIT_Empresa = S.CUIT
	  AND AFE.ID_ActividadFiscal = AF.ID
);

INSERT INTO concesion.TipoConcesion(ID_ActividadFiscal, Nombre)
SELECT DISTINCT AF.ID, S.TipoConcesion
FROM @ConcesionesSeed S
JOIN concesion.ActividadFiscal AF ON AF.Nombre = S.ActividadFiscal
WHERE NOT EXISTS (
	SELECT 1
	FROM concesion.TipoConcesion TC
	WHERE TC.ID_ActividadFiscal = AF.ID
	  AND TC.Nombre = S.TipoConcesion
);

INSERT INTO concesion.Concesion(ID_AreaProtegida, CUIT_Empresa, ID_TipoConcesion, FechaInicio, FechaFin, Canon)
SELECT S.ID_AreaProtegida, S.CUIT, TC.ID, S.FechaInicio, S.FechaFin, S.Canon
FROM @ConcesionesSeed S
JOIN concesion.ActividadFiscal AF ON AF.Nombre = S.ActividadFiscal
JOIN concesion.TipoConcesion TC ON TC.ID_ActividadFiscal = AF.ID AND TC.Nombre = S.TipoConcesion
WHERE NOT EXISTS (
	SELECT 1
	FROM concesion.Concesion C
	WHERE C.ID_AreaProtegida = S.ID_AreaProtegida
	  AND C.CUIT_Empresa = S.CUIT
	  AND C.FechaInicio = S.FechaInicio
);

INSERT INTO concesion.FacturaConcesion(ID_Concesion, FechaEmision, FechaVencimiento, MontoEsperado)
SELECT C.ID, DATEFROMPARTS(2026, 1, 5), DATEFROMPARTS(2026, 1, 20), C.Canon
FROM concesion.Concesion C
JOIN @ConcesionesSeed S ON S.ID_AreaProtegida = C.ID_AreaProtegida AND S.CUIT = C.CUIT_Empresa
WHERE NOT EXISTS (
	SELECT 1
	FROM concesion.FacturaConcesion F
	WHERE F.ID_Concesion = C.ID
	  AND F.FechaEmision = DATEFROMPARTS(2026, 1, 5)
);

INSERT INTO concesion.FacturaConcesion(ID_Concesion, FechaEmision, FechaVencimiento, MontoEsperado)
SELECT C.ID, DATEFROMPARTS(2026, 2, 5), DATEFROMPARTS(2026, 2, 20), C.Canon
FROM concesion.Concesion C
JOIN @ConcesionesSeed S ON S.ID_AreaProtegida = C.ID_AreaProtegida AND S.CUIT = C.CUIT_Empresa
WHERE NOT EXISTS (
	SELECT 1
	FROM concesion.FacturaConcesion F
	WHERE F.ID_Concesion = C.ID
	  AND F.FechaEmision = DATEFROMPARTS(2026, 2, 5)
);

INSERT INTO concesion.PagoConcesion(ID_Factura, FechaPago, MontoPagado)
SELECT F.ID, DATEADD(DAY, 5, F.FechaEmision), F.MontoEsperado
FROM concesion.FacturaConcesion F
JOIN concesion.Concesion C ON C.ID = F.ID_Concesion
JOIN @ConcesionesSeed S ON S.ID_AreaProtegida = C.ID_AreaProtegida AND S.CUIT = C.CUIT_Empresa
WHERE S.Pagada = 1
  AND NOT EXISTS (SELECT 1 FROM concesion.PagoConcesion P WHERE P.ID_Factura = F.ID);

PRINT('Seed finalizado. Resumen de criterios de aceptacion:');

SELECT
	(SELECT COUNT(*) FROM parque.AreaProtegida WHERE Nombre LIKE '% Seed%') AS ParquesSeed,
	(SELECT COUNT(*) FROM actividad.Actividad WHERE Nombre LIKE '% Seed') AS ActividadesSeed,
	(SELECT COUNT(*) FROM personal.GuiaAutorizado WHERE Nombre LIKE 'GuiaSeed%') AS GuiasSeed,
	(SELECT COUNT(*) FROM personal.Guardaparques WHERE Nombre LIKE 'GuardaparqueSeed%') AS GuardaparquesSeed,
	(SELECT COUNT(*) FROM concesion.Concesion C JOIN concesion.Empresa E ON E.CUIT = C.CUIT_Empresa WHERE E.Nombre LIKE 'Empresa Seed%') AS ConcesionesSeed,
	(SELECT COUNT(*) FROM venta.Entrada E JOIN venta.Comprobante C ON C.ID = E.ID_Comprobante JOIN parque.PuntoDeVenta PV ON PV.ID = C.ID_PuntoDeVenta WHERE PV.Descripcion = 'Boleteria Seed') AS EntradasSeed;
GO
