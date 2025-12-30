# Sentencias SQL



Las bases de datos se crearon inicialmente para establecer límites claros de dominio a lo largo del proyecto. Una vez definido el esquema analítico final y la estrategia de ingesta de datos, se implementaron las definiciones de tablas.

La información detallada usada en los documentos sobre el ds\_id asignado, las columnas creadas en SQL y su uso en Power BI se encuentra en el documento de Excel generated\_tables.xls.



### 1\. Base de Datos y Fundamentos

###### 1.0\_create\_databases



Se empieza el proyecto creando bases de datos PostgreSQL específicas por dominio, incluyendo una corrección posterior que renombra deudas a creditos para mantener la consistencia conceptual usada.



###### 1.1\_create\_schema\_album\_financiero



Crea el esquema central album\_financiero y migra las tablas existentes desde el esquema public para establecer un entorno de modelado unificado.



###### 1.2\_create\_tables\_from\_csv



Crea tablas de hechos (fact\_) y dimensiones (dim\_) en PostgreSQL para soportar la importación de datos desde archivos CSV, incluyendo un control explícito del parseo de fechas para garantizar tipos de datos consistentes.



###### 1.3\_transform\_fact\_tables



Enriquece las tablas de hechos con columnas analíticas derivadas (claves de periodo, clasificaciones y cálculos) para soportar análisis temporales y el modelado en Power BI.



###### 1.4\_automate\_fact\_table\_updates



Automatización basada en desencadenantes (TRIGGERS) de PostgreSQL para recalcular columnas analíticas derivadas cada vez que las tablas de hechos o dimensiones son insertadas o actualizadas a partir de datos CSV actualizados.



### 2\. Conjuntos de Datos Curados para Analítica



Los datasets de esta sección se implementan como vistas materializadas para obtener datos limpios, deduplicados y transformados utilizados por el modelo semántico de Power BI.

Al almacenar los resultados físicamente y refrescarlos de forma explícita, estos datasets proporcionan snapshots analíticos consistentes, un mejor rendimiento y una separación clara entre las capas de preparación y consumo de datos.



Cada dataset se implementa en dos versiones:



•	v\_ datasets exponen uniones completas, clasificaciones y cálculos para permitir inspección y resolución de problemas directamente en DBeaver.



•	ds\_ datasets finales conservan únicamente los campos requeridos para relaciones y visuales en Power BI, con claves primarias definidas explícitamente para su correcta relación.



Este enfoque mantiene la claridad del modelo en Power BI, al mismo tiempo que preserva datasets transparentes y orientados al analista para futura validación técnica.



###### 2.0\_datasets\_dimensions



Define datasets de dimensiones curados que estandarizan atributos descriptivos y lógica de clasificación utilizada en todo el modelo de datos de Power BI.



###### 2.1\_datasets\_presupuesto



Define datasets de presupuesto curados que asignan cada transacción a un identificador de presupuesto y estructuran asignaciones mensuales para su comparación analítica contra el gasto real.



###### 2.2\_datasets\_viajes



Define datasets de viajes curados que aíslan transacciones relacionadas con viajes y las enriquecen con agrupaciones geográficas y tipos de cambio históricos, permitiendo análisis de gasto en moneda local y base.



###### 2.3\_datasets\_creditos



Define datasets de créditos curados que asocian transacciones con su línea de crédito y periodo de facturación correspondiente, habilitando el análisis de gastos y abonos por ciclo de crédito.



###### 2.4\_datasets\_terceros



Define datasets curados que identifican transacciones relacionadas con terceros y registros de deuda mediante la extracción directa de nombres de contrapartes desde las descripciones de transacciones.



###### 2.5\_datasets\_movimiento



Define datasets curados que rastrean fuentes de ingreso y comportamiento de inversión, separando movimientos impulsados por el usuario del desempeño de inversiones impulsado por el mercado a lo largo del tiempo.

