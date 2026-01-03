# This script monitors a local image folder associated with travel records, detects changes using file hashing,
# and regenerates a CSV mapping travel IDs to image URLs when updates occur.
# It then commits and pushes the updated dataset and assets to the repository, ensuring the Power BI model always references an up-to-date and consistent image source.

import hashlib
import pandas as pd
import re
import subprocess
from pathlib import Path
import os


# Paths
repo_path = r"C:\EXAMPLE\EXAMPLE\EXAMPLE"
csv_output = r"C:\EXAMPLE\EXAMPLE\EXAMPLE"

# URL base
base_url = "https://raw.example.com/example"

# Hash storage file
hash_file = os.path.join(repo_path, "_local_image_hashes.txt")


def file_hash(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        h.update(f.read())
    return h.hexdigest()


def load_previous_hashes():
    if not os.path.exists(hash_file):
        return {}
    hashes = {}
    with open(hash_file, "r", encoding="utf-8") as f:
        for line in f:
            name, h = line.strip().split("|")
            hashes[name] = h
    return hashes


def save_hashes(hash_dict):
    with open(hash_file, "w", encoding="utf-8") as f:
        for name, h in hash_dict.items():
            f.write(f"{name}|{h}\n")


print("Escaneando carpeta powerbi_viajes...")

# Step 1: Scan image folder
files = [f for f in os.listdir(repo_path) if f.lower().endswith((".jpg", ".jpeg"))]

current_hashes = {}
for f in files:
    fp = os.path.join(repo_path, f)
    current_hashes[f] = file_hash(fp)

previous_hashes = load_previous_hashes()

# Step 2: Detect changes
if current_hashes == previous_hashes:
    print("✓ No se detectaron cambios en carpeta powerbi_viajes. Se prosigue al siguiente paso.")
    exit()
else:
    print("Se detectaron cambios en powerbi_viajes.")
    print("Regenerando archivo viajes_url.csv...")


# Step 3: Regenerate CSV
image_urls = [base_url + f for f in files]

df = pd.DataFrame({"image_url": image_urls})
df["id_viaje"] = df["image_url"].str.extract(r"/(V\d+)\.(?:jpg|jpeg)$", flags=re.IGNORECASE)

df.to_csv(csv_output, index=False)

print("Archivo viajes_url.csv actualizado con éxito.")


# Step 4: Save new hashes
save_hashes(current_hashes)

print("Hashes actualizados para detección futura de cambios.")


# Step 5: Auto Git Upload
def run_git(cmd, message):
    print(message)
    result = subprocess.run(cmd, cwd=repo_path, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        print("Error ejecutando:", cmd)
    return result


print("Subiendo cambios al repositorio...")

run_git("git add .", "Añadiendo archivos al commit...")
run_git('git commit -m "Auto-update viajes_url.csv and images"', "Creando commit automático...")
run_git("git push", "Enviando cambios al repositorio...")

print("✓ Actualizacion de carpeta powerbi_viajes completada con éxito.")

