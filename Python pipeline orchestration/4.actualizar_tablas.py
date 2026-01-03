#This script truncates and reloads PostgreSQL fact and dimension tables using CSV files generated from Excel, ensuring a clean and consistent data state on each execution.
#Once the data is imported, all SQL functions and triggers defined in the database (Section 1.4) are automatically activated, 
# recalculating derived fields and preparing the data for downstream transformations.


import psycopg2
import os

# CSV file paths
CSV_FILES = {
    "fact_c_diaria": r"C:\Master Example\Master Example\Master Example\document",
    "fact_creditos": r"C:\Master Example\Master Example\Master Example\document",
    "fact_inversiones": r"C:\Master Example\Master Example\Master Example\document",
    "fact_presupuesto": r"C:\Master Example\Master Example\Master Example\document",
    "fact_parametros": r"C:\Master Example\Master Example\Master Example\document",
    "dim_geografia": r"C:\Master Example\Master Example\Master Example\document",
    "dim_id_deuda": r"C:\Master Example\Master Example\Master Example\document",
    "dim_id_presupuesto": r"C:\Master Example\Master Example\Master Example\document",
    "dim_id_viajes": r"C:\Master Example\Master Example\Master Example\document",
    "dim_tipo_cambio": r"C:\Master Example\Master Example\Master Example\document",
    "ds_viajes_url": r"C:\Master Example\Master Example\Master Example\document"
}

# PostgreSQL table targets
TABLES = {
    "fact_c_diaria": "album_financiero.fact_c_diaria",
    "fact_creditos": "album_financiero.fact_creditos",
    "fact_inversiones": "album_financiero.fact_inversiones",
    "fact_presupuesto": "album_financiero.fact_presupuesto",
    "fact_parametros": "album_financiero.fact_parametros",
    "dim_geografia": "album_financiero.dim_geografia",
    "dim_id_deuda": "album_financiero.dim_id_deuda",
    "dim_id_presupuesto": "album_financiero.dim_id_presupuesto",
    "dim_id_viajes": "album_financiero.dim_id_viajes",
    "dim_tipo_cambio": "album_financiero.dim_tipo_cambio",
    "ds_viajes_url": "album_financiero.ds_viajes_url"
}

# Columns to import for each CSV
CSV_COLUMNS = { 
    "fact_c_diaria": ["id", "fecha", "razon_uso", "clave", "descripcion", "lugar_de_uso", "metodo_pago", "monto", "id_viaje", "id_deuda"],
    "fact_creditos": ["fecha_inicio", "fecha_corte", "fecha_limite_pago", "listo_para_pago"],
    "fact_inversiones": ["tipo_inversion", "tipo_acceso", "fecha_monto", "monto"],
    "fact_presupuesto": ["inicio_mes", "final_mes", "razon_uso", "descripcion","monto_presupuesto","id_presupuesto"],
    "fact_parametros": ["parametro","valor","fecha_captura","limite_autoimpuesto"],
    "dim_geografia": ["ubicacion_viajes", "continente", "pais", "estado_region","moneda","latitud","longitud"],
    "dim_id_deuda": ["id_deuda", "descripcion", "fecha_inicio", "finalizado"],
    "dim_id_presupuesto": ["id_presupuesto", "concepto_principal", "tipo", "descripcion","grupo_viaje","razon_uso","clave","descripcion_c_diaria"],
    "dim_id_viajes": ["id_viaje", "ubicacion_viajes", "descripcion", "grupo_viaje","desde","hasta","viaje_principal"],
    "dim_tipo_cambio": ["fecha", "tipo_cambio", "moneda"],
    "ds_viajes_url": ["imagen_url", "id_viaje"]
}

def connect_db():
    """Creates and returns a PostgreSQL connection."""
    return psycopg2.connect(
            dbname="EXAMPLE",
            user="EXAMPLE",
            password="EXAMPLE",
            host="EXAMPLE",
            port="EXAMPLE"
    )

def load_csv_to_postgres(cursor, table_name, csv_path, column_list):
    """Loads a CSV file into PostgreSQL using COPY with explicit column list."""
    
    columns = ",".join(column_list)

    cursor.execute(f"TRUNCATE TABLE {table_name} RESTART IDENTITY;")

    with open(csv_path, "r", encoding="utf-8") as f:
        cursor.copy_expert(
            f"COPY {table_name} ({columns}) FROM STDIN WITH CSV HEADER",
            f
        )
    print(f" CSV cargado en {table_name}: {csv_path}")


if __name__ == "__main__":
    print("Comenzando la importación del CSV a PostgreSQL")

    conn = connect_db()
    cursor = conn.cursor()

    for key, csv_path in CSV_FILES.items():
        table = TABLES[key]
        columns = CSV_COLUMNS[key]

        if os.path.exists(csv_path):
            load_csv_to_postgres(cursor, table, csv_path, columns)
        else:
            print(f"⚠ Documento CSV no encontrado: {csv_path}")

    conn.commit()
    cursor.close()
    conn.close()

    print("Importación a PostgreSQL completada con éxito.")
