-- This script generates datasets that classify income transactions by category and source, and investment movements by detected investment type and action. 
-- It also derives an investment impact dataset that separates monthly balance changes into movement-driven effects and market-driven performance for accurate investment analysis in Power BI.


-- CSV007  ds_inversiones_movimientos
CREATE MATERIALIZED VIEW album_financiero.v_ds_inversiones_movimientos AS
SELECT cd.id,
cd.fecha,
cd.descripcion,
cd.monto,
dti.tipo_inversion				            AS tipo_inversion_detectado,
CASE 
	WHEN cd.monto < 0 THEN 'deposito'
	WHEN cd.monto > 0 THEN 'retiro'
	ELSE NULL
	END 						            AS categoria_movimiento,
cd.periodo_fact_c_diaria,
cd.clave    
FROM album_financiero.fact_c_diaria 		AS cd
JOIN album_financiero.dim_tipo_inversion 	AS dti
    ON cd.descripcion ILIKE '%' || dti.tipo_inversion || '%'
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_inversiones_movimientos AS
SELECT id,
clave,
tipo_inversion_detectado,
categoria_movimiento
FROM album_financiero.v_ds_inversiones_movimientos
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_inversiones_movimientos
ON album_financiero.ds_inversiones_movimientos (id);



-- CSV031  ds_ingresos
CREATE MATERIALIZED VIEW album_financiero.v_ds_ingresos AS
SELECT id,
fecha,
clave,
descripcion,
monto,
CASE 
	WHEN monto < 0 THEN 'Egreso'
	WHEN monto > 0 THEN 'Ingreso'
	ELSE NULL
	END 						            AS categoria_ingreso,
CASE
    WHEN descripcion ILIKE '%puntos premia%' THEN 'Monedero'
    WHEN clave = 'inversion' AND descripcion ILIKE '%Ahorro%' THEN 'Ahorro'
	WHEN clave = 'comercio' THEN 'Comercio'
    WHEN clave = 'inversion' THEN 'Trabajo'
	WHEN clave = 'transaccion' THEN 'Ingreso'
	ELSE 'Otros'
    END 								   AS tipo_ingreso,
periodo_fact_c_diaria
FROM album_financiero.fact_c_diaria		   AS cd
WHERE razon_uso = 'INGRESO'
OR (razon_uso = 'P.FORMAL' AND clave = 'transaccion')
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_ingresos AS
SELECT id,
categoria_ingreso,
tipo_ingreso
FROM album_financiero.v_ds_ingresos
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_ingresos
ON album_financiero.ds_ingresos (id);



-- CSV034  ds_inversiones_impacto
CREATE MATERIALIZED VIEW album_financiero.v_ds_inversiones_impacto AS
WITH snapshots AS (
    SELECT
        fi.id_inversiones,
        fi.tipo_inversion,
        fi.fecha_monto,
        fi.monto,
        fi.diferencia_mensual,
        LAG(fi.fecha_monto) OVER (
            PARTITION BY fi.tipo_inversion
            ORDER BY fi.fecha_monto
        ) AS fecha_snapshot_anterior,
        LAG(fi.monto) OVER (
            PARTITION BY fi.tipo_inversion
            ORDER BY fi.fecha_monto
        ) AS monto_anterior
    FROM album_financiero.fact_inversiones AS fi
),
impacto_movimientos AS (
    SELECT
        s.id_inversiones,
        CASE
            WHEN s.fecha_snapshot_anterior IS NULL THEN 0
            ELSE COALESCE(SUM(-m.monto), 0)
        END AS impacto_por_movimiento
    FROM snapshots AS s
    LEFT JOIN album_financiero.v_ds_inversiones_movimientos m
        ON m.tipo_inversion_detectado = s.tipo_inversion
       AND m.fecha > s.fecha_snapshot_anterior
       AND m.fecha <= s.fecha_monto
    GROUP BY
        s.id_inversiones,
        s.fecha_snapshot_anterior
)
SELECT
    s.id_inversiones,
    s.fecha_monto,
    DATE_TRUNC('month', s.fecha_monto)::date            AS primer_dia_mes_inversiones,
    s.tipo_inversion,
    s.monto,
    COALESCE(s.monto_anterior, s.monto)                 AS balance_inicial,
    s.diferencia_mensual,
    im.impacto_por_movimiento,
    (s.diferencia_mensual - im.impacto_por_movimiento)  AS impacto_mercado
FROM snapshots AS s
LEFT JOIN impacto_movimientos AS im
    ON im.id_inversiones = s.id_inversiones
ORDER BY
    s.tipo_inversion,
    s.fecha_monto;
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_inversiones_impacto AS
SELECT id_inversiones,
primer_dia_mes_inversiones,
balance_inicial,
impacto_por_movimiento,
impacto_mercado
FROM album_financiero.v_ds_inversiones_impacto
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_inversiones_impacto
ON album_financiero.ds_inversiones_impacto (id_inversiones);