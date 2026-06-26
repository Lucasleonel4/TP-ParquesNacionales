# Importar Latitud y Longitud
Lo que realiza esto es obtener de una API (GEOAPIFY) la latitud y longitud de las areas protegidas buscadas por búsqueda libre (cadena de caracteres simple)
La fetch url tiene una modifiación para solo traer resultados de argentina. 
La consulta a la API devuelve los centroides de los parques nacionales. Además de otros campos como 'state' que equivale a la provincia de donde es el centroide.
    Esto último se podría usar para asignar provincias. Sin embargo, será una sola provincia la que contenga el centroides. Entonces, habría que modificar el DER.
    Adicionalmente, se dan como correctas las latitud y longitudes devuelvas, deberían comprobarse. Se asigna siempre la primera devuelta.
> La busqueda de coordenadas del 'Monumento Natural Bloque Herratico' no devuelve resultados... unico que falla

## Como usar GEOAPIFY
1. Registrarse (Gratis)
2. Crear un nuevo proyecto.
3. Solicitar API Key para Geocoding.
4. Reemplazar en el archivo .ENV con la KEY obtenida.
> La API permite máximo 3000 consultas por día. Y solo 5 por segundo.

## Como conectar la APP con SQLServer (Solo habilitar puertos)
1. En SQL Server Configuration Manager -> SQL Server Network Configuration. Hacer clic en la instancia 
2. Habilitar TCP/IP 
3. Clic derecho en TCP/IP e ir a Propiedades, luego a IP Addresses
4. Bajar hasta IPAII y poner 0 en puertos dinámicos y asignar un puerto para TCP PORT
5. Ver si firewall bloquea la conexión y habilitar el puerto si lo hace. (No me generó problemas)

## Como debe ser el Archivo .ENV
El archivo .ENV deberá tener los valores (con ejemplos):
- DB_USER: sa
- DB_PASSWORD: 202604@Password123
- DB_SERVER: localhost
- DB_DATABASE: com2900
- DB_PORT: 1433
- GEOAPIFY_APIKey: 4e8354sadfsdf12334fadfsd

## Como usar la herramienta
1. Se debe tener node instalado.
2. Se debe tener el archivo .ENV generado
3. Ejecutar en terminal (dentro de la carpeta del cliente): npm install, para descargar los componentes: mssql, nodemon y dotenv
4. Lo que se usa para relacionar las AreasProtegidas con la latitud y longitud buscada está en app.js. 
    Entonces: ejecutar node app.js.
    O bien, con nodemon: npm run dev