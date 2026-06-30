# Política de Respaldo y Recuperación

**Universidad:** Universidad Nacional de La Matanza  
**Materia:** Base de Datos Aplicadas  
**Comisión:** 2900 (Martes noche)  
**Grupo:** 12  
**Fecha:** 30/06/2026  
**Sistema:** Gestión de Parques Nacionales  

## Objetivo

Definir una política simple de respaldo y recuperación para la base de datos `com2900`, con el fin de reducir la pérdida de información ante fallas de hardware, errores humanos, corrupción de datos o incidentes operativos.

## Alcance

La política aplica a:

- Base de datos principal `com2900`.
- Tablas operativas de parques, ventas, actividades, personal y concesiones.
- Datos importados desde archivos externos.
- Datos obtenidos desde APIs.
- Scripts de creación, seed data, reportes, seguridad y cifrado versionados en el repositorio.

No contempla respaldo de estaciones de trabajo ni archivos temporales locales usados durante pruebas.

## Objetivos De Recuperación

**RPO, Recovery Point Objective:** 24 horas.  
La pérdida máxima aceptable de datos es de un día operativo.

**RTO, Recovery Time Objective:** 4 horas.  
El tiempo objetivo para restaurar el servicio ante una falla crítica es de hasta 4 horas.

## Estrategia De Backup

Para un ambiente productivo se propone:

- Backup completo diario de la base `com2900`.
- Backup diferencial cada 6 horas durante la jornada operativa.
- Backup de log de transacciones cada 30 minutos, si la base se configura con modelo de recuperación `FULL`.
- Backup manual previo a cambios estructurales, despliegues o importaciones masivas.

Para el ambiente académico/local del TP:

- Ejecutar backup completo antes de la defensa o antes de pruebas destructivas.
- Conservar los scripts en GitHub como mecanismo adicional para recrear la base desde cero.

## Retención

Política sugerida:

- Backups diarios: conservar 7 días.
- Backups semanales: conservar 4 semanas.
- Backups mensuales: conservar 6 meses.
- Backups previos a despliegues importantes: conservar hasta validar correctamente el cambio.

## Ubicación De Backups

Los archivos `.bak` deben almacenarse fuera del directorio de datos de SQL Server. Se recomienda:

- Carpeta local dedicada para respaldos.
- Copia secundaria en almacenamiento externo o nube institucional.
- Restricción de permisos al equipo administrador de base de datos.

Ejemplo de ruta local:

```text
C:\SQLBackups\com2900\
```

## Validación De Backups

Cada backup debe verificarse mediante:

- Confirmación de finalización exitosa del comando `BACKUP DATABASE`.
- Revisión del historial de backups de SQL Server.
- Prueba periódica de restauración en una base alternativa, por ejemplo `com2900_restore_test`.

La existencia del archivo `.bak` no garantiza que el respaldo sea recuperable; por eso se recomienda probar restauraciones.

## Procedimiento De Backup Completo

Ejemplo T-SQL:

```sql
BACKUP DATABASE com2900
TO DISK = 'C:\SQLBackups\com2900\com2900_full.bak'
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;
```

## Procedimiento De Restauración De Prueba

Ejemplo T-SQL:

```sql
RESTORE VERIFYONLY
FROM DISK = 'C:\SQLBackups\com2900\com2900_full.bak'
WITH CHECKSUM;
```

Para una restauración real o de prueba se debe restaurar sobre una base distinta o asegurar que no haya usuarios conectados a la base destino.

## Responsabilidades

**Administrador de base de datos**

- Ejecutar y monitorear backups.
- Probar restauraciones periódicamente.
- Controlar permisos sobre archivos de respaldo.
- Documentar incidentes y recuperaciones.

**Equipo de desarrollo**

- Mantener scripts versionados en GitHub.
- Avisar antes de cambios estructurales o importaciones masivas.
- No versionar archivos `.bak`, contraseñas ni datos sensibles.

## Consideraciones De Seguridad

- Los backups pueden contener datos sensibles, como CUIL de personal.
- Deben almacenarse en ubicaciones protegidas.
- No deben subirse al repositorio público.
- Si se trasladan fuera del equipo local, deben cifrarse o protegerse mediante almacenamiento seguro.

## Criterio Para El TP

Para el alcance académico del trabajo práctico, se considera suficiente:

- Tener documentada la política de respaldo.
- Conservar scripts idempotentes para recrear la base.
- Ejecutar backups manuales antes de pruebas importantes.
- No versionar archivos `.bak` ni credenciales.

