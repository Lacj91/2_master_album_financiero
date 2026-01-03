-- This script creates the initial PostgreSQL databases used across the project, separating major functional domains such as transactions, 
-- budgets, travels, credits, and investments.
-- A later rename from deudas to creditos was applied to correct domain terminology.


CREATE DATABASE c_diaria;
CREATE DATABASE presupuesto;
CREATE DATABASE viajes;
CREATE DATABASE deudas;
CREATE DATABASE inversiones;
CREATE DATABASE parametros;
CREATE DATABASE tabla_geografia;
CREATE DATABASE tabla_id_viajes;
CREATE DATABASE tabla_id_deuda;
CREATE DATABASE tabla_id_presupuesto;

ALTER DATABASE deudas RENAME TO creditos; --renamed the wrongly created deudas table to creditos