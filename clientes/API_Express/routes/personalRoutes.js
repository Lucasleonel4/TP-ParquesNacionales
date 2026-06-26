const express = require('express');
const router  = express.Router();
const {ejecutarSP, ejecutarQuery} = require('../bd');


router.get('/', (req, res)=>{
    res.send('Apartado de Personal');
})

module.exports = router