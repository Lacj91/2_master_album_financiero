# This script converts structured Excel sheets into well-formatted CSV files by resolving formulas, standardizing dates and numeric fields, 
# cleaning text values, and removing non-analytical columns.
# The resulting CSV outputs are optimized for consistent loading into PostgreSQL fact and dimension tables as part of the automated data pipeline.

import os
import pandas as pd
from openpyxl import load_workbook
import warnings

warnings.filterwarnings("ignore", category=UserWarning, module="openpyxl")

MASTER_FILE = r"C:\Master Example\Master Example\Master Example\master_example.xlsm"

REFERENCE_FILES = {
    "tabla_geografia": r"C:\Master Example\Master Example\Master Example\master_example.xlsm",
    "tabla_id_deuda": r"C:\Master Example\Master Example\Master Example\master_example.xlsm",
    "tabla_id_presupuesto": r"C:\Master Example\Master Example\Master Example\master_example.xlsm",
    "tabla_id_viajes": r"C:\Master Example\Master Example\Master Example\master_example.xlsm",
}

OUTPUT_FOLDER = r"C:\Master Example\Master Example\Master Example"
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

# Load Excel sheet with formulas converted to values
def load_excel_sheet_as_df(path, sheet_name):
    wb = load_workbook(path, data_only=True)
    ws = wb[sheet_name]

    data = list(ws.values)
    header = data[0]
    rows = data[1:]

    df = pd.DataFrame(rows, columns=header)
    return df

# Format dates → dd/mm/yyyy
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

# Convert currency columns to numeric floats
def clean_currency_columns(df, sheet_name):
    if sheet_name not in CURRENCY_COLUMNS:
        return df

    for col in CURRENCY_COLUMNS[sheet_name]:
        if col in df.columns:
            df[col] = (
                df[col]
                .astype(str)
                .str.replace("$", "", regex=False)
                .str.replace(",", "", regex=False)
            )

    return df

# Clean text columns: remove quotes, commas, $, whitespace
def clean_text_columns(df):
    for col in df.columns:
        if df[col].dtype == object:
            df[col] = df[col].astype(str)
            df[col] = df[col].str.replace('"', "", regex=False)
            df[col] = df[col].str.replace(",", "", regex=False)
            df[col] = df[col].str.strip()
    return df

# Export DataFrame to CSV
def export_dataframe(df, name):
    output_path = os.path.join(OUTPUT_FOLDER, f"{name}.csv")
    df.to_csv(output_path, index=False, encoding="utf-8")
    print(f" Exportado: {output_path}")

# MAIN PROCESS
def main():

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

if __name__ == "__main__":
    main()
