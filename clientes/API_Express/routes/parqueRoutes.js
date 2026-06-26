const express = require('express');
const router  = express.Router();
const {ejecutarSP, ejecutarQuery} = require('../bd');


router.get('/', (req, res)=>{
    res.send('Apartado de Areas Protegidas');
})

// ABL Areas Protegidas con SP actuales
    router.get('/areaprotegida', async (req, res)=>{
        const areasprotegidas = await ejecutarSP('[parque].[AreaProtegidaConsulta]',{});
        
        if(!areasprotegidas){
            const error = new Error('No se encuentran areas protegidas para mostrar.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(areasprotegidas);
    });

    router.post('/areaprotegida', async (req, res, next)=>{

        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar valores.');
            error.status = 400;
            return next(error);
        }

        const nuevaArea = req.body;
        await ejecutarSP('[parque].[AreaProtegidaAlta]', nuevaArea);
        console.log(nuevaArea);
        res.status(201).json({ message: 'Area creada.' });
    });

    router.put('/areaprotegida', async (req, res, next)=>{

       if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const nuevaArea = req.body;
        await ejecutarSP('[parque].[AreaProtegidaModificacion]', nuevaArea);
        console.log(nuevaArea);
        res.status(200).json({ message: 'Area actualizada.' });
    });
    
    router.delete('/areaprotegida', async (req, res, next)=>{

        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del area a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[parque].[AreaProtegidaBaja]', bajaDatos);
        console.log(bajaDatos);
        res.status(200).json({ message: 'Area eliminada.' });
    });


// ABL Punto de Venta con SP Actuales
    router.get('/puntodeventa', async (req, res, next) => {
        const puntos = await ejecutarSP('[parque].[PuntoDeVentaConsulta]', {});
        
        if (!puntos || puntos.length === 0) {
            const error = new Error('No se encuentran puntos de venta para mostrar.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(puntos);
    });

    router.post('/puntodeventa', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar valores.');
            error.status = 400;
            return next(error);
        }

        const nuevoPunto = req.body;
        await ejecutarSP('[parque].[PuntoDeVentaAlta]', nuevoPunto);
        console.log(nuevoPunto);
        res.status(201).json({ message: 'Punto de venta creado.' });
    });

    router.put('/puntodeventa', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar mínimo el ID para actualizar.');
            error.status = 400;
            return next(error);
        }

        const puntoModificado = req.body;
        await ejecutarSP('[parque].[PuntoDeVentaModificacion]', puntoModificado);
        console.log(puntoModificado);
        res.status(200).json({ message: 'Punto de venta actualizado.' });
    });

    router.delete('/puntodeventa', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar el ID del punto de venta a eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[parque].[PuntoDeVentaBaja]', bajaDatos);
        console.log(bajaDatos);
        res.status(200).json({ message: 'Punto de venta eliminado.' });
    });


// ABL Provincia contiene Parque, con SP Actuales (Posiblemente no se use)
    router.get('/provinciacontieneparque', async (req, res, next) => {
        const registros = await ejecutarSP('[parque].[ProvinciaContieneParqueConsulta]', {});
        
        if (!registros || registros.length === 0) {
            const error = new Error('No se encuentran registros de provincias con parques.');
            error.status = 404;
            return next(error);
        }
        res.status(200).json(registros);
    });

    router.post('/provinciacontieneparque', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_Provincia e ID_AreaProtegida.');
            error.status = 400;
            return next(error);
        }

        const nuevoRegistro = req.body;
        await ejecutarSP('[parque].[ProvinciaContieneParqueAlta]', nuevoRegistro);
        console.log(nuevoRegistro);
        res.status(201).json({ message: 'Relación provincia-parque creada.' });
    });

    router.delete('/provinciacontieneparque', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar ID_Provincia e ID_AreaProtegida para eliminar.');
            error.status = 400;
            return next(error);
        }

        const bajaDatos = req.body;
        await ejecutarSP('[parque].[ProvinciaContieneParqueBaja]', bajaDatos);
        console.log(bajaDatos);
        res.status(200).json({ message: 'Relación provincia-parque eliminada.' });
    });
    
module.exports = router