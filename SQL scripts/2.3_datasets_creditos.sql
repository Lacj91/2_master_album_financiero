-- This script creates datasets that link credit-based transactions to their active credit line and cutoff period based on transaction date. 
-- It classifies each movement as spending or deposit and derives the billing month start, supporting accurate credit usage analysis in Power BI.


--CSV011 ds_creditos_periodo
CREATE MATERIALIZED VIEW album_financiero.v_ds_creditos_periodo AS
SELECT cd.id,
cd.fecha,
cd.razon_uso,
cd.clave,
cd.descripcion,
cd.lugar_de_uso,
cd.metodo_pago,
cd.monto,
cr.id_creditos,
cr.periodo_inicio,
cr.periodo_corte,
TO_DATE(periodo_corte::TEXT || '01', 'YYYYMMDD')        AS primer_dia_mes_corte,
CASE
    WHEN monto < 0 THEN 'gasto'
    WHEN monto > 0 THEN 'deposito'
    ELSE NULL
END                                                     AS tipo_credito
FROM album_financiero.fact_c_diaria 				    AS cd
JOIN album_financiero.dim_metodo_pago_general   		AS dmp
    ON cd.metodo_pago_general = dmp.metodo_pago_general
JOIN album_financiero.fact_creditos 					AS cr
    ON dmp.metodo_pago_general = cr.metodo_pago_general
    AND cd.fecha BETWEEN cr.fecha_inicio AND cr.fecha_corte
WHERE cd.metodo_pago_general = 'credito'
WITH NO DATA;  -- ✔ optional: prevents initial load until you run REFRESH
--
CREATE MATERIALIZED VIEW album_financiero.ds_creditos_periodo AS
SELECT 
    id,
    id_creditos,
    periodo_inicio,
    periodo_corte,
    tipo_credito,
    primer_dia_mes_corte
FROM album_financiero.v_ds_creditos_periodo
WITH NO DATA;  -- ✔ optional: prevents initial load until you run REFRESH

CREATE UNIQUE INDEX pk_ds_creditos_periodo
ON album_financiero.ds_creditos_periodo (id);