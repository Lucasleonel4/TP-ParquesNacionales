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

    router.post('/divisa', async (req, res, next) => {
        if (!req.body || Object.keys(req.body).length === 0) {
            const error = new Error('El cuerpo de la petición está vacío. Debe enviar COD_ISO, Pais y/o ValorEnPesos.');
            error.status = 400;
            return next(error);
        }

        const nuevaDivisa = req.body;
        await ejecutarSP('[venta].[DivisaAlta]', nuevaDivisa);
        console.log(nuevaDivisa);
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
        console.log(divisaModificada);
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
        console.log(bajaDatos);
        res.status(200).json({ message: 'Divisa eliminada.' });
    });

module.exports = router