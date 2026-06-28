const express = require('express');
const router  = express.Router();
const {ejecutarSP, ejecutarQuery} = require('../bd');


router.get('/', (req, res)=>{
    res.send('Apartado de Personal');
})

// ============================================================================
// ABL GuiaAutorizado
// ============================================================================

    router.get('/guiaautorizado', async (req, res, next) => {
        const registros = (await ejecutarSP('[personal].[GuiaAutorizadoConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran guías autorizados registrados.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/guiaautorizado/:cuil', async (req, res, next) => {
        const cuil = parseInt(req.params.cuil);

        if (typeof cuil !== "number" || !Number.isInteger(cuil)) {
            const error = new Error('No se ingresó un CUIL válido.');
            error.status = 400;
            return next(error);
        }

        const registro = (await ejecutarSP('[personal].[GuiaAutorizadoConsulta]', { CUIL: cuil })).recordset;

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra el guía autorizado.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/guiaautorizado', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar CUIL, Nombre, Apellido y Autorizado.');
            error.status = 400;
            return next(error);
        }

        const nuevoGuia = req.body;
        await ejecutarSP('[personal].[GuiaAutorizadoAlta]', nuevoGuia);
        res.status(201).json({ message: 'Guía autorizado creado.' });
    });

    router.put('/guiaautorizado', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el CUIL para actualizar.');
            error.status = 400;
            return next(error);
        }

        const guiaModificado = req.body;
        await ejecutarSP('[personal].[GuiaAutorizadoModificacion]', guiaModificado);
        res.status(200).json({ message: 'Guía autorizado actualizado.' });
    });

    router.delete('/guiaautorizado', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el CUIL del guía a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[personal].[GuiaAutorizadoBaja]', bajaDatos);
        res.status(200).json({ message: 'Guía autorizado eliminado.' });
    });


// ============================================================================
// ABL Guardaparques
// ============================================================================

    router.get('/guardaparques', async (req, res, next) => {
        const registros = (await ejecutarSP('[personal].[GuardaparquesConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran guardaparques registrados.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/guardaparques/:cuil', async (req, res, next) => {
        const cuil = parseInt(req.params.cuil);

        if (typeof cuil !== "number" || !Number.isInteger(cuil)) {
            const error = new Error('No se ingresó un CUIL válido.');
            error.status = 400;
            return next(error);
        }

        const registro = (await ejecutarSP('[personal].[GuardaparquesConsulta]', { CUIL: cuil })).recordset;

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra el guardaparques.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/guardaparques', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar CUIL, Nombre, Apellido, FechaNacimiento y FechaIngreso.');
            error.status = 400;
            return next(error);
        }

        const nuevoGuardaparques = req.body;
        await ejecutarSP('[personal].[GuardaparquesAlta]', nuevoGuardaparques);
        res.status(201).json({ message: 'Guardaparques creado.' });
        });

        router.put('/guardaparques', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el CUIL para actualizar.');
            error.status = 400;
            return next(error);
        }

        const guardaparquesModificado = req.body;
        await ejecutarSP('[personal].[GuardaparquesModificacion]', guardaparquesModificado);
        res.status(200).json({ message: 'Guardaparques actualizado.' });
    });

    router.delete('/guardaparques', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el CUIL del guardaparques a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[personal].[GuardaparquesBaja]', bajaDatos);
        res.status(200).json({ message: 'Guardaparques eliminado.' });
    });

// ============================================================================
// ABL Contrato de Trabajo
// ============================================================================

    router.get('/contratotrabajo', async (req, res, next) => {
        const registros = (await ejecutarSP('[personal].[ContratoTrabajoConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran contratos de trabajo registrados.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/contratotrabajo/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)) {
            const error = new Error('No se ingresó un ID válido.');
            error.status = 400;
            return next(error);
        }

        const registro = (await ejecutarSP('[personal].[ContratoTrabajoConsulta]', { ID: id })).recordset;

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra el contrato de trabajo.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/contratotrabajo', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_AreaProtegida, CUIL_Guardaparques, FechaInicio y opcionalmente FechaFin.');
            error.status = 400;
            return next(error);
        }

        const nuevoContrato = req.body;
        await ejecutarSP('[personal].[ContratoTrabajoAlta]', nuevoContrato);
        res.status(201).json({ message: 'Contrato de trabajo creado.' });
    });

    router.put('/contratotrabajo', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const contratoModificado = req.body;
        await ejecutarSP('[personal].[ContratoTrabajoModificacion]', contratoModificado);
        res.status(200).json({ message: 'Contrato de trabajo actualizado.' });
    });

    router.delete('/contratotrabajo', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del contrato de trabajo a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[personal].[ContratoTrabajoBaja]', bajaDatos);
        res.status(200).json({ message: 'Contrato de trabajo eliminado.' });
    });

// ============================================================================
// ABL Permiso de Trabajo
// ============================================================================

    router.get('/permisodetrabajo', async (req, res, next) => {
        const registros = (await ejecutarSP('[personal].[PermisoDeTrabajoConsulta]', {})).recordset;

        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran permisos de trabajo registrados.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/permisodetrabajo/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)) {
            const error = new Error('No se ingresó un ID válido.');
            error.status = 400;
            return next(error);
        }

        const registro = (await ejecutarSP('[personal].[PermisoDeTrabajoConsulta]', { ID: id })).recordset;

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra el permiso de trabajo.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/permisodetrabajo', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_AreaProtegida, CUIL_GuiaAutorizado, FechaInicio y opcionalmente FechaFin.');
            error.status = 400;
            return next(error);
        }

        const nuevoPermiso = req.body;
        await ejecutarSP('[personal].[PermisoDeTrabajoAlta]', nuevoPermiso);
        res.status(201).json({ message: 'Permiso de trabajo creado.' });
        });

        // Modificación
        router.put('/permisodetrabajo', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const permisoModificado = req.body;
        await ejecutarSP('[personal].[PermisoDeTrabajoModificacion]', permisoModificado);
        res.status(200).json({ message: 'Permiso de trabajo actualizado.' });
    });

    router.delete('/permisodetrabajo', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del permiso de trabajo a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[personal].[PermisoDeTrabajoBaja]', bajaDatos);
        res.status(200).json({ message: 'Permiso de trabajo eliminado.' });
    });

    
module.exports = router