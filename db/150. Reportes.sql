/*
* Universidad: Universidad Nacional de La Matanza
* Materia: Base de Datos Aplicadas
* Comisión: 2900 (Martes noche)
* Grupo: 12
* Integrantes:
*  - Costilla, Lucas Leonel
*  - Mancilla Muñoz, Emmanuel Américo
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

CREATE OR ALTER PROCEDURE reporte.ConcesionesDeudorasDetalle
	@FechaCorte DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SET @FechaCorte = ISNULL(@FechaCorte, CONVERT(DATE, GETDATE()));

	SELECT
		C.ID       AS ID_Concesion,
		AP.Nombre  AS Parque,
		E.CUIT,
		E.Nombre   AS Empresa,
		TC.Nombre  AS ServicioPrestado,
		F.ID       AS ID_Factura,
		F.FechaVencimiento,
		F.MontoEsperado,
		ISNULL(P.Pagado, 0) AS MontoPagado,
		F.MontoEsperado - ISNULL(P.Pagado, 0) AS Pendiente
	FROM concesion.FacturaConcesion F
	JOIN concesion.Concesion C ON C.ID = F.ID_Concesion
	JOIN concesion.Empresa E ON E.CUIT = C.CUIT_Empresa
	JOIN concesion.TipoConcesion TC ON TC.ID = C.ID_TipoConcesion
	JOIN parque.AreaProtegida AP ON AP.ID = C.ID_AreaProtegida
	OUTER APPLY (
		SELECT SUM(Pg.MontoPagado) AS Pagado
		FROM concesion.PagoConcesion Pg
		WHERE Pg.ID_Factura = F.ID
	) P
	WHERE F.FechaVencimiento < @FechaCorte
	  AND F.MontoEsperado > ISNULL(P.Pagado, 0)
	ORDER BY C.ID, F.FechaVencimiento;
END;
GO

CREATE OR ALTER PROCEDURE reporte.ConcesionesDeudorasXml
	@FechaCorte DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SET @FechaCorte = ISNULL(@FechaCorte, CONVERT(DATE, GETDATE()));

	WITH FacturasDetalle AS (
		SELECT
			F.ID              AS ID_Factura,
			F.ID_Concesion,
			F.FechaVencimiento,
			F.MontoEsperado,
			ISNULL(P.Pagado, 0) AS MontoPagado,
			F.MontoEsperado - ISNULL(P.Pagado, 0) AS Pendiente
		FROM concesion.FacturaConcesion F
		OUTER APPLY (
			SELECT SUM(Pg.MontoPagado) AS Pagado
			FROM concesion.PagoConcesion Pg
			WHERE Pg.ID_Factura = F.ID
		) P
		WHERE F.FechaVencimiento < @FechaCorte
		  AND F.MontoEsperado > ISNULL(P.Pagado, 0)
	),
	ConcesionesResumen AS (
		SELECT
			C.ID       AS ID_Concesion,
			AP.Nombre  AS Parque,
			E.CUIT,
			E.Nombre   AS Empresa,
			TC.Nombre  AS ServicioPrestado
		FROM FacturasDetalle FD
		JOIN concesion.Concesion C ON C.ID = FD.ID_Concesion
		JOIN concesion.Empresa E ON E.CUIT = C.CUIT_Empresa
		JOIN concesion.TipoConcesion TC ON TC.ID = C.ID_TipoConcesion
		JOIN parque.AreaProtegida AP ON AP.ID = C.ID_AreaProtegida
		GROUP BY C.ID, AP.Nombre, E.CUIT, E.Nombre, TC.Nombre
	)
	SELECT
		CR.ID_Concesion AS [@idConcesion],
		CR.Parque,
		CR.Empresa AS [Empresa/@nombre],
		CR.CUIT AS [Empresa/@cuit],
		CR.ServicioPrestado,
		(
			SELECT COUNT(*) FROM FacturasDetalle FD WHERE FD.ID_Concesion = CR.ID_Concesion
		) AS [FacturasVencidas],
		(
			SELECT SUM(FD.Pendiente) FROM FacturasDetalle FD WHERE FD.ID_Concesion = CR.ID_Concesion
		) AS [MontoAdeudado],
		(
			SELECT MIN(FD.FechaVencimiento) FROM FacturasDetalle FD WHERE FD.ID_Concesion = CR.ID_Concesion
		) AS [VencimientoMasAntiguo],
		(
			SELECT DATEDIFF(MONTH, MIN(FD.FechaVencimiento), @FechaCorte)
			FROM FacturasDetalle FD WHERE FD.ID_Concesion = CR.ID_Concesion
		) AS [MesesAtraso],
		(
			SELECT
				FD.ID_Factura        AS [@id],
				FD.FechaVencimiento,
				FD.MontoEsperado,
				FD.MontoPagado,
				FD.Pendiente
			FROM FacturasDetalle FD
			WHERE FD.ID_Concesion = CR.ID_Concesion
			ORDER BY FD.FechaVencimiento
			FOR XML PATH('Factura'), TYPE
		) AS [DetalleFacturas]
	FROM ConcesionesResumen CR
	ORDER BY CR.ID_Concesion
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

	WITH Visitas AS (
		SELECT
			AP.Nombre AS Parque,
			MONTH(E.FechaHora) AS Mes
		FROM venta.Entrada E
		JOIN venta.TipoEntradaParque TEP ON TEP.ID = E.ID_TipoEntradaParque
		JOIN parque.AreaProtegida AP ON AP.ID = TEP.ID_AreaProtegida
		WHERE YEAR(E.FechaHora) = @Anio
	),
	PivotData AS (
		SELECT
			Parque,
			[1] AS Enero,
			[2] AS Febrero,
			[3] AS Marzo,
			[4] AS Abril,
			[5] AS Mayo,
			[6] AS Junio,
			[7] AS Julio,
			[8] AS Agosto,
			[9] AS Septiembre,
			[10] AS Octubre,
			[11] AS Noviembre,
			[12] AS Diciembre
		FROM Visitas
		PIVOT (COUNT(Mes) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) P
	)
	SELECT
		Parque,
		ISNULL(Enero, 0) AS Enero,
		ISNULL(Febrero, 0) AS Febrero,
		ISNULL(Marzo, 0) AS Marzo,
		ISNULL(Abril, 0) AS Abril,
		ISNULL(Mayo, 0) AS Mayo,
		ISNULL(Junio, 0) AS Junio,
		ISNULL(Julio, 0) AS Julio,
		ISNULL(Agosto, 0) AS Agosto,
		ISNULL(Septiembre, 0) AS Septiembre,
		ISNULL(Octubre, 0) AS Octubre,
		ISNULL(Noviembre, 0) AS Noviembre,
		ISNULL(Diciembre, 0) AS Diciembre,
		ISNULL(Enero, 0) + ISNULL(Febrero, 0) + ISNULL(Marzo, 0) + ISNULL(Abril, 0) + ISNULL(Mayo, 0) + ISNULL(Junio, 0) + ISNULL(Julio, 0) + ISNULL(Agosto, 0) + ISNULL(Septiembre, 0) + ISNULL(Octubre, 0) + ISNULL(Noviembre, 0) + ISNULL(Diciembre, 0) AS TotalAnual
	FROM PivotData
	ORDER BY Parque;
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