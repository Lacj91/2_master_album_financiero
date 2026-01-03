-- This script creates the album_financiero schema and assigns ownership to support centralized data modeling.
-- Existing tables are migrated from the public schema into this schema and validated using information_schema.


CREATE DATABASE album_financiero_bd;
--
CREATE SCHEMA album_financiero
    AUTHORIZATION postgres;



ALTER TABLE public.c_diaria SET SCHEMA album_financiero;
ALTER TABLE public.creditos SET SCHEMA album_financiero;
ALTER TABLE public.inversiones SET SCHEMA album_financiero;
ALTER TABLE public.parametros SET SCHEMA album_financiero;
ALTER TABLE public.presupuesto SET SCHEMA album_financiero;
ALTER TABLE public.tabla_geografia SET SCHEMA album_financiero;
ALTER TABLE public.tabla_id_deuda SET SCHEMA album_financiero;
ALTER TABLE public.tabla_id_presupuesto SET SCHEMA album_financiero;
ALTER TABLE public.tabla_id_viajes SET SCHEMA album_financiero;
--
ALTER TABLE public.creditos SET SCHEMA album_financiero; --adapting the name of the table, creates the schema inside of each databases.



SELECT table_schema, table_name  --Checks if the tables appears in album_financiero
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;