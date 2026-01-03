-- The resulting datasets enable consistent budget vs. actual analysis across specific, regular, and monetary spending scenarios in Power BI.

-- The CSV015 script derives budget-related datasets by applying hierarchical matching rules to assign an id_presupuesto to eligible transactions 
-- and by expanding budget definitions into monthly analytical structures. 



--CSV001 ds_presupuesto_aplicado
CREATE MATERIALIZED VIEW album_financiero.v_ds_presupuesto_aplicado AS
SELECT DISTINCT cd.id,
cd.fecha,
cd.razon_uso,
cd.clave,
cd.descripcion,
cd.lugar_de_uso,
cd.monto,
cd.periodo_fact_c_diaria,
dru.tipo_razon_uso,
cd.id_viaje,
vi.grupo_viaje,
COALESCE(
hpe.comparativa_descripcion,
hpe.comparativa_grupo_viaje,
hpe.comparativa_clave_si,
hpe.comparativa_clave_no
       ) 											                         AS id_presupuesto
FROM album_financiero.fact_c_diaria                    AS cd
JOIN album_financiero.dim_razon_uso                    AS dru 
    ON cd.razon_uso = dru.razon_uso
LEFT JOIN album_financiero.ds_viaje_id                 AS vi 					        
    ON vi.id_viaje = cd.id_viaje
LEFT JOIN album_financiero.help_presupuesto_especifico AS hpe
	ON hpe.id = cd.id
WHERE dru.tipo_razon_uso <> 'dinero'
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_presupuesto_aplicado AS
SELECT id,
tipo_razon_uso,
grupo_viaje,
id_presupuesto
FROM album_financiero.v_ds_presupuesto_aplicado
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_presupuesto_aplicado
ON album_financiero.ds_presupuesto_aplicado (id);



--CSV015 help_presupuesto_especifico
CREATE MATERIALIZED VIEW album_financiero.help_presupuesto_especifico AS
SELECT
    cd.id,
    cd.fecha,
    cd.razon_uso,
    cd.clave,
    cd.descripcion,
    cd.lugar_de_uso,
    cd.monto,
    cd.periodo_fact_c_diaria,
    dru.tipo_razon_uso,
    cd.id_viaje,
    vi.grupo_viaje,
    descr_match.id_presupuesto                AS comparativa_descripcion,
    grp_match.id_presupuesto                  AS comparativa_grupo_viaje,
    razon_match.razon_uso                     AS comparativa_razon_uso,
    clave_si_match.id_presupuesto             AS comparativa_clave_si,
    clave_no_match.id_presupuesto             AS comparativa_clave_no
FROM album_financiero.fact_c_diaria           AS cd
JOIN album_financiero.dim_razon_uso           AS dru
    ON cd.razon_uso = dru.razon_uso
LEFT JOIN (
    SELECT DISTINCT ON (id_viaje)
           id_viaje,
           grupo_viaje
    FROM album_financiero.v_ds_viaje_id
    ORDER BY id_viaje
)                                             AS vi
    ON vi.id_viaje = cd.id_viaje
-- RULE 1: descripcion_c_diaria
LEFT JOIN LATERAL (
    SELECT dip.id_presupuesto
    FROM album_financiero.dim_id_presupuesto AS dip
    WHERE dip.descripcion_c_diaria IS NOT NULL
      AND dip.descripcion_c_diaria <> ''
      AND cd.descripcion ILIKE dip.descripcion_c_diaria || '%'
    ORDER BY length(dip.descripcion_c_diaria) DESC, dip.id_presupuesto
    LIMIT 1
)                                             AS descr_match ON TRUE
-- RULE 2: grupo_viaje
LEFT JOIN LATERAL (
    SELECT dip.id_presupuesto
    FROM album_financiero.dim_id_presupuesto AS dip
    WHERE descr_match.id_presupuesto IS NULL
      AND dip.grupo_viaje IS NOT NULL
      AND dip.grupo_viaje <> ''
      AND dip.grupo_viaje = vi.grupo_viaje
    LIMIT 1
)                                            AS grp_match ON TRUE
-- RULE 3: razon_uso
LEFT JOIN LATERAL (
    SELECT dip.razon_uso
    FROM album_financiero.dim_id_presupuesto AS dip
    WHERE descr_match.id_presupuesto IS NULL
      AND grp_match.id_presupuesto IS NULL
      AND dip.razon_uso = cd.razon_uso
    LIMIT 1
)                                            AS razon_match ON TRUE
-- RULE 4: clave_si  (clave informed in both tables)
LEFT JOIN LATERAL (
    SELECT dip.id_presupuesto
    FROM album_financiero.dim_id_presupuesto AS dip
    WHERE descr_match.id_presupuesto IS NULL
      AND grp_match.id_presupuesto IS NULL
      AND razon_match.razon_uso IS NOT NULL
      AND dip.clave IS NOT NULL
      AND dip.clave <> ''
      AND UPPER(TRIM(cd.clave)) = UPPER(TRIM(dip.clave))
      AND UPPER(TRIM(cd.razon_uso)) = UPPER(TRIM(dip.razon_uso))
    LIMIT 1
)                                            AS clave_si_match ON TRUE
-- RULE 5: clave_no (clave is empty in dim_id_presupuesto)
LEFT JOIN LATERAL (
    SELECT dip.id_presupuesto
    FROM album_financiero.dim_id_presupuesto AS dip
    WHERE descr_match.id_presupuesto IS NULL
      AND grp_match.id_presupuesto IS NULL
      AND clave_si_match.id_presupuesto IS NULL
      AND (dip.clave IS NULL OR dip.clave = '')
      AND UPPER(TRIM(cd.razon_uso)) = UPPER(TRIM(dip.razon_uso))
    LIMIT 1
)                                          AS clave_no_match ON TRUE
WHERE dru.tipo_razon_uso = 'especifico'
WITH NO DATA;



-- CSV025 ds_presupuesto_mensual_especifico
CREATE MATERIALIZED VIEW album_financiero.v_ds_presupuesto_mensual_especifico AS
SELECT pr.id_presupuesto_mensual,
pr.inicio_mes,
pr.final_mes,
pr.razon_uso,
pr.descripcion,
pr.monto_presupuesto,
pr.id_presupuesto,
dip.descripcion 								                AS descripcion_id,
dip.tipo 										                    AS tipo_id,
pr.periodo_inicio,
pr.periodo_final
FROM album_financiero.fact_presupuesto	 			  AS pr
JOIN album_financiero.dim_razon_uso  			      AS dru 
    ON pr.razon_uso = dru.razon_uso
LEFT JOIN album_financiero.dim_id_presupuesto   AS dip   
	ON pr.id_presupuesto = dip.id_presupuesto
WHERE dru.tipo_razon_uso = 'especifico'
WITH NO DATA;
--
CREATE MATERIALIZED VIEW album_financiero.ds_presupuesto_mensual_especifico AS
SELECT id_presupuesto_mensual,
descripcion_id,
tipo_id,
inicio_mes,
periodo_inicio
FROM album_financiero.v_ds_presupuesto_mensual_especifico
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_presupuesto_mensual_especifico
ON album_financiero.ds_presupuesto_mensual_especifico (id_presupuesto_mensual);



--CSV026 ds_presupuesto_mensual_regular_dinero
CREATE MATERIALIZED VIEW album_financiero.v_ds_presupuesto_mensual_regular_dinero AS
SELECT pr.id_presupuesto_mensual,
    gen.month_date                                 AS mes_regular_dinero,
    pr.razon_uso,
    pr.descripcion,
    pr.monto_presupuesto,
    dru.tipo_razon_uso,
    (EXTRACT(YEAR FROM gen.month_date)::INTEGER * 100 + 
    EXTRACT(MONTH FROM gen.month_date)::INTEGER)  AS periodo_mes
FROM album_financiero.fact_presupuesto            AS pr
JOIN album_financiero.dim_razon_uso               AS dru
      ON pr.razon_uso = dru.razon_uso
LEFT JOIN album_financiero.dim_id_presupuesto     AS dip
      ON pr.id_presupuesto = dip.id_presupuesto
JOIN LATERAL (
    SELECT date_trunc('month', dd)::date          AS month_date
    FROM generate_series(
        pr.inicio_mes,
        pr.final_mes,
        interval '1 month'
    ) AS dd
) gen ON TRUE
WHERE dru.tipo_razon_uso <> 'especifico'
WITH NO DATA;

--
CREATE MATERIALIZED VIEW album_financiero.ds_presupuesto_mensual_regular_dinero AS
SELECT ROW_NUMBER() OVER () AS id_mensual_regular_dinero,
id_presupuesto_mensual,
mes_regular_dinero,
monto_presupuesto,
periodo_mes,
tipo_razon_uso
FROM album_financiero.v_ds_presupuesto_mensual_regular_dinero
WITH NO DATA;

CREATE UNIQUE INDEX pk_ds_presupuesto_mensual_regular_dinero
ON album_financiero.ds_presupuesto_mensual_regular_dinero (id_mensual_regular_dinero);