const { ejecutarSP, ejecutarQuery }     = require('./bd');
const { obtenerLatitudLongitudAreas, sleep }   = require('./fetchgeoapify');

async function obtenerAreasProtegidas(){
    try {
        const areasProtegidas = await ejecutarSP('parque.AreaProtegidaConsulta',{});
        return areasProtegidas;
    } catch (error) {
        console.error("Error: ", error);
        return [];
    }
}

async function actualizarLatitudLongitud(parametros){
    try {
        await ejecutarSP('parque.AreaProtegidaModificacion', parametros);
    } catch (error) {
        console.error("Error: ", error);
    }
}

async function ProcesarYActualizarAreas(){

    const areasProtegidas = await obtenerAreasProtegidas();

    //console.log("Areas capturadas: ");
    console.table(areasProtegidas);

    for(const area of areasProtegidas){
        const buscar = `${area.TipoArea} ${area.Nombre}`;
        console.log(`Buscando coordenadas para: ${buscar}...`);
        
        try {
            const latlon = await obtenerLatitudLongitudAreas(buscar,'');

            if (latlon && (latlon.latitud !== 0 || latlon.longitud !== 0)) {
                const parametros = { 
                    ID: area.ID, 
                    latitud: latlon.latitud, 
                    longitud: latlon.longitud 
                };
                
                await actualizarLatitudLongitud(parametros);
                console.log(`Se actualizó: ${buscar}`);
            } else {
                console.warn(`No se actulizó '${buscar}' por falta de coordenadas.`);
            }

        } catch (error) {
            console.error(`Error procesando el área ${buscar}:`, error);
        }
        console.log("Espera de 250ms...");
        await sleep(250);
    }
    //const areasProtegidasActualizadas = await obtenerAreasProtegidas();
    //console.table(areasProtegidasActualizadas);
}

ProcesarYActualizarAreas();