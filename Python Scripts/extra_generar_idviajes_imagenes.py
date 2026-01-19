// Copy 5 example images and paste them 147 times assigning the corresponding id_code.

import os
import shutil

folder = r"C:\Example\example\example"

# Take only original images (avoid re-copying generated ones)
images = [
    f for f in os.listdir(folder)
    if f.lower().endswith((".jpg", ".png", ".jpeg"))
    and not f.startswith("V")
]

images.sort()

total_images = 147
counter = 1

for i in range(total_images):
    src_image = images[i % len(images)]
    src_path = os.path.join(folder, src_image)

    extension = os.path.splitext(src_image)[1]
    new_name = f"V{counter:03}{extension}"
    dst_path = os.path.join(folder, new_name)

    shutil.copy(src_path, dst_path)
    counter += 1