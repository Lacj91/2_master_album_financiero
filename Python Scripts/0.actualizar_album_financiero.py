# This executable consolidates all backend automation steps into a single controlled workflow: detecting changes in travel images, regenerating reference CSV files, 
# exporting Excel data to clean CSVs, loading them into PostgreSQL tables, and refreshing all analytical materialized views.
# The unified version was intentionally implemented as a single script for the EXE build after encountering recursive execution issues 
# when chaining separate scripts, ensuring deterministic execution order and operational stability.
# As a result, the entire analytical backend can be refreshed with a single click, leaving all datasets ready for Power BI consumption.


import hashlib
import pandas as pd
import re
import subprocess
from pathlib import Path
import os
from openpyxl import load_workbook
import warnings
import psycopg2

warnings.filterwarnings("ignore", category=UserWarning, module="openpyxl")

# -------------------------
# Paths for first script
# -------------------------
REPO_PATH = r"C:\EXAMPLE\EXAMPLE\EXAMPLE"
CSV_OUTPUT = r"C:\EXAMPLE\EXAMPLE\EXAMPLE.csv"
BASE_URL = "https://example.com/example"
HASH_FILE = os.path.join(REPO_PATH, "_local_image_hashes.txt")

# -------------------------
# Paths for second script
# -------------------------
MASTER_FILE = r"C:\EXAMPLE\EXAMPLE\EXAMPLE.xlsx"
REFERENCE_FILES = {
    "tabla_geografia": r"C:\EXAMPLE\EXAMPLE\EXAMPLE.xlsx",
    "tabla_id_deuda": r"C:\EXAMPLE\EXAMPLE\EXAMPLE.xlsx",
    "tabla_id_presupuesto": r"C:\EXAMPLE\EXAMPLE\EXAMPLE.xlsx",
    "tabla_id_viajes": r"C:\EXAMPLE\EXAMPLE\EXAMPLE.xlsx",
}
OUTPUT_FOLDER = r"C:\EXAMPLE\EXAMPLE\EXAMPLE"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)
MASTER_SHEETS = ["c_diaria", "presupuesto", "inversiones", "creditos", "parametros"]

DATE_COLUMNS = {
    "c_diaria": ["fecha"],
    "presupuesto": ["inicio_mes", "final_mes"],
    "inversiones": ["fecha_monto"],
    "creditos": ["fecha_inicio", "fecha_corte", "fecha_limite_pago"],
    "parametros": ["fecha_compra"],
    "tabla_deuda": ["fecha_inicio"],
    "tabla_id_viajes": ["desde", "hasta"],
}

CURRENCY_COLUMNS = {
    "c_diaria": ["monto"],
    "presupuesto": ["monto_presupuesto"],
    "inversiones": ["monto"]
}

DROP_COLUMNS = {
    "c_diaria": [
        "m.extranjera",
        "moneda",
        "cantidad",
        "peso/um"
    ]
}

# -------------------------
# PostgreSQL CSV info (third script)
# -------------------------
CSV_FILES = {
    "fact_c_diaria": os.path.join(OUTPUT_FOLDER,"c_diaria.csv"),
    "fact_creditos": os.path.join(OUTPUT_FOLDER,"creditos.csv"),
    "fact_inversiones": os.path.join(OUTPUT_FOLDER,"inversiones.csv"),
    "fact_presupuesto": os.path.join(OUTPUT_FOLDER,"presupuesto.csv"),
    "fact_parametros": os.path.join(OUTPUT_FOLDER,"parametros.csv"),
    "dim_geografia": os.path.join(OUTPUT_FOLDER,"tabla_geografia.csv"),
    "dim_id_deuda": os.path.join(OUTPUT_FOLDER,"tabla_id_deuda.csv"),
    "dim_id_presupuesto": os.path.join(OUTPUT_FOLDER,"tabla_id_presupuesto.csv"),
    "dim_id_viajes": os.path.join(OUTPUT_FOLDER,"tabla_id_viajes.csv"),
    "dim_tipo_cambio": r"C:\EXAMPLE\EXAMPLE\EXAMPLE.csv",
    "ds_viajes_url": CSV_OUTPUT
}

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

# -------------------------
# Functions for first script
# -------------------------
def file_hash(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        h.update(f.read())
    return h.hexdigest()

def load_previous_hashes():
    if not os.path.exists(HASH_FILE):
        return {}
    hashes = {}
    with open(HASH_FILE, "r", encoding="utf-8") as f:
        for line in f:
            name, h = line.strip().split("|")
            hashes[name] = h
    return hashes

def save_hashes(hash_dict):
    with open(HASH_FILE, "w", encoding="utf-8") as f:
        for name, h in hash_dict.items():
            f.write(f"{name}|{h}\n")

def run_git(cmd, message):
    print(message)
    result = subprocess.run(cmd, cwd=REPO_PATH, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        print("Error ejecutando:", cmd)
    return result

def update_viajes_csv():
    print("Escaneando carpeta powerbi_viajes...")

    files = [f for f in os.listdir(REPO_PATH) if f.lower().endswith((".jpg", ".jpeg"))]
    current_hashes = {f: file_hash(os.path.join(REPO_PATH, f)) for f in files}
    previous_hashes = load_previous_hashes()

    if current_hashes == previous_hashes:
        print("✓ No se detectaron cambios en carpeta powerbi_viajes. Se prosigue al siguiente paso.")
        return  # skip regeneration

    print("Se detectaron cambios en powerbi_viajes. Regenerando archivo viajes_url.csv...")
    image_urls = [BASE_URL + f for f in files]
    df = pd.DataFrame({"image_url": image_urls})
    df["id_viaje"] = df["image_url"].str.extract(r"/(V\d+)\.(?:jpg|jpeg)$", flags=re.IGNORECASE)
    df.to_csv(CSV_OUTPUT, index=False)
    print("Archivo viajes_url.csv actualizado con éxito.")
    save_hashes(current_hashes)
    print("Hashes actualizados para detección futura de cambios.")

    print("Subiendo cambios al repositorio ...")
    run_git("git add .", "Añadiendo archivos al commit...")
    run_git('git commit -m "Auto-update viajes_url.csv and images"', "Creando commit automático...")
    run_git("git push", "Enviando cambios al repositorio...")
    print("✓ Actualizacion de carpeta powerbi_viajes completada con éxito.")

# -------------------------
# Functions for second script
# -------------------------
def load_excel_sheet_as_df(path, sheet_name):
    wb = load_workbook(path, data_only=True)
    ws = wb[sheet_name]
    data = list(ws.values)
    header = data[0]
    rows = data[1:]
    df = pd.DataFrame(rows, columns=header)
    return df

def format_date_columns(df, sheet_name):
    if sheet_name not in DATE_COLUMNS:
        return df
    for col in DATE_COLUMNS[sheet_name]:
        if col in df.columns:
            try:
                df[col] = pd.to_datetime(df[col], errors="coerce", dayfirst=True)
                df[col] = df[col].dt.strftime("%d/%m/%Y")
            except Exception:
                pass
    return df

def clean_currency_columns(df, sheet_name):
    if sheet_name not in CURRENCY_COLUMNS:
        return df
    for col in CURRENCY_COLUMNS[sheet_name]:
        if col in df.columns:
            df[col] = df[col].astype(str).str.replace("$","",regex=False).str.replace(",","",regex=False)
    return df

def clean_text_columns(df):
    for col in df.columns:
        if df[col].dtype == object:
            df[col] = df[col].astype(str).str.replace('"',"",regex=False).str.replace(",","",regex=False).str.strip()
    return df

def export_dataframe(df, name):
    output_path = os.path.join(OUTPUT_FOLDER, f"{name}.csv")
    df.to_csv(output_path, index=False, encoding="utf-8")
    print(f" Exportado: {output_path}")

def export_master_and_reference():
    # --- Export master sheets ---
    for sheet in MASTER_SHEETS:
        print(f"Procesando hoja: {sheet}")
        df = load_excel_sheet_as_df(MASTER_FILE, sheet)
        df = df.where(pd.notnull(df), "")
        if sheet in DROP_COLUMNS:
            df = df.drop(columns=DROP_COLUMNS[sheet], errors="ignore")
        df = format_date_columns(df, sheet)
        df = clean_currency_columns(df, sheet)
        df = clean_text_columns(df)
        df = df.fillna("")
        export_dataframe(df, sheet)

    # --- Export reference tables ---
    for name, path in REFERENCE_FILES.items():
        print(f"Procesando tabla de referencia: {name}")
        df = load_excel_sheet_as_df(path, name)
        df = df.where(pd.notnull(df), "")
        df = format_date_columns(df, name)
        df = clean_text_columns(df)
        df = df.fillna("")
        export_dataframe(df, name)

    print("✓ Todos los documentos CSV fueron descargados con éxito.")

# -------------------------
# Functions for PostgreSQL import (third script)
# -------------------------
def connect_db():
    """Creates and returns a PostgreSQL connection."""
    return psycopg2.connect(
        host="EXAMPLE",
        database="EXAMPLE",
        user="EXAMPLE",
        password="EXAMPLE",
        port="EXAMPLE"
    )

def load_csv_to_postgres(cursor, table_name, csv_path, column_list):
    """Loads a CSV file into PostgreSQL using COPY with explicit column list."""
    columns = ",".join(column_list)
    cursor.execute(f"TRUNCATE TABLE {table_name} RESTART IDENTITY;")
    with open(csv_path, "r", encoding="utf-8") as f:
        cursor.copy_expert(f"COPY {table_name} ({columns}) FROM STDIN WITH CSV HEADER", f)
    print(f" CSV cargado en {table_name}: {csv_path}")

def import_csv_to_postgres():
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

# -------------------------
# Functions for refreshing materialized views (fourth script)
# -------------------------
def refresh_all_mviews():
    print("Iniciando conexión a la base de datos...")
    try:
        conn = psycopg2.connect(
            dbname="EXAMPLE",
            user="EXAMPLE",
            password="EXAMPLE",
            host="EXAMPLE",
            port="EXAMPLE"
        )
        cursor = conn.cursor()
        print(" Conexión establecida.")

        cursor.execute("""
            SELECT matviewname
            FROM pg_matviews
            WHERE schemaname = 'album_financiero';
        """)

        mviews = [row[0] for row in cursor.fetchall()]

        if not mviews:
            print("No hay tablas MATERIALIZED VIEWS en el esquema.")
            return

        print(f"Se encontraron {len(mviews)} MATERIALIZED VIEWS.")

        mviews_ordenadas = sorted(
            mviews,
            key=lambda mv: (
                0 if mv.startswith("v_ds_") else
                1 if mv.startswith("ds_") else
                2
            )
        )

        print("Orden de refresco:")
        for mv in mviews_ordenadas:
            print("   •", mv)

        print("\nIniciando REFRESH...\n")

        for mv in mviews_ordenadas:
            full_name = f"album_financiero.{mv}"
            try:
                cursor.execute(f"REFRESH MATERIALIZED VIEW {full_name};")
                conn.commit()
                print(f"    {full_name} actualizado.\n")
            except Exception as e:
                print(f"    Error en {full_name}: {e}")
                conn.rollback()

        print("Todas las tablas MATERIALIZED VIEW han sido actualizadas correctamente.")

    except Exception as e:
        print(" Error al conectar o procesar:", e)

    finally:
        try:
            cursor.close()
            conn.close()
            print("Conexión cerrada.")
        except:
            pass

# -------------------------
# MAIN
# -------------------------
def main():
    update_viajes_csv()                 # Step 1
    export_master_and_reference()       # Step 2
    import_csv_to_postgres()            # Step 3
    refresh_all_mviews()                # Step 4
    print("===== PROCESO COMPLETO TERMINADO CON ÉXITO =====")
    input("Presiona ENTER para salir...")

if __name__ == "__main__":
    main()
