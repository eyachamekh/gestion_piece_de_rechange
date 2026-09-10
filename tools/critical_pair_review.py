import json
import os
from PIL import Image, ImageDraw, ImageOps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATASET = os.path.join(ROOT, "spare_parts_dataset")

with open(os.path.join(DATASET, "dataset_report.json"), encoding="utf-8") as f:
    dataset = json.load(f)
with open(os.path.join(DATASET, "dataset_quality_report.json"), encoding="utf-8") as f:
    quality = json.load(f)

parts = {int(x["id"]): x for x in dataset["parts"]}
out_dir = os.path.join(DATASET, "quality_contact_sheets")
os.makedirs(out_dir, exist_ok=True)

def locate(filename, part_id):
    for split in ("train", "val", "test"):
        p = os.path.join(DATASET, "images", split, f"PART_{part_id}", filename)
        if os.path.exists(p):
            return p
    raise FileNotFoundError(filename)

items = []
for pid in (66, 71):
    for filename in parts[pid]["images"]:
        items.append((pid, filename, locate(filename, pid)))

thumb_w, thumb_h = 360, 310
sheet = Image.new("RGB", (thumb_w * 2, thumb_h * ((len(items) + 1) // 2)), "white")
draw = ImageDraw.Draw(sheet)
for i, (pid, filename, path) in enumerate(items):
    x = (i % 2) * thumb_w
    y = (i // 2) * thumb_h
    im = Image.open(path).convert("RGB")
    im = ImageOps.contain(im, (thumb_w - 12, thumb_h - 55))
    sheet.paste(im, (x + (thumb_w - im.width) // 2, y + 5))
    draw.text((x + 6, y + thumb_h - 45), f"PART_{pid} {filename}", fill="black")
sheet_path = os.path.join(out_dir, "critical_pair_PART66_PART71.jpg")
sheet.save(sheet_path, quality=95)

pair_classifications = {
    "66-71": {
        "classification": "NEEDS MANUAL INSPECTION",
        "reason": "Two cross-part pairs are byte-identical, while the references differ. The images visibly show the same yellow safety component views and do not expose a reliable distinguishing feature. This does not prove either database association is wrong.",
    },
    "63-70": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The reviewed images show different industrial components (yellow module versus black Siemens housing) despite similar broad layout/background in the perceptual signature.",
    },
    "8-9": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show similar black Siemens-style housings photographed on the same work surface; the available views do not establish that they are the same physical part.",
    },
    "28-70": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The reviewed images show different physical objects (ring-like mechanical part versus black industrial housing).",
    },
    "46-57": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show different objects (yellow plastic/metal fitting versus small metal cylindrical piece).",
    },
    "38-47": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show different circular metal components with different proportions and openings, although the view/background is similar.",
    },
    "27-47": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "A small pin-like component is compared with a larger ring-like component; they are not visibly identical.",
    },
    "29-59": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The reviewed images show different mechanical shapes, not the same object.",
    },
    "8-70": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show black housings with similar photography/background but different visible enclosure details; reference-level distinction remains unresolved.",
    },
    "7-8": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "Both are black industrial housings photographed from related angles, but no byte identity was found.",
    },
    "8-63": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show a black housing and a yellow module; the perceptual similarity is not evidence of identical data.",
    },
    "19-73": {
        "classification": "NEEDS MANUAL INSPECTION",
        "reason": "The compact perceptual signatures are similar, but the available contact-sheet evidence does not prove whether the objects are the same family or share a background/view.",
    },
    "56-59": {
        "classification": "NEEDS MANUAL INSPECTION",
        "reason": "The pair crosses parts with similar compact signatures, but the available evidence is insufficient to establish a physical identity or specific distinguishing feature.",
    },
    "70-75": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The reviewed images show black industrial housings with related shape/background; they are not byte-identical and no proof of misassignment exists.",
    },
    "27-38": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show small metal components with different apparent geometry and scale.",
    },
    "29-47": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show different ring/circular components; visual similarity likely reflects shape and work-surface background.",
    },
    "6-8": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The reviewed images show different black industrial housings with related photography conditions.",
    },
    "69-72": {
        "classification": "NEEDS MANUAL INSPECTION",
        "reason": "The perceptual pair may reflect related yellow/industrial components, but the available evidence does not prove identity or the exact feature separating the references.",
    },
    "17-23": {
        "classification": "NEEDS MANUAL INSPECTION",
        "reason": "The perceptual signatures are close, but there is not enough visible evidence here to prove a same-image or same-object relationship.",
    },
    "43-47": {
        "classification": "GENUINELY DIFFERENT BUT VISUALLY SIMILAR PARTS",
        "reason": "The images show different industrial/mechanical objects; similar background and compact shape contribute to the perceptual score.",
    },
}

for pair in quality["duplicate_findings"]["cross_part_perceptual_pairs_threshold_0_90"]:
    key = f"{min(pair['part_a'], pair['part_b'])}-{max(pair['part_a'], pair['part_b'])}"
    pair["manual_classification"] = pair_classifications.get(key, {
        "classification": "NEEDS MANUAL INSPECTION",
        "reason": "Similarity alone is insufficient to classify this pair.",
    })

quality["duplicate_findings"]["classification_policy"] = (
    "Perceptual similarity is not treated as proof of bad data. "
    "Only byte identity is confirmed for the two PART_66/PART_71 image pairs; "
    "their database associations remain unaltered and require domain/manual verification."
)

critical = {
    "part_a": {
        "part_id": 66,
        "reference": parts[66]["reference"],
        "images": parts[66]["images"],
    },
    "part_b": {
        "part_id": 71,
        "reference": parts[71]["reference"],
        "images": parts[71]["images"],
    },
    "visible_review": {
        "contact_sheet": "spare_parts_dataset/quality_contact_sheets/critical_pair_PART66_PART71.jpg",
        "finding": "The reviewed images show the same-looking yellow safety component from front, side, rear/plate, and label/detail views. Two images in each part are byte-identical across the parts. No reliable physical difference can be seen in the current photos.",
        "label_or_reference": "The close/detail views contain printed markings, but the available image scale does not establish the two database references as visually readable or show a reference-specific suffix difference.",
        "dimensional_difference": "Not determinable from the current 2D photos.",
        "connector_difference": "Not determinable from the current photos.",
        "mounting_difference": "Not determinable from the current photos.",
        "shape_difference": "No reliable difference visible in the reviewed pair images.",
        "other_difference": "Possible small product/version distinction cannot be ruled out; it requires a physical inspection or higher-resolution targeted photos.",
    },
    "answers": {
        "A": "No reliable conclusion that MobileNetV2 can distinguish PART_66 from PART_71. Current LOO results show PART_71 was predicted as PART_66 for all five queries, including similarity 1.0 for the byte-identical images.",
        "B": "Collect controlled side-by-side photos of each part with a scale/ruler, connector and mounting faces, top/bottom/side views, and macro close-ups of every label, suffix, connector, hole pattern, and dimensional marking. Capture the same view and lighting for both references.",
        "C": "Yes, OCR is likely better if the distinguishing reference/suffix is printed and readable. OCR should be performed on a dedicated high-resolution label close-up; it should win over visual similarity.",
        "D": "Fine-tuning may be necessary only if a repeatable physical difference is visible but not represented by the generic feature extractor. It cannot solve identical pixels or missing visual evidence; the first requirement is correctly labeled, discriminative photos.",
    },
}

with open(os.path.join(DATASET, "dataset_quality_report.json"), "w", encoding="utf-8") as f:
    json.dump(quality, f, indent=2)

lines = [
    "# Critical visual-disambiguation case: PART_66 vs PART_71\n\n",
    "This is an investigation only. No image, database row, production code, model, or threshold was modified. Byte identity is not treated as proof that either part is incorrect.\n\n",
    f"## References\n\n- PART_66: `{parts[66]['reference']}`\n- PART_71: `{parts[71]['reference']}`\n\n",
    "## All current images\n\n",
]
for pid in (66, 71):
    lines.append(f"### PART_{pid}\n")
    for fn in parts[pid]["images"]:
        lines.append(f"- `{fn}`\n")
    lines.append("\n")
lines.extend([
    "## Visual evidence\n\n",
    "- The contact sheet is `quality_contact_sheets/critical_pair_PART66_PART71.jpg`.\n",
    "- Both parts show the same-looking yellow safety component across front, side, rear/plate, and detail views.\n",
    "- Two pairs are byte-identical: `1788611051045.jpg` ↔ `1788719233395.jpg`, and `1788611051048.jpg` ↔ `1788719233399.jpg`.\n",
    "- No reliable dimensional, connector, mounting, shape, or suffix difference is visible in the current photos.\n",
    "- A small real product/version difference remains possible; the current images do not prove or disprove it.\n\n",
    "## Printed reference/label\n\n",
    "The images contain printed/detail regions, but the present image scale and views do not establish a readable reference-specific suffix for both parts. A dedicated high-resolution label close-up is required.\n\n",
    "## Answers\n\n",
    f"- **A. MobileNetV2:** {critical['answers']['A']}\n",
    f"- **B. Additional photos:** {critical['answers']['B']}\n",
    f"- **C. OCR:** {critical['answers']['C']}\n",
    f"- **D. Fine-tuning:** {critical['answers']['D']}\n\n",
    "## Required photo set\n\n",
    "For each reference, capture the same controlled set: full front/back/top/bottom/left/right views; connector face; mounting face and hole pattern; ruler/caliper or dimension-marking view; macro label close-up; and one neutral-background overall photo. Keep the two references physically separated and manually verified.\n",
])
with open(os.path.join(DATASET, "critical_pair_PART66_PART71.md"), "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Wrote critical pair report and updated quality classifications")
