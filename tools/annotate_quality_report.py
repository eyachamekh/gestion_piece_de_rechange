import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
path = os.path.join(ROOT, "spare_parts_dataset", "dataset_quality_report.json")
md_path = os.path.join(ROOT, "spare_parts_dataset", "dataset_quality_report.md")

with open(path, encoding="utf-8") as f:
    report = json.load(f)

diagnoses = {
    6: {
        "categories": ["C different views of same part", "D label close-up vs full-part mismatch"],
        "evidence": "Contact sheet shows the same black Siemens module photographed from several sides plus a close label view. No cross-part exact duplicate was found for this part.",
    },
    11: {
        "categories": ["C different views of same part", "D label close-up vs full-part mismatch"],
        "evidence": "Contact sheet shows a black rectangular Siemens component with broad/full views and separate label/detail views; the views differ substantially in composition.",
    },
    50: {
        "categories": ["B visually similar parts", "C different views of same part"],
        "evidence": "The five photos show a small mechanical assembly from different angles. LOO chose PART_49 for 4/5 queries (mean similarity about 0.6901), indicating visual confusion with that assembly.",
    },
    71: {
        "categories": ["A duplicate/misassigned images"],
        "evidence": "Two images are byte-identical to PART_66 images. All five LOO queries were predicted as PART_66; exact duplicate pairs have similarity 1.0.",
    },
    72: {
        "categories": ["C different views of same part", "D label close-up vs full-part mismatch"],
        "evidence": "Contact sheet shows a yellow module photographed front, rear, side, and label/detail orientations. The composition changes strongly across the five images.",
    },
    5: {
        "categories": ["B visually similar parts", "C different views of same part", "D label close-up vs full-part mismatch"],
        "evidence": "Contact sheet shows a black Siemens device with several side/face views and a label/detail image. LOO confusion is distributed across similar black industrial components.",
    },
    7: {
        "categories": ["B visually similar parts", "C different views of same part"],
        "evidence": "Contact sheet shows a black rectangular device from multiple orientations. LOO most commonly confused it with PART_9 and also with PART_5.",
    },
    8: {
        "categories": ["B visually similar parts", "C different views of same part"],
        "evidence": "Contact sheet shows a black Siemens module photographed from multiple orientations. All four LOO queries were predicted as PART_9; cross-part perceptual pairs also link PART_8 with PART_9 and PART_70.",
    },
    9: {
        "categories": ["B visually similar parts", "C different views of same part"],
        "evidence": "Contact sheet shows a visually similar black module to PART_8/PART_70. LOO most commonly predicted PART_8; the confusion is consistent with similar shape and black housing.",
    },
    32: {
        "categories": ["C different views of same part", "G poor image quality"],
        "evidence": "Contact sheet shows a motor/industrial component with broad, label, and side/detail views. The visible scale and composition vary; no duplicate assignment was established.",
    },
    70: {
        "categories": ["B visually similar parts", "C different views of same part", "D label close-up vs full-part mismatch"],
        "evidence": "Contact sheet shows a black Siemens unit with label close-ups and full/side views. Cross-part perceptual pairs link it to PART_8 and PART_63; LOO also confused it with PART_6.",
    },
    74: {
        "categories": ["C different views of same part", "D label close-up vs full-part mismatch"],
        "evidence": "Contact sheet shows yellow modules in front, rear, side, and connector/detail views. All four LOO queries were predicted as PART_63, indicating strong visual overlap in this dataset.",
    },
    27: {
        "categories": ["G poor image quality", "H rotation/orientation", "J insufficient number of images"],
        "evidence": "Only three images exist and the contact sheet shows a very small metal cylinder photographed at different orientations/scales on a plain background. LOO accuracy is 0/3.",
    },
    29: {
        "categories": ["B visually similar parts", "C different views of same part", "J insufficient number of images"],
        "evidence": "Only three images exist and show a ring-like mechanical part from different angles. LOO most commonly predicted PART_28; the contact sheet shows similar circular hardware across the confused samples.",
    },
    49: {
        "categories": ["B visually similar parts", "C different views of same part", "J insufficient number of images"],
        "evidence": "Only three images exist and show a compact mechanical valve/assembly from different angles. All queries were predicted as PART_50, consistent with a visually similar assembly pair.",
    },
}

for row in report["worst_performing_parts"]:
    row["visual_review"] = diagnoses.get(row["part_id"], {
        "categories": ["K other"],
        "evidence": "No targeted visual annotation was added.",
    })

report["visual_review_method"] = {
    "reviewed_contact_sheets": [
        "spare_parts_dataset/quality_contact_sheets/worst_parts_all.jpg",
        "spare_parts_dataset/quality_contact_sheets/cross_part_suspicious_pairs.jpg",
    ],
    "scope": "Representative images for the 15 worst parts and the highest perceptual cross-part pairs were visually inspected.",
    "limit": "The review does not prove hidden EXIF, object identity, or database intent; categories are limited to visible evidence and the recorded LOO/duplicate results.",
}

with open(path, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)

with open(md_path, "a", encoding="utf-8") as f:
    f.write("\n## 10. Targeted visual review of the 15 worst parts\n")
    f.write("Representative images were inspected in `quality_contact_sheets/worst_parts_all.jpg`. The following diagnoses are evidence-based but limited to visible content plus LOO/duplicate results:\n\n")
    f.write("| Part | Categories | Factual evidence |\n|---:|---|---|\n")
    for row in report["worst_performing_parts"]:
        review = row["visual_review"]
        f.write(f"| {row['part_id']} | {', '.join(review['categories'])} | {review['evidence']} |\n")

print("Annotated", len(diagnoses), "worst parts")
