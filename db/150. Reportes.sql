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
* Script: 150. Reportes
* Descripción: Stored procedures de reportes solicitados para visitas, ingresos, deudores, matriz y concesiones por parque.
*/

USE com2900;
GO

IF SCHEMA_ID('reporte') IS NULL
	EXEC('CREATE SCHEMA reporte');
GO

CREATE OR ALTER PROCEDURE reporte.VisitasPorPeriodoParque
	@FechaDesde DATE = NULL,
	@FechaHasta DATE = NULL,
	@Agrupacion VARCHAR(10) = 'MES'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';

	IF @Agrupacion NOT IN ('SEMANA', 'MES', 'ANIO')
		SET @Errores += N'- La agrupacion debe ser SEMANA, MES o ANIO.' + CHAR(13) + CHAR(10);

	IF @FechaDesde IS NOT NULL AND @FechaHasta IS NOT NULL AND @FechaHasta < @FechaDesde
		SET @Errores += N'- La fecha hasta debe ser posterior o igual a la fecha desde.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	SELECT
		AP.ID AS ID_AreaProtegida,
		AP.Nombre AS Parque,
		CASE @Agrupacion
			WHEN 'SEMANA' THEN DATEPART(YEAR, E.FechaHora)
			WHEN 'MES' THEN DATEPART(YEAR, E.FechaHora)
			ELSE DATEPART(YEAR, E.FechaHora)
		END AS Anio,
		CASE WHEN @Agrupacion = 'SEMANA' THEN DATEPART(ISO_WEEK, E.FechaHora) END AS Semana,
		CASE WHEN @Agrupacion = 'MES' THEN DATEPART(MONTH, E.FechaHora) END AS Mes,
		COUNT(*) AS CantidadVisitantes
	FROM venta.Entrada E
	JOIN venta.TipoEntradaParque TEP ON TEP.ID = E.ID_TipoEntradaParque
	JOIN parque.AreaProtegida AP ON AP.ID = TEP.ID_AreaProtegida
	WHERE (@FechaDesde IS NULL OR CONVERT(DATE, E.FechaHora) >= @FechaDesde)
	  AND (@FechaHasta IS NULL OR CONVERT(DATE, E.FechaHora) <= @FechaHasta)
	GROUP BY
		AP.ID,
		AP.Nombre,
		DATEPART(YEAR, E.FechaHora),
		CASE WHEN @Agrupacion = 'SEMANA' THEN DATEPART(ISO_WEEK, E.FechaHora) END,
		CASE WHEN @Agrupacion = 'MES' THEN DATEPART(MONTH, E.FechaHora) END
	ORDER BY AP.Nombre, Anio, Mes, Semana;
END;
GO

CREATE OR ALTER PROCEDURE reporte.IngresosPorPeriodoParque
	@FechaDesde DATE = NULL,
	@FechaHasta DATE = NULL,
	@Agrupacion VARCHAR(10) = 'MES'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Errores NVARCHAR(MAX) = N'';

	IF @Agrupacion NOT IN ('SEMANA', 'MES', 'ANIO')
		SET @Errores += N'- La agrupacion debe ser SEMANA, MES o ANIO.' + CHAR(13) + CHAR(10);

	IF @FechaDesde IS NOT NULL AND @FechaHasta IS NOT NULL AND @FechaHasta < @FechaDesde
		SET @Errores += N'- La fecha hasta debe ser posterior o igual a la fecha desde.' + CHAR(13) + CHAR(10);

	IF LEN(@Errores) > 0
		THROW 50001, @Errores, 1;

	;WITH Ingresos AS (
		SELECT
			AP.ID AS ID_AreaProtegida,
			AP.Nombre AS Parque,
			E.FechaHora AS Fecha,
			1 AS CantidadEntradas,
			E.PrecioCobrado AS IngresoEntradas,
			CAST(0 AS INT) AS CantidadActividades,
			CAST(0 AS DECIMAL(20,2)) AS IngresoActividades,
			CAST(0 AS DECIMAL(20,2)) AS IngresoConcesiones
		FROM venta.Entrada E
		JOIN venta.TipoEntradaParque TEP ON TEP.ID = E.ID_TipoEntradaParque
		JOIN parque.AreaProtegida AP ON AP.ID = TEP.ID_AreaProtegida
		WHERE (@FechaDesde IS NULL OR CONVERT(DATE, E.FechaHora) >= @FechaDesde)
		  AND (@FechaHasta IS NULL OR CONVERT(DATE, E.FechaHora) <= @FechaHasta)

		UNION ALL

		SELECT
			AP.ID,
			AP.Nombre,
			IA.FechaHora,
			0,
			0,
			1,
			ISNULL(IA.PrecioCobrado, 0),
			0
		FROM actividad.InscripcionActividad IA
		JOIN actividad.Actividad A ON A.ID = IA.ID_Actividad
		JOIN parque.AreaProtegida AP ON AP.ID = A.ID_AreaProtegida
		WHERE IA.FechaHora IS NOT NULL
		  AND (@FechaDesde IS NULL OR CONVERT(DATE, IA.FechaHora) >= @FechaDesde)
		  AND (@FechaHasta IS NULL OR CONVERT(DATE, IA.FechaHora) <= @FechaHasta)

		UNION ALL

		SELECT
			AP.ID,
			AP.Nombre,
			CAST(P.FechaPago AS DATETIME),
			0,
			0,
			0,
			0,
			P.MontoPagado
		FROM concesion.PagoConcesion P
		JOIN concesion.FacturaConcesion F ON F.ID = P.ID_Factura
		JOIN concesion.Concesion C ON C.ID = F.ID_Concesion
		JOIN parque.AreaProtegida AP ON AP.ID = C.ID_AreaProtegida
		WHERE (@FechaDesde IS NULL OR P.FechaPago >= @FechaDesde)
		  AND (@FechaHasta IS NULL OR P.FechaPago <= @FechaHasta)
	)
	SELECT
		ID_AreaProtegida,
		Parque,
		DATEPART(YEAR, Fecha) AS Anio,
		CASE WHEN @Agrupacion = 'SEMANA' THEN DATEPART(ISO_WEEK, Fecha) END AS Semana,
		CASE WHEN @Agrupacion = 'MES' THEN DATEPART(MONTH, Fecha) END AS Mes,
		SUM(CantidadEntradas) AS CantidadEntradas,
		SUM(IngresoEntradas) AS IngresoEntradas,
		SUM(CantidadActividades) AS CantidadActividades,
		SUM(IngresoActividades) AS IngresoActividades,
		SUM(IngresoConcesiones) AS IngresoConcesiones,
		SUM(IngresoEntradas + IngresoActividades + IngresoConcesiones) AS IngresoTotal
	FROM Ingresos
	GROUP BY
		ID_AreaProtegida,
		Parque,
		DATEPART(YEAR, Fecha),
		CASE WHEN @Agrupacion = 'SEMANA' THEN DATEPART(ISO_WEEK, Fecha) END,
		CASE WHEN @Agrupacion = 'MES' THEN DATEPART(MONTH, Fecha) END
	ORDER BY Parque, Anio, Mes, Semana;
END;
GO

CREATE OR ALTER PROCEDURE reporte.ConcesionesDeudoras
	@FechaCorte DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SET @FechaCorte = ISNULL(@FechaCorte, CONVERT(DATE, GETDATE()));

	SELECT
		C.ID AS ID_Concesion,
		AP.Nombre AS Parque,
		E.CUIT,
		E.Nombre AS Empresa,
		TC.Nombre AS ServicioPrestado,
		COUNT(F.ID) AS FacturasVencidas,
		SUM(F.MontoEsperado - ISNULL(P.Pagado, 0)) AS MontoAdeudado,
		MIN(F.FechaVencimiento) AS VencimientoMasAntiguo,
		DATEDIFF(MONTH, MIN(F.FechaVencimiento), @FechaCorte) AS MesesAtraso
	FROM concesion.FacturaConcesion F
	JOIN concesion.Concesion C ON C.ID = F.ID_Concesion
	JOIN concesion.Empresa E ON E.CUIT = C.CUIT_Empresa
	JOIN concesion.TipoConcesion TC ON TC.ID = C.ID_TipoConcesion
	JOIN parque.AreaProtegida AP ON AP.ID = C.ID_AreaProtegida
	OUTER APPLY (
		SELECT SUM(P.MontoPagado) AS Pagado
		FROM concesion.PagoConcesion P
		WHERE P.ID_Factura = F.ID
	) P
	WHERE F.FechaVencimiento < @FechaCorte
	  AND F.MontoEsperado > ISNULL(P.Pagado, 0)
	GROUP BY C.ID, AP.Nombre, E.CUIT, E.Nombre, TC.Nombre
	ORDER BY MontoAdeudado DESC, VencimientoMasAntiguo;
END;
GO

CREATE OR ALTER PROCEDURE reporte.ConcesionesDeudorasXml
	@FechaCorte DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SET @FechaCorte = ISNULL(@FechaCorte, CONVERT(DATE, GETDATE()));

	SELECT
		C.ID AS [@idConcesion],
		AP.Nombre AS [Parque],
		E.CUIT AS [Empresa/@cuit],
		E.Nombre AS [Empresa],
		TC.Nombre AS [ServicioPrestado],
		COUNT(F.ID) AS [FacturasVencidas],
		SUM(F.MontoEsperado - ISNULL(P.Pagado, 0)) AS [MontoAdeudado],
		MIN(F.FechaVencimiento) AS [VencimientoMasAntiguo],
		DATEDIFF(MONTH, MIN(F.FechaVencimiento), @FechaCorte) AS [MesesAtraso]
	FROM concesion.FacturaConcesion F
	JOIN concesion.Concesion C ON C.ID = F.ID_Concesion
	JOIN concesion.Empresa E ON E.CUIT = C.CUIT_Empresa
	JOIN concesion.TipoConcesion TC ON TC.ID = C.ID_TipoConcesion
	JOIN parque.AreaProtegida AP ON AP.ID = C.ID_AreaProtegida
	OUTER APPLY (
		SELECT SUM(P.MontoPagado) AS Pagado
		FROM concesion.PagoConcesion P
		WHERE P.ID_Factura = F.ID
	) P
	WHERE F.FechaVencimiento < @FechaCorte
	  AND F.MontoEsperado > ISNULL(P.Pagado, 0)
	GROUP BY C.ID, AP.Nombre, E.CUIT, E.Nombre, TC.Nombre
	FOR XML PATH('ConcesionDeudora'), ROOT('ConcesionesDeudoras'), TYPE;
END;
GO

CREATE OR ALTER PROCEDURE reporte.MatrizVisitasMensual
	@Anio INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @Anio IS NULL OR @Anio < 2000
		THROW 50001, 'El año debe ser mayor o igual a 2000.', 1;

	SELECT
		AP.Nombre AS Parque,
		SUM(CASE WHEN MONTH(E.FechaHora) = 1 THEN 1 ELSE 0 END) AS Enero,
		SUM(CASE WHEN MONTH(E.FechaHora) = 2 THEN 1 ELSE 0 END) AS Febrero,
		SUM(CASE WHEN MONTH(E.FechaHora) = 3 THEN 1 ELSE 0 END) AS Marzo,
		SUM(CASE WHEN MONTH(E.FechaHora) = 4 THEN 1 ELSE 0 END) AS Abril,
		SUM(CASE WHEN MONTH(E.FechaHora) = 5 THEN 1 ELSE 0 END) AS Mayo,
		SUM(CASE WHEN MONTH(E.FechaHora) = 6 THEN 1 ELSE 0 END) AS Junio,
		SUM(CASE WHEN MONTH(E.FechaHora) = 7 THEN 1 ELSE 0 END) AS Julio,
		SUM(CASE WHEN MONTH(E.FechaHora) = 8 THEN 1 ELSE 0 END) AS Agosto,
		SUM(CASE WHEN MONTH(E.FechaHora) = 9 THEN 1 ELSE 0 END) AS Septiembre,
		SUM(CASE WHEN MONTH(E.FechaHora) = 10 THEN 1 ELSE 0 END) AS Octubre,
		SUM(CASE WHEN MONTH(E.FechaHora) = 11 THEN 1 ELSE 0 END) AS Noviembre,
		SUM(CASE WHEN MONTH(E.FechaHora) = 12 THEN 1 ELSE 0 END) AS Diciembre,
		COUNT(*) AS TotalAnual
	FROM venta.Entrada E
	JOIN venta.TipoEntradaParque TEP ON TEP.ID = E.ID_TipoEntradaParque
	JOIN parque.AreaProtegida AP ON AP.ID = TEP.ID_AreaProtegida
	WHERE YEAR(E.FechaHora) = @Anio
	GROUP BY AP.Nombre
	ORDER BY AP.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE reporte.ParquesConConcesionesXml
	@ID_AreaProtegida BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		AP.ID AS [@id],
		AP.Nombre AS [Nombre],
		AP.TipoArea AS [TipoArea],
		AP.Superficie AS [Superficie],
		(
			SELECT
				C.ID AS [@id],
				C.FechaInicio AS [FechaInicio],
				C.FechaFin AS [FechaFin],
				C.Canon AS [Canon],
				E.CUIT AS [Titular/@cuit],
				E.Nombre AS [Titular],
				TC.Nombre AS [ServicioPrestado]
			FROM concesion.Concesion C
			JOIN concesion.Empresa E ON E.CUIT = C.CUIT_Empresa
			JOIN concesion.TipoConcesion TC ON TC.ID = C.ID_TipoConcesion
			WHERE C.ID_AreaProtegida = AP.ID
			ORDER BY C.FechaInicio
			FOR XML PATH('Concesion'), TYPE
		) AS [Concesiones]
	FROM parque.AreaProtegida AP
	WHERE @ID_AreaProtegida IS NULL OR AP.ID = @ID_AreaProtegida
	ORDER BY AP.Nombre
	FOR XML PATH('Parque'), ROOT('Parques'), TYPE;
END;
GO

CREATE OR ALTER PROCEDURE reporte.ActividadesMasDemandadas
	@FechaDesde DATE = NULL,
	@FechaHasta DATE = NULL,
	@Top INT = 10
AS
BEGIN
	SET NOCOUNT ON;

	IF @Top IS NULL OR @Top <= 0
		THROW 50001, 'El top debe ser mayor que cero.', 1;

	SELECT TOP (@Top)
		AP.Nombre AS Parque,
		A.Nombre AS Actividad,
		TA.Nombre AS TipoActividad,
		COUNT(IA.ID) AS Contrataciones,
		SUM(ISNULL(IA.PrecioCobrado, 0)) AS Ingresos
	FROM actividad.InscripcionActividad IA
	JOIN actividad.Actividad A ON A.ID = IA.ID_Actividad
	JOIN actividad.TipoActividad TA ON TA.ID = A.ID_TipoActividad
	JOIN parque.AreaProtegida AP ON AP.ID = A.ID_AreaProtegida
	WHERE (@FechaDesde IS NULL OR CONVERT(DATE, IA.FechaHora) >= @FechaDesde)
	  AND (@FechaHasta IS NULL OR CONVERT(DATE, IA.FechaHora) <= @FechaHasta)
	GROUP BY AP.Nombre, A.Nombre, TA.Nombre
	ORDER BY Contrataciones DESC, Ingresos DESC;
END;
GO
