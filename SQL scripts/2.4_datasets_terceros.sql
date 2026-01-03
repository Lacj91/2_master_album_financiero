-- This script derives third-party datasets by parsing transaction descriptions to extract counterparty names using a standardized delimiter 
-- colon (:) in the descripcion column of the fact_c_diaria table.
-- It also generates a dedicated debt dataset that links transactions to debt identifiers and periods, enabling third-party and debt-level analysis in Power BI.

-- CSV002 ds_nombre
CREATE MATERIALIZED VIEW album_financiero.v_ds_nombre AS
SELECT *
FROM (
    SELECT 
        cd.id,
        cd.fecha,
		cd.razon_uso,
        cd.clave,
		cd.descripcion,
		cd.lugar_de_uso,
		cd.monto,
		cd.periodo_fact_c_diaria,
        CASE
            WHEN cd.descripcion LIKE '%:%' 
                THEN TRIM(RIGHT(cd.descripcion, LENGTH(cd.descripcion) - POSITION(':' IN cd.descripcion)))
            ELSE 'Varios'
        END 						   AS nombre
    FROM album_financiero.fact_c_diaria AS cd
    WHERE cd.clave <> 'deuda'
) t
WHERE t.nombre <> 'Varios'
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_nombre AS
SELECT 
    id,
    clave,
	nombre
FROM album_financiero.v_ds_nombre
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_nombre
ON album_financiero.ds_nombre (id);



--CSV018 ds_deuda_id
CREATE MATERIALIZED VIEW album_financiero.v_ds_deuda_id AS 
SELECT cd.id,
cd.fecha,
cd.razon_uso,
cd.descripcion,
cd.lugar_de_uso,
cd.monto,
cd.id_deuda,
cd.periodo_fact_c_diaria,
CASE
	WHEN cd.descripcion LIKE '%:%' 
	THEN TRIM(RIGHT(cd.descripcion, LENGTH(cd.descripcion) - POSITION(':' IN cd.descripcion)))
    ELSE 'Varios'
END 									AS nombre_deudor,
tid.periodo_id_deuda
FROM album_financiero.fact_c_diaria 	AS cd
JOIN album_financiero.dim_id_deuda 	    AS tid
	ON cd.id_deuda = tid.id_deuda 
WHERE cd.id_deuda IS NOT NULL
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_deuda_id AS
SELECT id,
id_deuda,
nombre_deudor,
periodo_id_deuda
FROM album_financiero.v_ds_deuda_id
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_deuda_id
ON album_financiero.ds_deuda_id (id);