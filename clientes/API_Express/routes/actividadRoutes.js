const express = require('express');
const router  = express.Router();
const {ejecutarSP, ejecutarQuery} = require('../bd');


router.get('/', (req, res)=>{
    res.send('Apartado de Actividades');
})


// ============================================================================
// ABL TipoActividad
// ============================================================================

    router.get('/tipoactividad', async (req, res, next) => {
        const registros = (await ejecutarSP('[actividad].[TipoActividadConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran tipos de actividad registrados.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/tipoactividad/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)) {
            const error = new Error('No se ingresó un ID válido.');
            error.status = 400;
            return next(error);
        }

        const registro = (await ejecutarSP('[actividad].[TipoActividadConsulta]', { ID: id })).recordset;

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra el tipo de actividad.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/tipoactividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar Nombre.');
            error.status = 400;
            return next(error);
        }

        const nuevoRegistro = req.body;
        await ejecutarSP('[actividad].[TipoActividadAlta]', nuevoRegistro);
        res.status(201).json({ message: 'Tipo de actividad creado.' });
    });

    router.put('/tipoactividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const registroModificado = req.body;
        await ejecutarSP('[actividad].[TipoActividadModificacion]', registroModificado);
        res.status(200).json({ message: 'Tipo de actividad actualizado.' });
    });

    router.delete('/tipoactividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del tipo de actividad a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[actividad].[TipoActividadBaja]', bajaDatos);
        res.status(200).json({ message: 'Tipo de actividad eliminado.' });
    });


// ============================================================================
// ABL Actividad
// ============================================================================

    router.get('/actividad', async (req, res, next) => {
        const registros = (await ejecutarSP('[actividad].[ActividadConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran actividades registradas.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/actividad/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)) {
            const error = new Error('No se ingresó un ID válido.');
            error.status = 400;
            return next(error);
        }

        const registro = (await ejecutarSP('[actividad].[ActividadConsulta]', { ID: id })).recordset;

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra la actividad.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/actividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_AreaProtegida, ID_TipoActividad, Nombre, Duracion, Costo y CupoMaximo.');
            error.status = 400;
            return next(error);
        }

        const nuevaActividad = req.body;
        await ejecutarSP('[actividad].[ActividadAlta]', nuevaActividad);
        res.status(201).json({ message: 'Actividad creada.' });
    });

    router.put('/actividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const actividadModificada = req.body;
        await ejecutarSP('[actividad].[ActividadModificacion]', actividadModificada);
        res.status(200).json({ message: 'Actividad actualizada.' });
    });

    router.delete('/actividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID de la actividad a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[actividad].[ActividadBaja]', bajaDatos);
        res.status(200).json({ message: 'Actividad eliminada.' });
    }); 


// ============================================================================
// ABL InscripcionActividad
// ============================================================================

    router.get('/inscripcionactividad', async (req, res, next) => {
        const registros = (await ejecutarSP('[actividad].[InscripcionActividadConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran inscripciones registradas.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/inscripcionactividad/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)) {
            const error = new Error('No se ingresó un ID válido.');
            error.status = 400;
            return next(error);
        }

        const registro = (await ejecutarSP('[actividad].[InscripcionActividadConsulta]', { ID: id })).recordset;

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra la inscripción.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/inscripcionactividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_Actividad, ID_Comprobante, FechaHora y PrecioCobrado.');
            error.status = 400;
            return next(error);
        }

        const nuevaInscripcion = req.body;
        await ejecutarSP('[actividad].[InscripcionActividadAlta]', nuevaInscripcion);
        res.status(201).json({ message: 'Inscripción creada.' });
    });

    router.put('/inscripcionactividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const inscripcionModificada = req.body;
        await ejecutarSP('[actividad].[InscripcionActividadModificacion]', inscripcionModificada);
        res.status(200).json({ message: 'Inscripción actualizada.' });
    });

    router.delete('/inscripcionactividad', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID de la inscripción a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[actividad].[InscripcionActividadBaja]', bajaDatos);
        res.status(200).json({ message: 'Inscripción eliminada.' });
    });


// ============================================================================
// ABL GuiaAsignadoTour
// ============================================================================

    router.get('/guiaasignadotour', async (req, res, next) => {
        const registros = (await ejecutarSP('[actividad].[GuiaAsignadoTourConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran guías asignados a tours.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/guiaasignadotour/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)) {
            const error = new Error('No se ingresó un ID válido.');
            error.status = 400;
            return next(error);
        }

        const registros = (await ejecutarSP('[actividad].[GuiaAsignadoTourConsulta]', {ID_Actividad: id})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran guías asignados al tour.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.post('/guiaasignadotour', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_Actividad y CUIL_GuiaAutorizado.');
            error.status = 400;
            return next(error);
        }

        const nuevoRegistro = req.body;
        await ejecutarSP('[actividad].[GuiaAsignadoTourAlta]', nuevoRegistro);
        res.status(201).json({ message: 'Guía asignado a tour creado.' });
    });

    router.delete('/guiaasignadotour', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_Actividad y CUIL_GuiaAutorizado para eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[actividad].[GuiaAsignadoTourBaja]', bajaDatos);
        res.status(200).json({ message: 'Guía asignado a tour eliminado.' });
    });

module.exports = router