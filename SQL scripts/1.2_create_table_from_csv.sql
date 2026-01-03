-- This script defines the physical structure of fact and dimension tables used in the project and prepares them for CSV imports.
-- Date fields are initially loaded as text and later converted to DATE to avoid parsing inconsistencies during ingestion.


--CSV012 dim_geografia
CREATE TABLE album_financiero.dim_geografia (
    id_geografia serial PRIMARY KEY,   --This create a numeric serial id.
	ubicacion_viajes varchar(70),
    continente varchar(50),
    pais varchar(70),
    estado_region varchar(70),
	moneda varchar(50),
	latitud numeric,
	longitud numeric
);



--CSV013 dim_id_presupuesto
CREATE TABLE album_financiero.dim_id_presupuesto (
   	id_presupuesto varchar(10) PRIMARY KEY,
	concepto_principal varchar(50),
	tipo varchar(20),
	descripcion varchar(100),
	grupo_viaje varchar(10),
	razon_uso varchar(20),
	clave varchar(20),
	descripcion_c_diaria varchar(50)
);



--CSV014 fact_parametros
CREATE TABLE album_financiero.fact_parametros (
    id_parametros serial PRIMARY KEY,   --This create a numeric serial id.
	parametro varchar(20),
    valor numeric,
    fecha_captura varchar(20),  -- import as text first to avoid automatic conversion
    limite_autoimpuesto numeric
);

ALTER TABLE album_financiero.fact_parametros
ALTER COLUMN fecha_captura TYPE DATE
USING TO_DATE(fecha_captura, 'DD/MM/YYYY');



--CSV015 fact_inversiones
CREATE TABLE album_financiero.fact_inversiones (
    id_inversiones serial PRIMARY KEY,   --This create a numeric serial id.
	tipo_inversion varchar(50),
    tipo_acceso varchar (20),
    fecha_monto varchar(20),  -- import as text first to avoid automatic conversion
    monto numeric
);

ALTER TABLE album_financiero.fact_inversiones
ALTER COLUMN fecha_monto TYPE DATE
USING TO_DATE(fecha_monto, 'DD/MM/YYYY');
--
ALTER TABLE album_financiero.fact_inversiones 
ADD COLUMN diferencia_mensual NUMERIC;

UPDATE album_financiero.fact_inversiones        AS fi
SET diferencia_mensual = sub.diferencia_mensual
FROM (
    SELECT 
        id_inversiones,
        monto - LAG(monto) OVER (
            PARTITION BY tipo_inversion
            ORDER BY fecha_monto
        )                                      AS diferencia_mensual
    FROM album_financiero.fact_inversiones
) sub
WHERE fi.id_inversiones = sub.id_inversiones;



--CSV016 dim_tipo_cambio
CREATE TABLE album_financiero.dim_tipo_cambio (
   	id_tipo_cambio serial PRIMARY KEY,   --This create a numeric serial id.
    fecha varchar(20),
    tipo_cambio numeric,
	moneda varchar(30)
);

ALTER TABLE album_financiero.dim_tipo_cambio
ALTER COLUMN fecha TYPE DATE
USING TO_DATE(fecha, 'DD/MM/YYYY');



--CSV017 dim_id_deuda
CREATE TABLE album_financiero.dim_id_deuda (
   	id_deuda varchar(10) PRIMARY KEY,
	descripcion varchar(70),
	fecha_inicio varchar(20),  -- import as text first to avoid automatic conversion
	finalizado varchar(10)
);

ALTER TABLE album_financiero.dim_id_deuda
ALTER COLUMN fecha_inicio TYPE DATE
USING TO_DATE(fecha_inicio, 'DD/MM/YYYY');



--CSV020 dim_id_viajes
CREATE TABLE album_financiero.dim_id_viajes (
   	id_viaje varchar(10) PRIMARY KEY,
	ubicacion_viajes varchar(50),
	descripcion varchar(100),
	grupo_viaje varchar(10),
	desde varchar(20),  -- import as text first to avoid automatic conversion
	hasta varchar(20),  -- import as text first to avoid automatic conversion
	viaje_principal varchar(50)
);

ALTER TABLE album_financiero.dim_id_viajes
ALTER COLUMN desde TYPE DATE
USING TO_DATE(desde, 'DD/MM/YYYY');

ALTER TABLE album_financiero.dim_id_viajes
ALTER COLUMN hasta TYPE DATE
USING TO_DATE(hasta, 'DD/MM/YYYY');




--CSV021 fact_c_diaria
CREATE TABLE album_financiero.fact_c_diaria (
    id varchar(10) PRIMARY KEY,
    fecha varchar(20),  -- import as text first to avoid automatic conversion
    razon_uso varchar(50),
    clave varchar(20),
    descripcion varchar(300),
    lugar_de_uso varchar(50),
    metodo_pago varchar(20),
    monto numeric,
    id_viaje varchar(10),
    id_deuda varchar(10)
);

ALTER TABLE album_financiero.fact_c_diaria
ALTER COLUMN fecha TYPE DATE
USING TO_DATE(fecha, 'DD/MM/YYYY');



--CSV022 fact_creditos
CREATE TABLE album_financiero.fact_creditos (
    id_creditos serial PRIMARY KEY,   --This create a numeric serial id.
	fecha_inicio varchar(20),  -- import as text first to avoid automatic conversion
    fecha_corte varchar(20),  -- import as text first to avoid automatic conversion
    fecha_limite_pago varchar(20),  -- import as text first to avoid automatic conversion
    listo_para_pago varchar(10)
);

ALTER TABLE album_financiero.fact_creditos
ALTER COLUMN fecha_inicio TYPE DATE
USING TO_DATE(fecha_inicio, 'DD/MM/YYYY');

ALTER TABLE album_financiero.fact_creditos
ALTER COLUMN fecha_corte TYPE DATE
USING TO_DATE(fecha_corte, 'DD/MM/YYYY');

ALTER TABLE album_financiero.fact_creditos
ALTER COLUMN fecha_limite_pago TYPE DATE
USING TO_DATE(fecha_limite_pago, 'DD/MM/YYYY');



--CSV023 fact_presupuesto
CREATE TABLE album_financiero.fact_presupuesto (
    id_presupuesto_mensual serial PRIMARY KEY,   --This create a numeric serial id.
	inicio_mes varchar(20),  -- import as text first to avoid automatic conversion
    final_mes varchar(20),  -- import as text first to avoid automatic conversion
    razon_uso varchar(20),
    descripcion varchar(300),
    monto_presupuesto numeric,
	id_presupuesto varchar(10)
);

ALTER TABLE album_financiero.fact_presupuesto
ALTER COLUMN inicio_mes TYPE DATE
USING TO_DATE(inicio_mes, 'DD/MM/YYYY');

ALTER TABLE album_financiero.fact_presupuesto
ALTER COLUMN final_mes TYPE DATE
USING TO_DATE(final_mes, 'DD/MM/YYYY');
--
SHOW DateStyle;      -- should be ISO, DMY
