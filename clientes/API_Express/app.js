require('dotenv').config();
const { cerrarConexion } = require('./bd');

const express = require('express');
const app     = express();
const cors    = require('cors');
const PORT    = process.env.PORT || 4000;

const parqueRoutes      = require('./routes/parqueRoutes');
const personalRoutes    = require('./routes/personalRoutes');
const ventaRoutes       = require('./routes/ventaRoutes');
const actividadRoutes   = require('./routes/actividadRoutes');
const concesionRoutes   = require('./routes/concesionRoutes');

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Para poder recibir como objeto lo que envia un formulario html

app.get('/', (req, res)=>{res.send('Conectado a la API de Parques Nacionales');});

app.use('/parque',       parqueRoutes);
app.use('/venta',        ventaRoutes);
app.use('/actividad',    actividadRoutes);
app.use('/personal',     personalRoutes);
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

// Cierre del Pool y Conexion a la BD
const apagadoAPI = async () => {
  console.log('\n====================================');
    console.log('Se está apagando el servidor...');
    await cerrarConexion(); 
    console.log('Conexión cerrada correctamente.');
    console.log('====================================');
    process.exit(0);
};
process.on('SIGINT', apagadoAPI);