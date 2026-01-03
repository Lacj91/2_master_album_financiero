#This script connects to PostgreSQL and refreshes all materialized views in the album_financiero schema in a controlled order, 
# respecting dependencies between validation (v_ds_) and consumption (ds_) datasets.
# After execution, all curated datasets are fully updated and ready to be consumed by the Power BI semantic model.


import psycopg2

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

        # Obtener todas las MATERIALIZED VIEWS
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

        # Orden recomendado
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

        # REFRESH en orden
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


if __name__ == "__main__":
    print("Iniciando proceso REFRESH MATERIALIZED VIEW")
    refresh_all_mviews()
    # input("\n✔ Presiona ENTER para salir...")

