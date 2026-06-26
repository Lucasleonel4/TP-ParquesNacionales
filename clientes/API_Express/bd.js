require('dotenv').config();
const sql = require('mssql');

// CONFIGURACIÓN: 
const config = {

    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_DATABASE,
    port: parseInt(process.env.DB_PORT),
    options:{
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
    }
};

console.log("Intentando conectar a la BD...");

// POOL DE CONEXIÓN: 
    //  Reserva conexiones para no crear nuevas cada vez que se hace manipula la BD
const pool = new sql.ConnectionPool(config);
const poolConnect = pool.connect()
                    .then(()=>{
                         console.log('INFO: Conexión Exitosa a SQL Server');
                         // mostrar info de base de datos
                    })
                    .catch((err)=>{
                        console.error('ERROR: Problema al conectar con SQL Server');
                        console.error('Mensaje: ', err.message);
                        if (err.code === 'ESOCKET') {
                            console.error('Posibles causas: Puerto incorrecto, servidor apagado o firewall');
                        }
                        if (err.code === 'ELOGIN') {
                            console.error('Error de login: Usuario o contraseña incorrectos');
                        }
                    })


// FUNCION PARA EJECUTAR UN PROCEDIMIENTO ALMACENADO
async function ejecutarSP(nombreSP, parametros = {}){
    try {
        await poolConnect;

        const request = pool.request();

        //Agrega los parametros concatenando pares clave-valor
        Object.keys(parametros).forEach(key=>{
            request.input(key, parametros[key]);
        });

        const resultado = await request.execute(nombreSP);

        return resultado.recordset || [];

    } catch (error) {
        console.error(`Error al ejecutar SP ${nombreSP}: `, error.message);
        throw error; // Devuelve el error en la funcion que lo llama
    }
}

// FUNCION PARA EJECUTAR UNA QUERY
async function ejecutarQuery(sqlQuery, parametros = []){

    try {
        await poolConnect;

        const request = pool.request();

        Object.keys(parametros).forEach(key=>{
            request.input(key, parametros[key]);
        })

        const resultado = await request.query(sqlQuery);
     
        return resultado.recordset;

    } catch (error) {
        console.error('Error en la query: ', error.message);
        throw error; // Devuelve el error en la funcion que lo llama
    }
}

// FUNCION PARA CERRAR EL POOL DE CONEXIONES
async function cerrarConexion(){

    try {
        await pool.close();
        console.log('Pool de conexiones cerrado');
    } catch (error) {
      console.error('Error al cerrar el pool de conexiones: ', error.message);  
    }
}

// EXPORTAR LAS FUNCIONES Y PAQUETES
module.exports = {
    ejecutarSP,
    ejecutarQuery,
    cerrarConexion,
    sql // Exporta el paquete mssql
}