import json
import os
from PIL import Image, ImageDraw, ImageOps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATASET = os.path.join(ROOT, "spare_parts_dataset")
with open(os.path.join(DATASET, "dataset_quality_report.json"), encoding="utf-8") as f:
    report = json.load(f)

out_dir = os.path.join(DATASET, "quality_contact_sheets")
os.makedirs(out_dir, exist_ok=True)

def find_image(rel):
    return os.path.join(ROOT, rel.replace("\\", os.sep))

def make_sheet(name, items, columns=4):
    thumb_w, thumb_h = 260, 220
    rows = (len(items) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_w, rows * thumb_h), "white")
    draw = ImageDraw.Draw(sheet)
    for i, item in enumerate(items):
        x = (i % columns) * thumb_w
        y = (i // columns) * thumb_h
        try:
            im = Image.open(find_image(item["relative_path"])).convert("RGB")
            im = ImageOps.contain(im, (thumb_w - 10, thumb_h - 40))
            sheet.paste(im, (x + (thumb_w - im.width) // 2, y + 4))
            label = item.get("label", "")
            draw.text((x + 4, y + thumb_h - 32), label[:42], fill="black")
        except Exception as exc:
            draw.text((x + 4, y + 4), str(exc), fill="red")
    path = os.path.join(out_dir, name)
    sheet.save(path, quality=92)
    print(path)

# Worst parts: all images, with the part ID and filename.
worst = report["worst_performing_parts"]
items = []
for part in worst:
    for rel in part["images"]:
        items.append({"relative_path": rel, "label": f"PART_{part['part_id']} {os.path.basename(rel)}"})
make_sheet("worst_parts_all.jpg", items)

# Exact duplicate pairs and the highest perceptual pairs.
pairs = report["duplicate_findings"]["cross_part_perceptual_pairs_threshold_0_90"][:12]
items = []
for pair in pairs:
    items.append({"relative_path": pair["path_a"], "label": f"A P{pair['part_a']} {pair['image_a']}"})
    items.append({"relative_path": pair["path_b"], "label": f"B P{pair['part_b']} {pair['image_b']}"})
make_sheet("cross_part_suspicious_pairs.jpg", items, columns=4)
