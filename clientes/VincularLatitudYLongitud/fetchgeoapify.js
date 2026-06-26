
require('dotenv').config();

// FUNCION DE SLEEP PARA 1 GET CADA 0.2 SEGS
function sleep(ms) {
    return new Promise(function(resolve) {
        setTimeout(resolve, ms);
    });
}

// FUNCION LARGA PARA FETCH
async function obtenerLatitudLongitudAreas(nombreArea, provincia){
    try {
        const APIKey = process.env.GEOAPIFY_APIKey
        const urlDefalt = 'https://api.geoapify.com/v1/geocode/search'
        const textoBusqueda = provincia ? `${nombreArea}, ${provincia}` : nombreArea;
        const urlFetch = `${urlDefalt}?text=${encodeURIComponent(textoBusqueda)}&filter=countrycode:ar&apiKey=${APIKey}`;

        const response = await fetch(urlFetch);
        
        if(!response.ok){
            throw new Error(`Error HTTP: El estado es ${response.status}`);
        }

        const datosUbicacion = await response.json();

        if (!datosUbicacion.features || datosUbicacion.features.length === 0) {
            console.warn(`No se encontraron resultados para: ${nombreArea}`);
            return {latitud: 0, longitud: 0};
        }
        const propiedadUbicacion = datosUbicacion.features[0].properties;

        return {
            latitud: propiedadUbicacion.lat,
            longitud: propiedadUbicacion.lon 
        };

    } catch (error) {
        console.error("No se pudo conectar a la API");
        return {latitud: 0, longitud: 0};
    }
}

module.exports = {obtenerLatitudLongitudAreas, sleep};