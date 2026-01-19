// Generate the table dim_viajes_url

import os
import pandas as pd
import re

# Folder where images are stored locally
folder_path = r"C:\example\example\example"

# List all jpg/jpeg files
image_files = [f for f in os.listdir(folder_path) if f.lower().endswith((".jpg", ".jpeg"))]

base_url = "https://raw.githubusercontent.com/Lacj91/2_album_financiero/main/data/powerbi_viajes/"

# Combine base URL with filenames
image_urls = [base_url + f for f in image_files]

# Create DataFrame
df = pd.DataFrame({"image_url": image_urls})

# Extract id_viaje
df["id_viaje"] = df["image_url"].str.extract(r"/(V\d+)\.(?:jpg|jpeg)$", flags=re.IGNORECASE)

df.head(25)  # preview

df.to_csv(r"C:\Users\lacj9\OneDrive\Documents\Educacion\Data Analysis\Capstones Project\Personal Capstone project\Fase 2\album_financiero_phase_two\data\dim_viajes_url_publico.csv", index=False)