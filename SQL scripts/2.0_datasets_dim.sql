-- This script generates dimension datasets that extract distinct business attributes, apply normalization and classification rules, 
-- and enrich them with derived fields when required. 
-- These datasets support consistent filtering, grouping, and relationships within the Power BI star schema.


--CSV004 dim_viajes_grupo
CREATE MATERIALIZED VIEW album_financiero.dim_viajes_grupo AS
SELECT 
    div.grupo_viaje,
    MAX(div.viaje_principal)            AS viaje_principal,
    dg.id_geografia,
    MIN(div.desde)                      AS primera_fecha,
    MAX(div.hasta)                      AS ultima_fecha,
    COUNT(*)                            AS veces_usado
FROM album_financiero.dim_id_viajes   AS div
JOIN album_financiero.dim_geografia   AS dg
    ON div.viaje_principal = dg.ubicacion_viajes
WHERE div.grupo_viaje IS NOT NULL
GROUP BY div.grupo_viaje,
   dg.id_geografia
ORDER BY div.grupo_viaje ASC
WITH NO DATA;

CREATE UNIQUE INDEX pk_dim_viajes_grupo
ON album_financiero.dim_viajes_grupo (grupo_viaje);



--CSV006 dim_tipo_inversion
CREATE MATERIALIZED VIEW album_financiero.dim_tipo_inversion AS
SELECT DISTINCT
    TRIM(tipo_inversion)            AS tipo_inversion,
    TRIM(tipo_acceso)               AS tipo_acceso 
FROM album_financiero.fact_inversiones
WHERE tipo_inversion IS NOT NULL;

CREATE UNIQUE INDEX idx_dim_tipo_inversion_pk
ON album_financiero.dim_tipo_inversion (tipo_inversion);




--CSV009 dim_razon_uso
CREATE MATERIALIZED VIEW album_financiero.dim_razon_uso AS
SELECT 
    DISTINCT razon_uso,
    CASE
        WHEN razon_uso LIKE 'P.%' THEN 'especifico'
        WHEN razon_uso ILIKE 'DINERO' OR razon_uso ILIKE 'INGRESO' THEN 'dinero'
        ELSE 'regular'
    END AS tipo_razon_uso
FROM album_financiero.fact_c_diaria
WHERE razon_uso IS NOT NULL
WITH NO DATA;

CREATE UNIQUE INDEX pk_dim_razon_uso
ON album_financiero.dim_razon_uso (razon_uso);



--CSV019  dim_nombre
CREATE MATERIALIZED VIEW album_financiero.dim_nombre AS
SELECT DISTINCT
    nombre,
    ( SELECT string_agg(
                   LEFT(word, 1) || RIGHT(word, 2),
                   '')
        FROM regexp_split_to_table(nombre, '\s+') AS word
    ) AS nombre_abr
FROM album_financiero.v_ds_nombre;
ORDER BY nombre ASC;

CREATE UNIQUE INDEX pk_dim_nombre
ON album_financiero.dim_nombre (nombre);



--CSV025  dim_metodo_pago_general
CREATE MATERIALIZED VIEW album_financiero.dim_metodo_pago_general AS
SELECT DISTINCT metodo_pago_general
FROM album_financiero.fact_c_diaria
WHERE metodo_pago_general IS NOT NULL;

CREATE UNIQUE INDEX pk_dim_metodo_pago_general
ON album_financiero.dim_metodo_pago_general (metodo_pago_general);



--CSV026  dim_categoria_movimiento
CREATE MATERIALIZED VIEW album_financiero.dim_categoria_movimiento AS
SELECT DISTINCT categoria_movimiento
FROM album_financiero.ds_inversiones_movimientos;

CREATE UNIQUE INDEX pk_dim_categoria_movimiento
ON album_financiero.dim_categoria_movimiento (categoria_movimiento);



--CSV028  dim_tipo_credito
CREATE MATERIALIZED VIEW album_financiero.dim_tipo_credito AS
SELECT DISTINCT tipo_credito
FROM album_financiero.ds_creditos_periodo;

CREATE UNIQUE INDEX pk_dim_tipo_credito
ON album_financiero.dim_tipo_credito (tipo_credito);



--CSV029  dim_deuda_nombre
CREATE MATERIALIZED VIEW album_financiero.dim_deuda_nombre AS
SELECT DISTINCT
    nombre_deudor,
    ( SELECT string_agg(
                   LEFT(word, 1) || RIGHT(word, 2),
                   '')
        FROM regexp_split_to_table(nombre_deudor, '\s+') AS word
    ) AS nombre_abr
FROM  album_financiero.v_ds_deuda_id
ORDER BY nombre_deudor ASC;

CREATE UNIQUE INDEX pk_dim_deuda_nombre
ON album_financiero.dim_deuda_nombre (nombre_deudor);



--CSV030  dim_nombre_clave
CREATE MATERIALIZED VIEW album_financiero.dim_nombre_clave AS
SELECT DISTINCT clave
FROM album_financiero.v_ds_nombre
ORDER BY clave ASC;

CREATE UNIQUE INDEX pk_dim_nombre_clave
ON album_financiero.dim_nombre_clave (clave);



--CSV032  dim_ingresos
CREATE MATERIALIZED VIEW album_financiero.dim_ingresos AS
SELECT DISTINCT tipo_ingreso
FROM album_financiero.v_ds_ingresos
ORDER BY tipo_ingreso ASC;

CREATE UNIQUE INDEX pk_dim_ingresos
ON album_financiero.dim_ingresos (tipo_ingreso);



--CSV033 dim_inversiones_movimientos
CREATE MATERIALIZED VIEW album_financiero.dim_inversiones_movimientos AS
SELECT DISTINCT tipo_inversion_detectado
FROM album_financiero.ds_inversiones_movimientos;

CREATE UNIQUE INDEX idx_dim_inversiones_movimientos_pk
ON album_financiero.dim_inversiones_movimientos (tipo_inversion_detectado);



--CSV035  dim_tipo_cambio_moneda
CREATE MATERIALIZED VIEW album_financiero.dim_tipo_cambio_moneda AS
SELECT DISTINCT moneda
FROM album_financiero.v_ds_viaje_tipo_cambio
ORDER BY moneda ASC;

CREATE UNIQUE INDEX pk_dim_ingresos
ON album_financiero.dim_tipo_cambio_monedas (moneda);



--CSV036 dim_clave
CREATE MATERIALIZED VIEW album_financiero.dim_clave AS
SELECT DISTINCT clave
FROM album_financiero.fact_c_diaria
WHERE clave IS NOT NULL
WITH NO DATA;

CREATE UNIQUE INDEX pk_dim_clave
ON album_financiero.dim_dim_clave (clave);



--CSV032  dim_canal_ingreso
CREATE MATERIALIZED VIEW album_financiero.dim_canal_ingreso AS
SELECT DISTINCT canal_ingreso
FROM album_financiero.v_ds_ingresos
ORDER BY canal_ingreso ASC;

CREATE UNIQUE INDEX pk_dim_canal_ingreso
ON album_financiero.dim_canal_ingreso (canal_ingreso);