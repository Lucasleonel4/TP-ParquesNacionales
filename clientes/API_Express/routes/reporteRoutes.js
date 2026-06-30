const express = require('express');
const router  = express.Router();
const {ejecutarSP} = require('../bd');


router.get('/', (req, res)=>{
    res.send('Apartado de Reportes');
})


// ============================================================================
// Visitas por período y parque
// ============================================================================

router.get('/visitas-parque', async (req, res, next) => {
  const params = {};
  if (req.query.fechaDesde) params.FechaDesde = req.query.fechaDesde;
  if (req.query.fechaHasta) params.FechaHasta = req.query.fechaHasta;
  params.Agrupacion = req.query.agrupacion || 'MES';

  try {
    const resultado = (await ejecutarSP('[reporte].[VisitasPorPeriodoParque]', params)).recordset;
    if (!resultado || resultado.length === 0) {
      const error = new Error('No hay visitas en el período indicado.');
      error.status = 404;
      return next(error);
    }
    res.status(200).json(resultado);
  } catch (err) {
    next(err);
  }
});


// ============================================================================
// Ingresos por período y parque
// ============================================================================

router.get('/ingresos-parque', async (req, res, next) => {
  const params = {};
  if (req.query.fechaDesde) params.FechaDesde = req.query.fechaDesde;
  if (req.query.fechaHasta) params.FechaHasta = req.query.fechaHasta;
  params.Agrupacion = req.query.agrupacion || 'MES';

  try {
    const resultado = (await ejecutarSP('[reporte].[IngresosPorPeriodoParque]', params)).recordset;
    if (!resultado || resultado.length === 0) {
      const error = new Error('No hay ingresos en el período indicado.');
      error.status = 404;
      return next(error);
    }
    res.status(200).json(resultado);
  } catch (err) {
    next(err);
  }
});


// ============================================================================
// Concesiones deudoras (resumen)
// ============================================================================

router.get('/deudores', async (req, res, next) => {
  const params = {};
  if (req.query.fechaCorte) params.FechaCorte = req.query.fechaCorte;

  try {
    const resultado = (await ejecutarSP('[reporte].[ConcesionesDeudoras]', params)).recordset;
    if (!resultado || resultado.length === 0) {
      const error = new Error('No hay concesiones deudoras con la fecha de corte indicada.');
      error.status = 404;
      return next(error);
    }
    res.status(200).json(resultado);
  } catch (err) {
    next(err);
  }
});


// ============================================================================
// Concesiones deudoras (detalle por factura)
// ============================================================================

router.get('/deudores-detalle', async (req, res, next) => {
  const params = {};
  if (req.query.fechaCorte) params.FechaCorte = req.query.fechaCorte;

  try {
    const resultado = (await ejecutarSP('[reporte].[ConcesionesDeudorasDetalle]', params)).recordset;
    if (!resultado || resultado.length === 0) {
      const error = new Error('No hay facturas deudoras con la fecha de corte indicada.');
      error.status = 404;
      return next(error);
    }
    res.status(200).json(resultado);
  } catch (err) {
    next(err);
  }
});


// ============================================================================
// Concesiones deudoras XML
// ============================================================================

router.get('/deudores-xml', async (req, res, next) => {
  const params = {};
  if (req.query.fechaCorte) params.FechaCorte = req.query.fechaCorte;

  try {
    const resultado = await ejecutarSP('[reporte].[ConcesionesDeudorasXml]', params);
    const xmlContent = resultado.recordset && resultado.recordset[0] ? resultado.recordset[0][''] : null;
    if (!xmlContent) {
      const error = new Error('No hay concesiones deudoras con la fecha de corte indicada.');
      error.status = 404;
      return next(error);
    }
    res.type('text/xml').status(200).send(xmlContent);
  } catch (err) {
    next(err);
  }
});


// ============================================================================
// Matriz de visitas mensual
// ============================================================================

router.get('/matriz-visitas', async (req, res, next) => {
  const anio = parseInt(req.query.anio);
  if (isNaN(anio) || anio < 2000) {
    const error = new Error('Se debe informar un año válido mayor o igual a 2000.');
    error.status = 400;
    return next(error);
  }

  try {
    const resultado = (await ejecutarSP('[reporte].[MatrizVisitasMensual]', { Anio: anio })).recordset;
    if (!resultado || resultado.length === 0) {
      const error = new Error(`No hay visitas registradas en el año ${anio}.`);
      error.status = 404;
      return next(error);
    }
    res.status(200).json(resultado);
  } catch (err) {
    next(err);
  }
});


// ============================================================================
// Parques con concesiones anidadas XML
// ============================================================================

router.get('/parques-concesiones-xml', async (req, res, next) => {
  const params = {};
  if (req.query.idAreaProtegida) params.ID_AreaProtegida = parseInt(req.query.idAreaProtegida);

  try {
    const resultado = await ejecutarSP('[reporte].[ParquesConConcesionesXml]', params);
    const xmlContent = resultado.recordset && resultado.recordset[0] ? resultado.recordset[0][''] : null;
    if (!xmlContent) {
      const error = new Error('No se pudo generar el XML de parques con concesiones.');
      error.status = 404;
      return next(error);
    }
    res.type('text/xml').status(200).send(xmlContent);
  } catch (err) {
    next(err);
  }
});


// ============================================================================
// Actividades más demandadas
// ============================================================================

router.get('/actividades-demandadas', async (req, res, next) => {
  const params = {};
  if (req.query.fechaDesde) params.FechaDesde = req.query.fechaDesde;
  if (req.query.fechaHasta) params.FechaHasta = req.query.fechaHasta;
  params.Top = req.query.top ? parseInt(req.query.top) : 10;

  try {
    const resultado = (await ejecutarSP('[reporte].[ActividadesMasDemandadas]', params)).recordset;
    if (!resultado || resultado.length === 0) {
      const error = new Error('No hay actividades registradas en el período indicado.');
      error.status = 404;
      return next(error);
    }
    res.status(200).json(resultado);
  } catch (err) {
    next(err);
  }
});


module.exports = router
