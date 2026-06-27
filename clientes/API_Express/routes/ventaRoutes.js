const express = require('express');
const router  = express.Router();
const {ejecutarSP, ejecutarQuery} = require('../bd');


router.get('/', (req, res)=>{
    res.send('Apartado de Ventas');
})

// ABL Divisa con SP ACTUALES

    router.get('/divisa', async (req, res, next) => {
        const divisas = await ejecutarSP('[venta].[DivisaConsulta]', {});
        
        if (!divisas || divisas.length === 0) {
            const error = new Error('No se encuentran divisas registradas.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(divisas);
    });

    router.get('/divisa/:id', async (req, res, next) => {

        const divisa = await ejecutarSP('[venta].[DivisaConsulta]', {COD_ISO: req.params.id});

        if (!divisa || divisa.length === 0) {
            const error = new Error('No se encuentra la divisa.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(divisa);
    });

    router.post('/divisa', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar COD_ISO, Pais y/o ValorEnPesos.');
            error.status = 400;
            return next(error);
        }

        const nuevaDivisa = req.body;
        await ejecutarSP('[venta].[DivisaAlta]', nuevaDivisa);
        res.status(201).json({ message: 'Divisa creada.' });
    });

    router.put('/divisa', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo COD_ISO para actualizar.');
            error.status = 400;
            return next(error);
        }

        const divisaModificada = req.body;
        await ejecutarSP('[venta].[DivisaModificacion]', divisaModificada);
        res.status(200).json({ message: 'Divisa actualizada.' });
    });

    router.delete('/divisa', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar COD_ISO para eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[venta].[DivisaBaja]', bajaDatos);
        res.status(200).json({ message: 'Divisa eliminada.' });
    });


// ABL Tipo de Entrada con SP ACTUALES

    router.get('/tipoentrada', async (req, res, next) => {
        const tipos = await ejecutarSP('[venta].[TipoEntradaConsulta]', {});
        
        if (!tipos || tipos.length === 0) {
            const error = new Error('No se encuentran tipos de entrada registrados.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(tipos);
    });

    router.get('/tipoentrada/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)){
                const error = new Error('No se ingresó un id válido.');
                error.status = 400;
                return next(error);
        }

        const tipo = await ejecutarSP('[venta].[TipoEntradaConsulta]', { ID: id});

        if (!tipo || tipo.length === 0) {
            const error = new Error('No se encuentra el tipo de entrada.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(tipo);
    });

    router.post('/tipoentrada', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar Nombre.');
            error.status = 400;
            return next(error);
        }

        const nuevoTipo = req.body;
        await ejecutarSP('[venta].[TipoEntradaAlta]', nuevoTipo);
        res.status(201).json({ message: 'Tipo de entrada creado.' });
    });

    router.put('/tipoentrada', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const tipoModificado = req.body;
        await ejecutarSP('[venta].[TipoEntradaModificacion]', tipoModificado);
        res.status(200).json({ message: 'Tipo de entrada actualizado.' });
    });

    router.delete('/tipoentrada', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del tipo de entrada a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[venta].[TipoEntradaBaja]', bajaDatos);
        res.status(200).json({ message: 'Tipo de entrada eliminado.' });
    });


// ABL Tipo de Entrada Parque con SP ACTUALES

    router.get('/tipoentradaparque', async (req, res, next) => {
        const registros = await ejecutarSP('[venta].[TipoEntradaParqueConsulta]', {});
        
        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran registros de tipos de entrada por parque.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.get('/tipoentradaparque/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)){
                const error = new Error('No se ingresó un id válido.');
                error.status = 400;
                return next(error);
        }

        const registro = await ejecutarSP('[venta].[TipoEntradaParqueConsulta]', { ID: id });

        if (!registro || registro.length === 0) {
            const error = new Error('No se encuentra el registro de tipo de entrada por parque.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registro);
    });

    router.post('/tipoentradaparque', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_AreaProtegida, ID_TipoEntrada y Precio.');
            error.status = 400;
            return next(error);
        }

        const nuevoRegistro = req.body;
        await ejecutarSP('[venta].[TipoEntradaParqueAlta]', nuevoRegistro);
        res.status(201).json({ message: 'Registro de tipo de entrada por parque creado.' });
    });

    router.put('/tipoentradaparque', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const registroModificado = req.body;
        await ejecutarSP('[venta].[TipoEntradaParqueModificacion]', registroModificado);
        res.status(200).json({ message: 'Registro de tipo de entrada por parque actualizado.' });
    });

    router.delete('/tipoentradaparque', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del registro a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[venta].[TipoEntradaParqueBaja]', bajaDatos);
        res.status(200).json({ message: 'Registro de tipo de entrada por parque eliminado.' });
    });


// ABL Comprobante con SP ACTUALES

    router.get('/comprobante', async (req, res, next) => {
        const comprobantes = await ejecutarSP('[venta].[ComprobanteConsulta]', {});
        
        if (!comprobantes || comprobantes.length === 0) {
            const error = new Error('No se encuentran comprobantes registrados.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(comprobantes);
    });

    router.get('/comprobante/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)){
                const error = new Error('No se ingresó un id válido.');
                error.status = 400;
                return next(error);
        }

        const comprobante = await ejecutarSP('[venta].[ComprobanteConsulta]', { ID: id });

        if (!comprobante || comprobante.length === 0) {
            const error = new Error('No se encuentra el comprobante.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(comprobante);
    });

    router.post('/comprobante', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_PuntoDeVenta, COD_ISO_Divisa, MedioDePago, FechaHora y Total.');
            error.status = 400;
            return next(error);
        }

        const nuevoComprobante = req.body;
        
        const resultado = await ejecutarSP('[venta].[ComprobanteAlta]', nuevoComprobante,{IDComprobante:0});
        //const idGenerado = resultado.output ? resultado.output.IDComprobante : null;

        res.status(201).json({ 
            message: 'Comprobante creado.', 
            //id: idGenerado 
        });
    });

    router.put('/comprobante', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const comprobanteModificado = req.body;
        await ejecutarSP('[venta].[ComprobanteModificacion]', comprobanteModificado);
        console.log(comprobanteModificado);
        res.status(200).json({ message: 'Comprobante actualizado.' });
    });

    router.delete('/comprobante', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del comprobante a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[venta].[ComprobanteBaja]', bajaDatos);
        console.log(bajaDatos);
        res.status(200).json({ message: 'Comprobante eliminado.' });
    });


// ABL Entrada con SP ACTUALES

    router.get('/entrada', async (req, res, next) => {
        const entradas = await ejecutarSP('[venta].[EntradaConsulta]', {});
        
        if (!entradas || entradas.length === 0) {
            const error = new Error('No se encuentran entradas registradas.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(entradas);
    });

    router.get('/entrada/:id', async (req, res, next) => {
        const id = parseInt(req.params.id);

        if (typeof id !== "number" || !Number.isInteger(id)){
                const error = new Error('No se ingresó un id válido.');
                error.status = 400;
                return next(error);
        }

        const entrada = await ejecutarSP('[venta].[EntradaConsulta]', { ID: id });

        if (!entrada || entrada.length === 0) {
            const error = new Error('No se encuentra la entrada.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(entrada);
        });

        // Alta
        router.post('/entrada', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_TipoEntradaParque, ID_Comprobante, FechaHora y PrecioCobrado.');
            error.status = 400;
            return next(error);
        }

        const nuevaEntrada = req.body;
        await ejecutarSP('[venta].[EntradaAlta]', nuevaEntrada);
        console.log(nuevaEntrada);
        res.status(201).json({ message: 'Entrada creada.' });
    });

    router.put('/entrada', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const entradaModificada = req.body;
        await ejecutarSP('[venta].[EntradaModificacion]', entradaModificada);
        console.log(entradaModificada);
        res.status(200).json({ message: 'Entrada actualizada.' });
    });

    router.delete('/entrada', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID de la entrada a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[venta].[EntradaBaja]', bajaDatos);
        console.log(bajaDatos);
        res.status(200).json({ message: 'Entrada eliminada.' });
    });

module.exports = router