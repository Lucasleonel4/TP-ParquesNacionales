const express = require('express');
const router  = express.Router();
const {ejecutarSP, ejecutarQuery} = require('../bd');


router.get('/', (req, res)=>{
    res.send('Apartado de Areas Concesiones');
})


// ============================================================================
// ABL ActividadFiscal
// ============================================================================

router.get('/actividadfiscal', async (req, res, next) => {
  const registros = (await ejecutarSP('[concesion].[ActividadFiscalConsulta]', {})).recordset;

  if (!registros || registros.length === 0) {
    const error = new Error('No se encuentran actividades fiscales registradas.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registros);
});

router.get('/actividadfiscal/:id', async (req, res, next) => {
  const id = parseInt(req.params.id);

  if (typeof id !== "number" || !Number.isInteger(id)) {
    const error = new Error('No se ingresó un ID válido.');
    error.status = 400;
    return next(error);
  }

  const registro = (await ejecutarSP('[concesion].[ActividadFiscalConsulta]', { ID: id })).recordset;

  if (!registro || registro.length === 0) {
    const error = new Error('No se encuentra la actividad fiscal.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registro);
});

router.post('/actividadfiscal', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar Nombre.');
    error.status = 400;
    return next(error);
  }

  const nuevaActividad = req.body;
  const resultado = await ejecutarSP('[concesion].[ActividadFiscalAlta]', nuevaActividad);
  const idGenerado = resultado.recordset && resultado.recordset[0] ? resultado.recordset[0].ID : null;

  res.status(201).json({ message: 'Actividad fiscal creada.', id: idGenerado });
});

router.put('/actividadfiscal', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
    error.status = 400;
    return next(error);
  }

  const actividadModificada = req.body;
  await ejecutarSP('[concesion].[ActividadFiscalModificacion]', actividadModificada);
  res.status(200).json({ message: 'Actividad fiscal actualizada.' });
});

router.delete('/actividadfiscal', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID de la actividad fiscal a eliminar.');
    error.status = 400;
    return next(error);
  }

  const bajaDatos = req.body;
  await ejecutarSP('[concesion].[ActividadFiscalBaja]', bajaDatos);
  res.status(200).json({ message: 'Actividad fiscal eliminada.' });
});


// ============================================================================
// ABL Empresa
// ============================================================================

router.get('/empresa', async (req, res, next) => {
  const registros = (await ejecutarSP('[concesion].[EmpresaConsulta]', {})).recordset;

  if (!registros || registros.length === 0) {
    const error = new Error('No se encuentran empresas registradas.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registros);
});

router.get('/empresa/:cuit', async (req, res, next) => {
  const cuit = parseInt(req.params.cuit);

  if (typeof cuit !== "number" || !Number.isInteger(cuit)) {
    const error = new Error('No se ingresó un CUIT válido.');
    error.status = 400;
    return next(error);
  }

  const registro = (await ejecutarSP('[concesion].[EmpresaConsulta]', { CUIT: cuit })).recordset;

  if (!registro || registro.length === 0) {
    const error = new Error('No se encuentra la empresa.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registro);
});

router.post('/empresa', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar CUIT y Nombre.');
    error.status = 400;
    return next(error);
  }

  const nuevaEmpresa = req.body;
  await ejecutarSP('[concesion].[EmpresaAlta]', nuevaEmpresa);
  res.status(201).json({ message: 'Empresa creada.' });
});

router.put('/empresa', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el CUIT para actualizar.');
    error.status = 400;
    return next(error);
  }

  const empresaModificada = req.body;
  await ejecutarSP('[concesion].[EmpresaModificacion]', empresaModificada);
  res.status(200).json({ message: 'Empresa actualizada.' });
});

router.delete('/empresa', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar el CUIT de la empresa a eliminar.');
    error.status = 400;
    return next(error);
  }

  const bajaDatos = req.body;
  await ejecutarSP('[concesion].[EmpresaBaja]', bajaDatos);
  res.status(200).json({ message: 'Empresa eliminada.' });
});


// ============================================================================
// ABL TipoConcesion
// ============================================================================

router.get('/tipoconcesion', async (req, res, next) => {
  const registros = (await ejecutarSP('[concesion].[TipoConcesionConsulta]', {})).recordset;

  if (!registros || registros.length === 0) {
    const error = new Error('No se encuentran tipos de concesión registrados.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registros);
});

router.get('/tipoconcesion/:id', async (req, res, next) => {
  const id = parseInt(req.params.id);

  if (typeof id !== "number" || !Number.isInteger(id)) {
    const error = new Error('No se ingresó un ID válido.');
    error.status = 400;
    return next(error);
  }

  const registro = (await ejecutarSP('[concesion].[TipoConcesionConsulta]', { ID: id })).recordset;

  if (!registro || registro.length === 0) {
    const error = new Error('No se encuentra el tipo de concesión.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registro);
});

router.post('/tipoconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_ActividadFiscal y Nombre.');
    error.status = 400;
    return next(error);
  }

  const nuevoTipo = req.body;
  const resultado = await ejecutarSP('[concesion].[TipoConcesionAlta]', nuevoTipo);
  const idGenerado = resultado.recordset && resultado.recordset[0] ? resultado.recordset[0].ID : null;

  res.status(201).json({ message: 'Tipo de concesión creado.', id: idGenerado });
});

router.put('/tipoconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
    error.status = 400;
    return next(error);
  }

  const tipoModificado = req.body;
  await ejecutarSP('[concesion].[TipoConcesionModificacion]', tipoModificado);
  res.status(200).json({ message: 'Tipo de concesión actualizado.' });
});

router.delete('/tipoconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del tipo de concesión a eliminar.');
    error.status = 400;
    return next(error);
  }

  const bajaDatos = req.body;
  await ejecutarSP('[concesion].[TipoConcesionBaja]', bajaDatos);
  res.status(200).json({ message: 'Tipo de concesión eliminado.' });
});


// ============================================================================
// ABL ActividadFiscalInscriptaEmpresa
// ============================================================================

router.get('/actividadfiscalinscriptaempresa', async (req, res, next) => {
  const registros = (await ejecutarSP('[concesion].[ActividadFiscalInscriptaEmpresaConsulta]', {})).recordset;

  if (!registros || registros.length === 0) {
    const error = new Error('No se encuentran inscripciones de empresas en actividades fiscales.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registros);
});

router.get('/actividadfiscalinscriptaempresa/:cuit', async (req, res, next) => {
  const cuit = parseInt(req.params.cuit);

  if (typeof cuit !== "number" || !Number.isInteger(cuit)) {
    const error = new Error('No se ingresó un CUIT válido.');
    error.status = 400;
    return next(error);
  }

  const registro = (await ejecutarSP('[concesion].[ActividadFiscalInscriptaEmpresaConsulta]', { CUIT_Empresa: cuit })).recordset;

  if (!registro || registro.length === 0) {
    const error = new Error('No se encuentra la inscripción de la empresa en actividades fiscales.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registro);
});

router.post('/actividadfiscalinscriptaempresa', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar CUIT_Empresa, ID_ActividadFiscal y opcionalmente Principal.');
    error.status = 400;
    return next(error);
  }

  const nuevaInscripcion = req.body;
  await ejecutarSP('[concesion].[ActividadFiscalInscriptaEmpresaAlta]', nuevaInscripcion);
  res.status(201).json({ message: 'Inscripción creada.' });
});

router.put('/actividadfiscalinscriptaempresa', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar CUIT_Empresa e ID_ActividadFiscal para actualizar.');
    error.status = 400;
    return next(error);
  }

  const inscripcionModificada = req.body;
  await ejecutarSP('[concesion].[ActividadFiscalInscriptaEmpresaModificacion]', inscripcionModificada);
  res.status(200).json({ message: 'Inscripción actualizada.' });
});

router.delete('/actividadfiscalinscriptaempresa', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar CUIT_Empresa e ID_ActividadFiscal para eliminar.');
    error.status = 400;
    return next(error);
  }

  const bajaDatos = req.body;
  await ejecutarSP('[concesion].[ActividadFiscalInscriptaEmpresaBaja]', bajaDatos);
  res.status(200).json({ message: 'Inscripción eliminada.' });
});



// ============================================================================
// ABL Concesion
// ============================================================================

router.get('/concesion', async (req, res, next) => {
  const registros = (await ejecutarSP('[concesion].[ConcesionConsulta]', {})).recordset;

  if (!registros || registros.length === 0) {
    const error = new Error('No se encuentran concesiones registradas.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registros);
});

router.get('/concesion/:id', async (req, res, next) => {
  const id = parseInt(req.params.id);

  if (typeof id !== "number" || !Number.isInteger(id)) {
    const error = new Error('No se ingresó un ID válido.');
    error.status = 400;
    return next(error);
  }

  const registro = (await ejecutarSP('[concesion].[ConcesionConsulta]', { ID: id })).recordset;

  if (!registro || registro.length === 0) {
    const error = new Error('No se encuentra la concesión.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registro);
});

router.post('/concesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_AreaProtegida, CUIT_Empresa, ID_TipoConcesion, FechaInicio, FechaFin y Canon.');
    error.status = 400;
    return next(error);
  }

  const nuevaConcesion = req.body;
  const resultado = await ejecutarSP('[concesion].[ConcesionAlta]', nuevaConcesion);
  const idGenerado = resultado.recordset && resultado.recordset[0] ? resultado.recordset[0].ID : null;

  res.status(201).json({ message: 'Concesión creada.', id: idGenerado });
});

router.put('/concesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
    error.status = 400;
    return next(error);
  }

  const concesionModificada = req.body;
  await ejecutarSP('[concesion].[ConcesionModificacion]', concesionModificada);
  res.status(200).json({ message: 'Concesión actualizada.' });
});

router.delete('/concesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID de la concesión a eliminar.');
    error.status = 400;
    return next(error);
  }

  const bajaDatos = req.body;
  await ejecutarSP('[concesion].[ConcesionBaja]', bajaDatos);
  res.status(200).json({ message: 'Concesión eliminada.' });
});


// ============================================================================
// ABL FacturaConcesion
// ============================================================================

router.get('/facturaconcesion', async (req, res, next) => {
  const registros = (await ejecutarSP('[concesion].[FacturaConcesionConsulta]', {})).recordset;

  if (!registros || registros.length === 0) {
    const error = new Error('No se encuentran facturas de concesión registradas.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registros);
});

router.get('/facturaconcesion/:id', async (req, res, next) => {
  const id = parseInt(req.params.id);

  if (typeof id !== "number" || !Number.isInteger(id)) {
    const error = new Error('No se ingresó un ID válido.');
    error.status = 400;
    return next(error);
  }

  const registro = (await ejecutarSP('[concesion].[FacturaConcesionConsulta]', { ID: id })).recordset;

  if (!registro || registro.length === 0) {
    const error = new Error('No se encuentra la factura de concesión.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registro);
});

router.post('/facturaconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_Concesion, FechaEmision, FechaVencimiento y MontoEsperado.');
    error.status = 400;
    return next(error);
  }

  const nuevaFactura = req.body;
  const resultado = await ejecutarSP('[concesion].[FacturaConcesionAlta]', nuevaFactura);
  const idGenerado = resultado.recordset && resultado.recordset[0] ? resultado.recordset[0].ID : null;

  res.status(201).json({ message: 'Factura de concesión creada.', id: idGenerado });
});

router.put('/facturaconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
    error.status = 400;
    return next(error);
  }

  const facturaModificada = req.body;
  await ejecutarSP('[concesion].[FacturaConcesionModificacion]', facturaModificada);
  res.status(200).json({ message: 'Factura de concesión actualizada.' });
});

router.delete('/facturaconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID de la factura de concesión a eliminar.');
    error.status = 400;
    return next(error);
  }

  const bajaDatos = req.body;
  await ejecutarSP('[concesion].[FacturaConcesionBaja]', bajaDatos);
  res.status(200).json({ message: 'Factura de concesión eliminada.' });
});


// ============================================================================
// ABL PagoConcesion
// ============================================================================

router.get('/pagoconcesion', async (req, res, next) => {
  const registros = (await ejecutarSP('[concesion].[PagoConcesionConsulta]', {})).recordset;

  if (!registros || registros.length === 0) {
    const error = new Error('No se encuentran pagos de concesión registrados.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registros);
});

router.get('/pagoconcesion/:id', async (req, res, next) => {
  const id = parseInt(req.params.id);

  if (typeof id !== "number" || !Number.isInteger(id)) {
    const error = new Error('No se ingresó un ID válido.');
    error.status = 400;
    return next(error);
  }

  const registro = (await ejecutarSP('[concesion].[PagoConcesionConsulta]', { ID: id })).recordset;

  if (!registro || registro.length === 0) {
    const error = new Error('No se encuentra el pago de concesión.');
    error.status = 404;
    return next(error);
  }
  res.status(200).json(registro);
});

router.post('/pagoconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_Factura, FechaPago y MontoPagado.');
    error.status = 400;
    return next(error);
  }

  const nuevoPago = req.body;
  const resultado = await ejecutarSP('[concesion].[PagoConcesionAlta]', nuevoPago);
  const idGenerado = resultado.recordset && resultado.recordset[0] ? resultado.recordset[0].ID : null;

  res.status(201).json({ message: 'Pago de concesión creado.', id: idGenerado });
});

router.put('/pagoconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
    error.status = 400;
    return next(error);
  }

  const pagoModificado = req.body;
  await ejecutarSP('[concesion].[PagoConcesionModificacion]', pagoModificado);
  res.status(200).json({ message: 'Pago de concesión actualizado.' });
});

router.delete('/pagoconcesion', async (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del pago de concesión a eliminar.');
    error.status = 400;
    return next(error);
  }

  const bajaDatos = req.body;
  await ejecutarSP('[concesion].[PagoConcesionBaja]', bajaDatos);
  res.status(200).json({ message: 'Pago de concesión eliminado.' });
});

module.exports = router
