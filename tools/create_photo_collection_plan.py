import csv
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATASET = os.path.join(ROOT, "spare_parts_dataset")

with open(os.path.join(DATASET, "dataset_report.json"), encoding="utf-8") as f:
    dataset = json.load(f)
with open(os.path.join(DATASET, "dataset_quality_report.json"), encoding="utf-8") as f:
    quality = json.load(f)

parts = {int(p["id"]): p for p in dataset["parts"]}
counts = {pid: int(dataset["images_per_part"][str(pid)]) for pid in parts}
worst = {int(x["part_id"]): x for x in quality["worst_performing_parts"]}

priority1 = {6, 11, 50, 71, 72, 5, 7, 8, 9, 32, 70, 74, 27, 29, 49}
pair_ids = set()
pair_rows = quality["most_confused_part_pairs"]
for pair in pair_rows:
    pair_ids.add(int(pair["part_a"]))
    pair_ids.add(int(pair["part_b"]))
priority1 |= pair_ids

rows = []
for pid in sorted(parts):
    if pid in priority1:
        priority = 1
    elif counts[pid] == 3:
        priority = 2
    else:
        priority = 3

    info = worst.get(pid)
    if info:
        wrong = info.get("common_wrong_predictions", [])
        confused_with = "; ".join(
            f"PART_{x['predicted_part']} ({x['count']} wrong, max sim {x['max_similarity']:.3f})"
            for x in wrong[:3]
        ) or "None recorded"
        problem = (
            f"LOO accuracy {info['accuracy']:.1%}; "
            f"{' and '.join(info.get('visual_review', {}).get('categories', []))}"
        )
        reason = info.get("visual_review", {}).get("evidence", "")
    else:
        confused = [
            f"PART_{p['part_b'] if p['part_a'] == pid else p['part_a']}"
            for p in pair_rows if pid in (int(p["part_a"]), int(p["part_b"]))
        ]
        confused_with = "; ".join(dict.fromkeys(confused)) or "None recorded"
        problem = "Baseline part not in the 15 worst-performing classes"
        reason = "Collect representative views and one discriminative detail photo before relying on visual matching."

    if pid in (66, 71):
        problem = "Critical visual-disambiguation pair; current images include byte-identical cross-part pairs"
        confused_with = "PART_66 and PART_71"
        reason = "Do not assume an error. Capture matched, high-resolution views that reveal the actual physical/reference distinction."
    elif pid in priority1:
        reason = reason or "Priority 1 because this part is in a high-confusion pair or has poor LOO performance."

    if priority == 1:
        recommended = "5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature."
    elif priority == 2:
        recommended = "5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail."
    else:
        recommended = "3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature."

    rows.append({
        "priority": priority,
        "part_id": pid,
        "reference": parts[pid].get("reference", ""),
        "current_image_count": counts[pid],
        "problem": problem,
        "confused_with": confused_with,
        "recommended_new_images": recommended,
        "reason": reason,
    })

csv_path = os.path.join(DATASET, "photo_collection_priority.csv")
with open(csv_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=[
        "priority", "part_id", "reference", "current_image_count", "problem",
        "confused_with", "recommended_new_images", "reason",
    ])
    writer.writeheader()
    writer.writerows(rows)

priority1_ids = sorted(priority1)
priority2_ids = sorted(pid for pid in parts if pid not in priority1 and counts[pid] == 3)
priority3_ids = sorted(pid for pid in parts if pid not in priority1 and counts[pid] != 3)

md = []
md.append("# Photo collection plan v2\n\n")
md.append("This plan prepares a second objective MobileNetV2 evaluation. It does not modify production code, OCR, YOLO, MySQL, existing images, models, or thresholds. The goal is to collect **distinguishing information**, not merely increase the image count.\n\n")
md.append("## 1. Overall collection strategy\n\n")
md.append("- Current baseline remains unchanged: 76 parts, 311 images, LOO Recall@1 approximately 51.77%.\n")
md.append("- Target approximately 8–12 correctly labeled images per part after collection. The exact number may be lower when an angle has no physical meaning.\n")
md.append("- For every confusing pair, collect the same controlled view of each physical part so the distinguishing feature can be compared directly.\n")
md.append("- Capture the feature that actually separates the parts: connector, mounting pattern, dimensions, shape detail, printed suffix, pin count, or another verified feature. Do not assume which feature exists.\n")
md.append("- Keep label/reference close-ups separate from overall/shape photos in the collection notes, while retaining the same single part ID for every image.\n\n")
md.append("## Priority counts\n\n")
md.append(f"- Priority 1: **{len(priority1_ids)} parts** (15 worst-performing parts plus both sides of every recorded high-confusion pair)\n")
md.append(f"- Priority 2: **{len(priority2_ids)} parts** (remaining parts with exactly 3 current images)\n")
md.append(f"- Priority 3: **{len(priority3_ids)} parts** (all remaining parts)\n\n")

def add_priority(title, ids, detail):
    md.append(f"## {title}\n\n{detail}\n\n")
    md.append("| Part | Reference | Current images | Problem/confusion | New images |\n|---:|---|---:|---|---|\n")
    for pid in ids:
        r = next(x for x in rows if x["part_id"] == pid)
        md.append(f"| PART_{pid} | `{r['reference']}` | {r['current_image_count']} | {r['problem']}; confused with: {r['confused_with']} | {r['recommended_new_images']} |\n")
    md.append("\n")

add_priority("2. Priority 1 parts", priority1_ids, "These parts need targeted collection first. The CSV contains the complete reason and confusion list for each part.")
add_priority("3. Priority 2 parts", priority2_ids, "These classes have only three current images, so their evaluation is especially sensitive to viewpoint and photo quality.")
add_priority("4. Priority 3 parts", priority3_ids, "These parts are not currently the highest risk, but should still receive consistent reference and distinguishing-feature photos.")

md.append("## 5. PART_66 / PART_71 special plan\n\n")
md.append("- PART_66 reference: `330322028306`\n")
md.append("- PART_71 reference: `330322028206`\n")
md.append("- Do not delete, merge, relabel, or copy any existing image.\n")
md.append("- The current photos include byte-identical pairs, but this is not treated as proof of incorrect data. The two physical references may differ by a small feature that the photos do not show.\n")
md.append("- Photograph each physical part independently, then compare the matched views side-by-side:\n")
md.append("  1. full front and full back;\n  2. left and right sides;\n  3. top and bottom;\n  4. connector/interface face and pin count;\n  5. mounting face, holes, clips, and keying;\n  6. dimensions or ruler/caliper view where relevant;\n  7. high-resolution label and exact reference/suffix;\n  8. macro of any feature that differs when the parts are placed side-by-side;\n  9. one neutral-background overall view for each part.\n")
md.append("- Do not invent a difference. If no difference is visible, record that the distinction remains unknown and rely on a readable reference/OCR close-up.\n\n")

md.append("## 6. Standard photo protocol\n\n")
md.append("For each part, aim for the following set, omitting only physically meaningless views:\n\n")
md.append("1. Full overall view\n2. Front\n3. Back\n4. Side\n5. Opposite side\n6. Connector/interface\n7. Mounting area\n8. Label/reference close-up\n9. Close-up of the known or suspected distinguishing feature\n10. Different orientation\n11. Hand-held example, if hand-held use is expected\n12. Different lighting/background\n\n")
md.append("The most important image is the one showing the feature that separates this part from its closest confusing part. A generic additional angle is less valuable than a clear connector, suffix, hole pattern, dimension, or shape-detail photo.\n\n")

md.append("## 7. Image labeling rules\n\n")
md.append("- Every image must belong to exactly one database part ID.\n")
md.append("- Record the database part ID and reference at capture time.\n")
md.append("- Use a filename that preserves the single part identity, for example `PART_66_label_closeup_01.jpg`.\n")
md.append("- Record the view/condition in accompanying collection notes: `overall`, `connector`, `mounting`, `label`, `distinguishing_feature`, `handheld`, `low_light`, etc.\n")
md.append("- Verify the physical item and printed reference before assigning the image.\n\n")

md.append("## 8. Rules preventing cross-part image duplication\n\n")
md.append("- Never reuse one physical photo under two part IDs.\n")
md.append("- Never copy an image between class folders.\n")
md.append("- If the same scene contains two parts, photograph and crop each part separately only if each resulting image is independently captured/verified and assigned to one part; do not use one identical crop for both.\n")
md.append("- Before the next evaluation, compute byte hashes and perceptual similarity again, but treat high similarity as a review flag—not an automatic data error.\n")
md.append("- For visually identical-looking parts, collect separate photos with the two physical items separated and the distinguishing evidence visible.\n\n")

md.append("## 9. Recommended collection amount and evaluation split\n\n")
md.append("- Collect enough new images to reach approximately 8–12 total images per part, prioritizing discriminative views over volume.\n")
md.append("- Keep newly collected images separate from the current baseline until verified.\n")
md.append("- Do not change the existing baseline or thresholds before rerunning the same evaluation protocol.\n")
md.append("- After collection, re-run duplicate review, then evaluate with leave-one-out and repeated 1-shot/2-shot tests using the same metrics. Compare results objectively to the 51.77% LOO baseline.\n\n")

md.append("## 10. Exact conditions to photograph\n\n")
md.append("- Printed reference, model number, suffix, and dimensions at readable resolution.\n")
md.append("- Connector face, pin count, keying, terminal arrangement, and cable/interface details.\n")
md.append("- Mounting holes, clips, tabs, brackets, threads, and physical interfaces.\n")
md.append("- Profile, height, width, thickness, openings, grooves, and other shape details.\n")
md.append("- Front/back/top/bottom/side views with consistent scale for confusing pairs.\n")
md.append("- Clean neutral background plus realistic hand-held/background examples.\n")
md.append("- Lighting that avoids glare on labels and dark shadows on physical details.\n\n")

md.append("## 11. Files\n\n")
md.append("- `photo_collection_priority.csv`: one row per part with priority, confusion, problem, and recommended new images.\n")
md.append("- This plan intentionally does not modify production code, database contents, OCR, YOLO, model files, or thresholds.\n")

md_path = os.path.join(DATASET, "photo_collection_plan_v2.md")
with open(md_path, "w", encoding="utf-8") as f:
    f.write("".join(md))

print(json.dumps({
    "csv": csv_path,
    "markdown": md_path,
    "priority1_count": len(priority1_ids),
    "priority2_count": len(priority2_ids),
    "priority3_count": len(priority3_ids),
    "rows": len(rows),
}, indent=2))
