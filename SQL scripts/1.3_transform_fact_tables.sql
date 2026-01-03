--This script enriches existing fact tables by adding derived columns such as period identifiers, normalized payment methods, and calculated metrics.
--These transformations prepare the data for analytical use and star-schema relationships in Power BI.


--CSV014 fact_parametros
ALTER TABLE album_financiero.fact_parametros 
ADD COLUMN periodo_parametros INTEGER;

UPDATE album_financiero.fact_parametros
SET periodo_parametros = EXTRACT(YEAR FROM fecha_captura)::INTEGER * 100 + EXTRACT(MONTH FROM fecha_captura)::INTEGER;



--CSV015  fact_inversiones
ALTER TABLE album_financiero.fact_inversiones 
ADD COLUMN periodo_inversiones INTEGER;

UPDATE album_financiero.fact_inversiones
SET periodo_inversiones = EXTRACT(YEAR FROM fecha_monto)::INTEGER * 100 + EXTRACT(MONTH FROM fecha_monto)::INTEGER;

ALTER TABLE album_financiero.fact_inversiones 
ADD COLUMN diferencia_mensual NUMERIC;

UPDATE album_financiero.fact_inversiones
SET diferencia_mensual = sub.diferencia_mensual
FROM (
    SELECT 
        id,
        monto - LAG(monto) OVER (
            PARTITION BY tipo_inversion
            ORDER BY fecha_monto
        ) AS diferencia_mensual
    FROM album_financiero.fact_inversiones
) sub
WHERE f.id = sub.id;



--CSV017  dim_id_deuda
ALTER TABLE album_financiero.dim_id_deuda
ADD COLUMN periodo_id_deuda INTEGER;

UPDATE album_financiero.dim_id_deuda
SET periodo_id_deuda = EXTRACT(YEAR FROM fecha_inicio)::INTEGER * 100 + EXTRACT(MONTH FROM fecha_inicio)::INTEGER;



-- CSV021  fact_c_diaria
ALTER TABLE album_financiero.fact_c_diaria
ADD COLUMN periodo_fact_c_diaria INTEGER;

UPDATE album_financiero.fact_c_diaria
SET periodo_fact_c_diaria = EXTRACT(YEAR FROM fecha)::INTEGER * 100 + EXTRACT(MONTH FROM fecha)::INTEGER;
--
ALTER TABLE album_financiero.fact_c_diaria
ADD COLUMN metodo_pago_general VARCHAR(20);

UPDATE album_financiero.fact_c_diaria
SET metodo_pago_general = CASE
    WHEN LOWER(metodo_pago) LIKE '%efectivo%' THEN 'efectivo'
    WHEN LOWER(metodo_pago) LIKE '%debito%'   THEN 'debito'
    WHEN LOWER(metodo_pago) LIKE '%credito%' THEN 'credito'
    ELSE 'otros'
END;



--CSV022  fact_creditos
ALTER TABLE album_financiero.fact_creditos
ADD COLUMN periodo_inicio INTEGER;

UPDATE album_financiero.fact_creditos
SET periodo_inicio = EXTRACT(YEAR FROM fecha_inicio)::INTEGER * 100 + EXTRACT(MONTH FROM fecha_inicio)::INTEGER;

ALTER TABLE album_financiero.fact_creditos
ADD COLUMN periodo_corte INTEGER;

UPDATE album_financiero.fact_creditos
SET periodo_corte = EXTRACT(YEAR FROM fecha_corte)::INTEGER * 100 + EXTRACT(MONTH FROM fecha_corte)::INTEGER;

ALTER TABLE album_financiero.fact_creditos
ADD COLUMN primer_dia_mes_corte DATE;

UPDATE album_financiero.fact_creditos
SET primer_dia_mes_corte = TO_DATE(periodo_corte::TEXT || '01', 'YYYYMMDD')

ALTER TABLE album_financiero.fact_creditos
ADD COLUMN periodo_limite_pago INTEGER;

UPDATE album_financiero.fact_creditos
SET periodo_limite_pago = EXTRACT(YEAR FROM fecha_limite_pago)::INTEGER * 100 + EXTRACT(MONTH FROM fecha_limite_pago)::INTEGER;
--
ALTER TABLE album_financiero.fact_creditos
ADD COLUMN metodo_pago_general VARCHAR(20);

UPDATE album_financiero.fact_creditos
SET metodo_pago_general = 'credito';



--CSV023  fact_presupuesto
ALTER TABLE album_financiero.fact_presupuesto
ADD COLUMN periodo_inicio INTEGER;

UPDATE album_financiero.fact_presupuesto
SET periodo_inicio = EXTRACT(YEAR FROM inicio_mes)::INTEGER * 100 + EXTRACT(MONTH FROM inicio_mes)::INTEGER;

ALTER TABLE album_financiero.fact_presupuesto
ADD COLUMN periodo_final INTEGER;

UPDATE album_financiero.fact_presupuesto
SET periodo_final = EXTRACT(YEAR FROM final_mes)::INTEGER * 100 + EXTRACT(MONTH FROM final_mes)::INTEGER;














