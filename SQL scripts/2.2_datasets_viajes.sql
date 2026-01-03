-- This script creates datasets that identify transactions associated with travels using id_viaje and consolidate them by travel group for analytical consistency. 
-- It also assigns the applicable historical exchange rate per transaction, enabling accurate normalization of travel expenses into local currency for reporting in Power BI.


--CSV003 ds_viaje_id
CREATE MATERIALIZED VIEW album_financiero.v_ds_viaje_id AS
SELECT cd.id,
cd.fecha,
cd.razon_uso,
cd.clave,
cd.descripcion,
cd.lugar_de_uso,
cd.monto,
cd.id_viaje,
dvg.grupo_viaje,
cd.periodo_fact_c_diaria
FROM album_financiero.fact_c_diaria     AS cd
JOIN album_financiero.dim_id_viajes     AS div
    ON cd.id_viaje = div.id_viaje
JOIN album_financiero.dim_viajes_grupo  AS dvg
    ON div.grupo_viaje = dvg.grupo_viaje
WHERE cd.id_viaje IS NOT NULL
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_viaje_id AS
SELECT id,
id_viaje,
grupo_viaje
FROM album_financiero.v_ds_viaje_id
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_viaje_id
ON album_financiero.ds_viaje_id (id);



--CSV005 ds_viaje_tipo_cambio
CREATE MATERIALIZED VIEW album_financiero.v_ds_viaje_tipo_cambio AS
SELECT
    vi.id,
    vi.fecha,
    vi.clave,
    vi.descripcion,
    vi.lugar_de_uso,
    vi.monto,
    vi.id_viaje,
    dg.moneda,
    dtc.tipo_cambio,
    vi.periodo_fact_c_diaria
FROM album_financiero.v_ds_viaje_id                     AS vi
JOIN album_financiero.dim_id_viajes                     AS div
    ON vi.id_viaje = div.id_viaje
JOIN album_financiero.dim_geografia                     AS dg
    ON div.ubicacion_viajes = dg.ubicacion_viajes
LEFT JOIN LATERAL (                                             -- 🔹 This is the key part:
    SELECT tipo_cambio
    FROM album_financiero.dim_tipo_cambio               AS dtc
    WHERE dtc.moneda = dg.moneda
      AND dtc.fecha <= vi.fecha
    ORDER BY dtc.fecha DESC
    LIMIT 1
) AS dtc ON TRUE
WHERE dg.moneda <> 'Peso Mexicano'
WITH NO DATA;

--
CREATE MATERIALIZED VIEW album_financiero.ds_viaje_tipo_cambio AS
SELECT id,
id_viaje,
moneda,
tipo_cambio
FROM album_financiero.v_ds_viaje_tipo_cambio
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_viaje_tipo_cambio
ON album_financiero.ds_viaje_tipo_cambio (id);



-- CSV010 ds_viajes_url
CREATE TABLE album_financiero.ds_viajes_url (
   	imagen_url varchar(400),
    id_viaje varchar(10) PRIMARY KEY
);