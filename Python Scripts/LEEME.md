# Orquestación del pipeline en Python



Automatizacion de ingestión y actualización de datos, utilizando Python para sincronizar documents CSV, actualización de tablas vistas materializadas (MATERIALIZED VIEW) en PostgreSQL y los reportes finales usados en Power BI.



###### 0.actualizar\_album\_financiero.exe

Ejecuta el proceso completo de actualización de datos en un solo documento EXE, automatizando el seguimiento y actualización de la carpeta de imágenes, la generación de archivos CSV, la carga en PostgreSQL y la actualización de vistas materializadas requeridas por la solución en Power BI.



Los siguientes guiones están enfocados en cada uno de los pasos realizados en el documento EXE.



###### 1.actualizar\_powerbi\_viajes

Automatiza la detección de cambios en los recursos de imágenes relacionados en su carpeta, regenera el conjunto de datos de referencia correspondiente y sincroniza las actualizaciones con el repositorio para su consumo posterior en Power BI.



###### 2.exportar\_a\_csv

Exporta y estandariza los datos financieros de origen basados en Excel en conjuntos de datos listos en formato CSV, permitiendo una importación correcta en PostgreSQL.



###### 3.refrescar\_tablas

Automatiza la carga masiva de archivos CSV depurados en las tablas de hechos (FACTS) y dimensiones (DIM) de PostgreSQL, funcionando como la etapa de importación del pipeline analítico.



###### 4.actualizar\_tablas

Automatiza la actualización de todas las vistas materializadas en PostgreSQL para propagar los datos recién importados hacia los conjuntos de datos analíticos (datasets) curados.

