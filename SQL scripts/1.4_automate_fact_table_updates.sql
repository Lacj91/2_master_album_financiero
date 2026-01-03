-- This script defines trigger functions that automatically recompute derived columns such as period keys, classifications, 
-- and calculated metrics during insert and update operations.
-- This approach ensures data consistency after CSV reloads without requiring manual post-import transformations.

-- In PostgreSQL, a trigger defines when an automatic action should occur (for example, before an insert or update on a table), 
-- while a trigger function defines what logic is executed when that event happens.
-- Together, they allow derived fields to be recalculated automatically at the data layer whenever source data changes.


--CSV014 fact_parametros
CREATE OR REPLACE FUNCTION trg_fact_parametros_updates()
RETURNS TRIGGER AS $$
BEGIN
  NEW.periodo_parametros :=
    EXTRACT(YEAR FROM NEW.fecha_captura)::INTEGER * 100 +
    EXTRACT(MONTH FROM NEW.fecha_captura)::INTEGER;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER trg_fact_parametros_updates
BEFORE INSERT OR UPDATE ON album_financiero.fact_parametros
FOR EACH ROW
EXECUTE FUNCTION trg_fact_parametros_updates();



--CSV015  fact_inversiones
CREATE OR REPLACE FUNCTION trg_fact_inversiones_updates()
RETURNS TRIGGER AS $$
DECLARE
    prev_monto NUMERIC;
BEGIN
    NEW.periodo_inversiones :=
        EXTRACT(YEAR FROM NEW.fecha_monto)::INTEGER * 100 +
        EXTRACT(MONTH FROM NEW.fecha_monto)::INTEGER;

    SELECT monto
    INTO prev_monto
    FROM album_financiero.fact_inversiones
    WHERE tipo_inversion = NEW.tipo_inversion
      AND fecha_monto < NEW.fecha_monto
    ORDER BY fecha_monto DESC
    LIMIT 1;

    IF prev_monto IS NULL THEN
        NEW.diferencia_mensual := NULL;
    ELSE
        NEW.diferencia_mensual := NEW.monto - prev_monto;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER trg_fact_inversiones_before_ins_upd
BEFORE INSERT OR UPDATE ON album_financiero.fact_inversiones
FOR EACH ROW
EXECUTE FUNCTION trg_fact_inversiones_updates();



--CSV017  dim_id_deuda
CREATE OR REPLACE FUNCTION trg_dim_id_deuda_updates()
RETURNS TRIGGER AS $$
BEGIN
  NEW.periodo_id_deuda :=
    EXTRACT(YEAR FROM NEW.fecha_inicio)::INTEGER * 100 +
    EXTRACT(MONTH FROM NEW.fecha_inicio)::INTEGER;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER trg_dim_id_deuda_updates
BEFORE INSERT OR UPDATE ON album_financiero.dim_id_deuda
FOR EACH ROW
EXECUTE FUNCTION trg_dim_id_deuda_updates();



-- CSV021 fact_c_diaria
CREATE OR REPLACE FUNCTION trg_fact_c_diaria_updates()
RETURNS TRIGGER AS $$
BEGIN
    NEW.periodo_fact_c_diaria :=
        EXTRACT(YEAR FROM NEW.fecha)::INTEGER * 100 +
        EXTRACT(MONTH FROM NEW.fecha)::INTEGER;

    NEW.metodo_pago_general :=
        CASE
            WHEN LOWER(NEW.metodo_pago) LIKE '%efectivo%' THEN 'efectivo'
            WHEN LOWER(NEW.metodo_pago) LIKE '%debito%'   THEN 'debito'
            WHEN LOWER(NEW.metodo_pago) LIKE '%credito%' THEN 'credito'
            ELSE 'otros'
        END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER trg_fact_c_diaria_update
BEFORE INSERT OR UPDATE ON album_financiero.fact_c_diaria
FOR EACH ROW
EXECUTE FUNCTION trg_fact_c_diaria_updates();
--If the table is not updated and want to see if the function and trigger works.
UPDATE album_financiero.fact_c_diaria   
SET fecha = fecha;



--CSV022  fact_creditos
CREATE OR REPLACE FUNCTION trg_fact_creditos_updates()
RETURNS TRIGGER AS $$
BEGIN
  -- periodo_inicio
  NEW.periodo_inicio :=
    EXTRACT(YEAR FROM NEW.fecha_inicio)::INTEGER * 100 +
    EXTRACT(MONTH FROM NEW.fecha_inicio)::INTEGER;

  -- periodo_corte
  NEW.periodo_corte :=
    EXTRACT(YEAR FROM NEW.fecha_corte)::INTEGER * 100 +
    EXTRACT(MONTH FROM NEW.fecha_corte)::INTEGER;

  -- primer_dia_mes_corte (YYYYMM01 as date)
  NEW.primer_dia_mes_corte :=
    TO_DATE(NEW.periodo_corte::TEXT || '01', 'YYYYMMDD');

  -- periodo_limite_pago
  NEW.periodo_limite_pago :=
    EXTRACT(YEAR FROM NEW.fecha_limite_pago)::INTEGER * 100 +
    EXTRACT(MONTH FROM NEW.fecha_limite_pago)::INTEGER;

  -- metodo_pago_general is always "credito"
  NEW.metodo_pago_general := 'credito';

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER trg_fact_creditos_updates
BEFORE INSERT OR UPDATE ON album_financiero.fact_creditos
FOR EACH ROW
EXECUTE FUNCTION trg_fact_creditos_updates();



--CSV023  fact_presupuesto
CREATE OR REPLACE FUNCTION trg_fact_presupuesto_updates()
RETURNS TRIGGER AS $$
BEGIN
    NEW.periodo_inicio :=
      EXTRACT(YEAR FROM NEW.inicio_mes)::INTEGER * 100 +
      EXTRACT(MONTH FROM NEW.inicio_mes)::INTEGER;

    NEW.periodo_final :=
      EXTRACT(YEAR FROM NEW.final_mes)::INTEGER * 100 +
      EXTRACT(MONTH FROM NEW.final_mes)::INTEGER;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER trg_fact_presupuesto_update
BEFORE INSERT OR UPDATE ON album_financiero.fact_presupuesto
FOR EACH ROW
EXECUTE FUNCTION trg_fact_presupuesto_updates();