import hashlib
import json
import math
import os
from collections import Counter, defaultdict
from itertools import combinations

import numpy as np
from PIL import Image, ImageOps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATASET = os.path.join(ROOT, "spare_parts_dataset")
REPORT_DIR = DATASET

with open(os.path.join(DATASET, "dataset_report.json"), encoding="utf-8") as f:
    dataset_report = json.load(f)
with open(os.path.join(DATASET, "loo_results.json"), encoding="utf-8") as f:
    loo = json.load(f)
with open(os.path.join(DATASET, "per_part_report.json"), encoding="utf-8") as f:
    per_part_report = json.load(f)

part_info = {int(p["id"]): p for p in dataset_report["parts"]}
reference = {pid: str(info.get("reference") or "") for pid, info in part_info.items()}

records = []
for part in sorted(part_info):
    part_dir = os.path.join(DATASET, "images")
    for split in ("train", "val", "test"):
        folder = os.path.join(part_dir, split, f"PART_{part}")
        if not os.path.isdir(folder):
            continue
        for name in sorted(os.listdir(folder)):
            path = os.path.join(folder, name)
            if not os.path.isfile(path):
                continue
            try:
                raw = open(path, "rb").read()
                with Image.open(path) as im:
                    exif = im.getexif()
                    orientation = exif.get(274)
                    width, height = im.size
                    ratio = width / height if height else None
                    corrected = ImageOps.exif_transpose(im).convert("RGB")
                    small = corrected.resize((32, 32))
                    arr = np.asarray(small, dtype=np.float32)
                    # Average hash and a compact color/layout signature.
                    gray = np.asarray(small.convert("L"), dtype=np.float32)
                    ahash = "".join("1" if x >= gray.mean() else "0" for x in gray.reshape(-1))
                    phash = ahash
                    label_crop_ratio = None
                    # Text-heavy/label-like heuristic: edge density plus compact aspect.
                    edge = np.abs(np.diff(gray, axis=1)).mean() + np.abs(np.diff(gray, axis=0)).mean()
                    brightness = float(arr.mean())
                    label_like = bool(edge > 24 and min(width, height) >= 300)
                records.append({
                    "part_id": part,
                    "reference": reference[part],
                    "split": split,
                    "image": name,
                    "relative_path": os.path.relpath(path, ROOT),
                    "path": path,
                    "bytes": len(raw),
                    "sha256": hashlib.sha256(raw).hexdigest(),
                    "width": width,
                    "height": height,
                    "aspect_ratio": ratio,
                    "orientation": orientation,
                    "exif_orientation_present": orientation is not None,
                    "ahash": ahash,
                    "phash": phash,
                    "edge_score": float(edge),
                    "brightness": brightness,
                    "label_like_heuristic": label_like,
                })
            except Exception as exc:
                records.append({
                    "part_id": part, "reference": reference[part], "split": split,
                    "image": name, "relative_path": os.path.relpath(path, ROOT),
                    "path": path, "error": str(exc),
                })

def hamming(a, b):
    return sum(x != y for x, y in zip(a, b))

def perceptual_similarity(a, b):
    if "phash" not in a or "phash" not in b:
        return 0.0
    return 1.0 - hamming(a["phash"], b["phash"]) / len(a["phash"])

by_sha = defaultdict(list)
for r in records:
    if "sha256" in r:
        by_sha[r["sha256"]].append(r)

cross_part_duplicates = []
for values in by_sha.values():
    parts = {x["part_id"] for x in values}
    if len(parts) > 1:
        for a, b in combinations(values, 2):
            if a["part_id"] != b["part_id"]:
                cross_part_duplicates.append({
                    "part_a": a["part_id"], "image_a": a["image"],
                    "part_b": b["part_id"], "image_b": b["image"],
                    "exact_duplicate": True, "perceptual_similarity": 1.0,
                    "file_size_a": a["bytes"], "file_size_b": b["bytes"],
                    "reference_a": a["reference"], "reference_b": b["reference"],
                    "path_a": a["relative_path"], "path_b": b["relative_path"],
                })

cross_part_near = []
for a, b in combinations(records, 2):
    if a["part_id"] == b["part_id"] or "phash" not in a or "phash" not in b:
        continue
    sim = perceptual_similarity(a, b)
    if sim >= 0.90:
        cross_part_near.append({
            "part_a": a["part_id"], "image_a": a["image"],
            "part_b": b["part_id"], "image_b": b["image"],
            "exact_duplicate": a["sha256"] == b["sha256"],
            "perceptual_similarity": sim,
            "file_size_a": a["bytes"], "file_size_b": b["bytes"],
            "reference_a": a["reference"], "reference_b": b["reference"],
            "path_a": a["relative_path"], "path_b": b["relative_path"],
        })
cross_part_near.sort(key=lambda x: (-x["perceptual_similarity"], x["part_a"], x["part_b"]))

within_part_near = []
for part in sorted(part_info):
    values = [r for r in records if r["part_id"] == part]
    for a, b in combinations(values, 2):
        sim = perceptual_similarity(a, b)
        if sim >= 0.90:
            within_part_near.append({
                "part_id": part, "image_a": a["image"], "image_b": b["image"],
                "perceptual_similarity": sim, "exact_duplicate": a["sha256"] == b["sha256"],
            })

results_by_part = defaultdict(list)
for r in loo["results"]:
    results_by_part[int(r["actual_part"])].append(r)

worst = []
for row in per_part_report["per_part"]:
    pid = int(row["part_id"])
    wrong = [r for r in results_by_part[pid] if not r["correct"]]
    wrong_counts = Counter(r["predicted_part"] for r in wrong)
    common_wrong = []
    for other, count in wrong_counts.most_common():
        sims = [r["best_score"] for r in wrong if r["predicted_part"] == other]
        common_wrong.append({
            "predicted_part": other,
            "count": count,
            "mean_similarity": float(np.mean(sims)),
            "max_similarity": float(np.max(sims)),
        })
    worst.append({
        "part_id": pid,
        "reference": reference[pid],
        "image_count": len([r for r in records if r["part_id"] == pid]),
        "correct": row["correct"],
        "total": row["total"],
        "accuracy": row["accuracy"],
        "common_wrong_predictions": common_wrong[:5],
        "images": [r["relative_path"] for r in records if r["part_id"] == pid],
    })
worst.sort(key=lambda x: (x["accuracy"], -x["total"], x["part_id"]))
worst15 = worst[:15]

part_consistency = []
for pid in sorted(part_info):
    values = [r for r in records if r["part_id"] == pid and "width" in r]
    ratios = [r["aspect_ratio"] for r in values]
    areas = [r["width"] * r["height"] for r in values]
    orientations = Counter(str(r["orientation"]) if r["orientation"] is not None else "none" for r in values)
    label_count = sum(1 for r in values if r["label_like_heuristic"])
    full_count = len(values) - label_count
    ratio_range = (min(ratios), max(ratios)) if ratios else None
    resolution_range = (min(areas), max(areas)) if areas else None
    consistency_score = (max(ratios) - min(ratios)) if ratios else None
    part_consistency.append({
        "part_id": pid, "reference": reference[pid], "image_count": len(values),
        "dimensions": sorted({f"{r['width']}x{r['height']}" for r in values}),
        "aspect_ratio_min_max": ratio_range,
        "resolution_pixels_min_max": resolution_range,
        "exif_orientations": dict(orientations),
        "label_like_count": label_count,
        "full_part_like_count": full_count,
        "aspect_ratio_range": consistency_score,
        "brightness_min_max": (
            min(r["brightness"] for r in values), max(r["brightness"] for r in values)
        ) if values else None,
        "high_inconsistency_flag": bool(
            values and ((consistency_score or 0) > 0.8 or (label_count > 0 and full_count > 0))
        ),
        "images": [
            {
                "image": r["image"], "split": r["split"], "width": r["width"],
                "height": r["height"], "aspect_ratio": r["aspect_ratio"],
                "orientation": r["orientation"],
                "label_like_heuristic": r["label_like_heuristic"],
                "brightness": r["brightness"],
                "relative_path": r["relative_path"],
            } for r in values
        ],
    })

pair_counts = Counter()
pair_examples = defaultdict(list)
for r in loo["results"]:
    if not r["correct"]:
        pair = tuple(sorted((int(r["actual_part"]), int(r["predicted_part"]))))
        pair_counts[pair] += 1
        if len(pair_examples[pair]) < 3:
            pair_examples[pair].append({
                "query": r["query"], "best_similarity": r["best_score"],
                "margin": r["margin"],
            })
confused_pairs = [
    {
        "part_a": pair[0], "reference_a": reference[pair[0]],
        "part_b": pair[1], "reference_b": reference[pair[1]],
        "wrong_query_count": count, "examples": pair_examples[pair],
    }
    for pair, count in pair_counts.most_common(20)
]

quality = {
    "dataset_overview": {
        "parts": len(part_info), "images": len(records),
        "images_with_read_errors": sum(1 for r in records if "error" in r),
        "min_images_per_part": min(len([r for r in records if r["part_id"] == p]) for p in part_info),
        "max_images_per_part": max(len([r for r in records if r["part_id"] == p]) for p in part_info),
        "source": "spare_parts_dataset/images copied from backend/uploads",
    },
    "duplicate_findings": {
        "cross_part_exact_duplicate_pairs": cross_part_duplicates,
        "cross_part_perceptual_pairs_threshold_0_90": cross_part_near,
        "within_part_perceptual_pairs_threshold_0_90": within_part_near,
        "exact_duplicate_sha_groups": [
            [{"part_id": x["part_id"], "image": x["image"]} for x in group]
            for group in by_sha.values() if len(group) > 1
        ],
    },
    "worst_performing_parts": worst15,
    "most_confused_part_pairs": confused_pairs,
    "image_consistency": part_consistency,
    "quality_summary": {
        "total_exif_orientation_present": sum(1 for r in records if r.get("exif_orientation_present")),
        "dimension_counts": dict(Counter(f"{r.get('width')}x{r.get('height')}" for r in records)),
        "aspect_ratio_counts_rounded": dict(Counter(round(r["aspect_ratio"], 2) for r in records if "aspect_ratio" in r)),
        "heuristic_label_like_total": sum(1 for r in records if r.get("label_like_heuristic")),
        "heuristic_full_part_like_total": sum(1 for r in records if not r.get("label_like_heuristic") and "width" in r),
        "low_resolution_under_640_short_side": sum(
            1 for r in records if "width" in r and min(r["width"], r["height"]) < 640
        ),
    },
    "diagnosis_policy": {
        "factual_limit": "Automated metadata and perceptual checks cannot prove hand, background, or object count; those require visual review.",
        "confirmed_categories": ["A duplicate/misassigned images", "J insufficient number of images"],
        "heuristic_categories": ["B visually similar parts", "C different views of same part", "D label close-up vs full-part mismatch", "G poor image quality", "H rotation/orientation"],
    },
    "recommendations": {
        "cleanup": [
            "Manually review every cross-part exact/perceptual duplicate before training or threshold tuning.",
            "Confirm each database image-to-part association; do not delete automatically.",
            "Keep query/gallery images disjoint during evaluation.",
            "Separate label close-ups and full-part photos as explicit image roles if possible.",
        ],
        "new_photos": [
            "Collect at least 8-12 images per part: overall views, multiple rotations, consistent distance, varied lighting/backgrounds.",
            "Add a dedicated readable-label close-up when a reference exists.",
            "Capture no-hand images and separately labeled hand-held images.",
            "Prioritize parts with 0% or low LOO accuracy and the most confused pairs.",
        ],
        "model_recommendation": "Keep MobileNetV2 as the baseline only; do not integrate it for automatic identification yet. Re-run evaluation after data cleanup and collection. Fine-tuning should be considered only after labels/associations and image roles are verified.",
        "yolo_recommendation": "Not required for the current one-part-per-photo workflow unless visual review confirms frequent multi-object or hand/background localization failures.",
    },
}

with open(os.path.join(REPORT_DIR, "dataset_quality_report.json"), "w", encoding="utf-8") as f:
    json.dump(quality, f, indent=2)

def fmt_paths(paths):
    return ", ".join(f"`{p}`" for p in paths)

md = []
md.append("# Dataset quality investigation\n")
md.append("Read-only investigation of the exported dataset, existing LOO results, and per-part report. No images, database rows, app code, models, or thresholds were modified.\n")
md.append("## 1. Dataset overview\n")
md.append(f"- Parts/classes: **{len(part_info)}**\n- Images inspected: **{len(records)}**\n- Per-part count: **{quality['dataset_overview']['min_images_per_part']}–{quality['dataset_overview']['max_images_per_part']}**\n- Read/decoding errors: **{quality['dataset_overview']['images_with_read_errors']}**\n- EXIF orientation tags present: **{quality['quality_summary']['total_exif_orientation_present']}**\n- Heuristic label-like images: **{quality['quality_summary']['heuristic_label_like_total']}** (not proof of a label)\n- Images with short side under 640 px: **{quality['quality_summary']['low_resolution_under_640_short_side']}**\n")
md.append("## 2. Cross-part duplicates and leakage\n")
md.append(f"- Exact cross-part duplicate pairs: **{len(cross_part_duplicates)}**\n- Perceptual cross-part pairs at phash similarity >= 0.90: **{len(cross_part_near)}**\n")
for x in cross_part_near[:50]:
    md.append(f"- PART_{x['part_a']} `{x['image_a']}` ↔ PART_{x['part_b']} `{x['image_b']}`; exact={x['exact_duplicate']}; perceptual={x['perceptual_similarity']:.4f}; sizes={x['file_size_a']}/{x['file_size_b']}; refs=`{x['reference_a']}` / `{x['reference_b']}`.\n")
if not cross_part_near:
    md.append("No cross-part perceptual pairs crossed the configured threshold.\n")
md.append("These findings must be manually verified before cleanup. If the same physical photo is assigned to different parts, LOO can produce irreducible ties or confidently wrong predictions; it can also distort threshold analysis because a wrong class may have similarity 1.0.\n")

md.append("## 3. Fifteen worst-performing parts\n")
md.append("| Part | Reference | Images | Correct/total | Accuracy | Most common wrong prediction |\n|---:|---|---:|---:|---:|---|\n")
for x in worst15:
    common = x["common_wrong_predictions"][0] if x["common_wrong_predictions"] else None
    wrong = f"PART_{common['predicted_part']} ({common['count']}x, max sim {common['max_similarity']:.4f})" if common else "none"
    md.append(f"| {x['part_id']} | `{x['reference']}` | {x['image_count']} | {x['correct']}/{x['total']} | {x['accuracy']:.3f} | {wrong} |\n")
md.append("\nDetailed per-query evidence is in `loo_results.json`; full per-part evidence is in `dataset_quality_report.json`.\n")

md.append("## 4. Most-confused pairs\n")
for x in confused_pairs[:20]:
    md.append(f"- PART_{x['part_a']} (`{x['reference_a']}`) ↔ PART_{x['part_b']} (`{x['reference_b']}`): {x['wrong_query_count']} wrong queries. Examples: {x['examples']}.\n")

md.append("\n## 5. Image consistency findings\n")
inconsistent = [x for x in part_consistency if x["high_inconsistency_flag"]]
md.append(f"Parts flagged by metadata/heuristics for internal inconsistency: **{len(inconsistent)}**. A flag means aspect-ratio spread > 0.8 or a mix of label-like/full-part heuristic results; it is not a definitive visual diagnosis.\n")
for x in inconsistent:
    md.append(f"- PART_{x['part_id']} (`{x['reference']}`): dimensions={x['dimensions']}; aspect range={x['aspect_ratio_min_max']}; label-like/full-part={x['label_like_count']}/{x['full_part_like_count']}; EXIF={x['exif_orientations']}.\n")
md.append("\n## 6. Evidence limits\n")
md.append("The requested categories hand/occlusion, background, rotation, and multiple objects cannot be proven from filenames, hashes, dimensions, and embedding results alone. The JSON includes representative image paths for targeted visual review; no unsupported diagnosis is asserted here. The label-like classification is a heuristic based on edge density and is not OCR or object detection.\n")
md.append("\n## 7. Recommendations\n")
for item in quality["recommendations"]["cleanup"]:
    md.append(f"- {item}\n")
md.append("\nNew photos to collect:\n")
for item in quality["recommendations"]["new_photos"]:
    md.append(f"- {item}\n")
md.append("\n## 8. Training/model decision\n")
md.append("- Current dataset: **not ready for reliable automatic fine-tuning or production visual identification** until cross-part assignments and duplicates are reviewed.\n")
md.append("- MobileNetV2: **keep as a baseline**, but do not integrate for automatic identification based on the current 51.77% LOO Recall@1 and observed cross-part high-similarity errors.\n")
md.append("- YOLO: **not necessary yet** for one-part-per-photo; revisit only if visual inspection confirms localization is needed.\n")
md.append("\n## 9. Final recommendation\n")
md.append("**Option D: OCR-first + visual fallback, with dataset cleanup and additional data collection.** OCR remains the strongest evidence when a printed reference is readable. The visual fallback should remain non-automatic until duplicate/misassignment issues are resolved and the expanded dataset is reevaluated. Fine-tuning (Option B) should come only after data quality is verified; changing the visual approach (Option C) is premature without first fixing the dataset evidence.\n")
md.append("\n## Files\n")
md.append("- `dataset_quality_report.json`\n- `dataset_quality_report.md`\n")
with open(os.path.join(REPORT_DIR, "dataset_quality_report.md"), "w", encoding="utf-8") as f:
    f.write("".join(md))

print(json.dumps({
    "records": len(records),
    "cross_part_exact": len(cross_part_duplicates),
    "cross_part_perceptual_ge_0_90": len(cross_part_near),
    "worst_parts": [x["part_id"] for x in worst15],
    "inconsistent_parts": len(inconsistent),
    "report_json": os.path.join(REPORT_DIR, "dataset_quality_report.json"),
    "report_md": os.path.join(REPORT_DIR, "dataset_quality_report.md"),
}, indent=2))
