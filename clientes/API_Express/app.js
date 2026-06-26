require('dotenv').config();

const express = require('express');
const app     = express();
const PORT    = process.env.PORT || 4000;

const parqueRoutes      = require('./routes/parqueRoutes');
const personalRoutes    = require('./routes/personalRoutes');
const ventaRoutes       = require('./routes/ventaRoutes');
const actividadRoutes   = require('./routes/actividadRoutes');
const concesionRoutes   = require('./routes/concesionRoutes');

app.use(express.json());

app.get('/', (req, res)=>{res.send('Conectado a la API de Parques Nacionales');});

app.use('/parque',      parqueRoutes);
app.use('/personal',     personalRoutes);
app.use('/venta',        ventaRoutes);
app.use('/actividad',    actividadRoutes);
app.use('/concesion',    concesionRoutes);

app.use((req, res, next) => {
  const error = new Error(`Ruta no encontrada: ${req.originalUrl}`);
  error.status = 404;
  next(error); // Se lo pasamos a nuestro manejador de errores central
});

app.use((err, req, res, next) => {
  const statusCode = err.status || 500;
  //console.error(err.message, err.stack);
  res.status(statusCode).json({
    message: err.message || 'Ha ocurrido un error en el servidor.',
  });
});

app.listen(PORT, ()=>{
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
})
