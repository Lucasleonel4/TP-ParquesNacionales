# Sobre la Herramienta
API en Express de la base de datos usando el paquete "mssql".
Esta API se podrá usar, por ejemplo en Postman.

## Como usar
1. Crear el archivo .ENV en la carpeta raiz del cliente. Este debe contener, por ejemplo:
    ```text
    DB_USER: administrador
    DB_PASSWORD: Password@Administrador
    DB_SERVER: localhost
    DB_DATABASE: com2900
    DB_PORT: 1433
    PORT: 4000
2. Instalar los paquetes de Node.
    ```bash
    npm install
> Debe tenerse instalado node y npm.
3. Correr el servidor
- Usando nodemon
    ```bash
    npm run dev
- Usando node
    ```bash
    node app.js
4. Para dejar de correr el servidor: En la terminal (usar bash), tipear "ctrl + c".

## Previo a usar
1. Configurar puertos y habilitar TCP en la configuración del motor.
2. Configurar firewall de windows si corresponde.
3. Importar en postman el archivo JSON _(Postman_BDA-ParquesNacionales)_ con los endpoints de consultas y los cuerpos correspondientes. Consulta, para todos los endpoints, el puerto 4000 de localhost.