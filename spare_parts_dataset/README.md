Spare parts dataset export

This dataset was exported from the project's MySQL parts table.

Source images: backend/uploads/ (original files are not moved or modified).

Each part from the parts table was exported into a folder: images/{train,val,test}/PART_<id>/.
Train/val/test split: approx 70/15/15 per part (see dataset_report.json for exact counts).

Notes:
- Images were validated by checking JPEG/PNG file signatures. Files failing the signature check were marked invalid and not copied.
- Missing files (referenced in DB but not found in backend/uploads) are reported in dataset_report.json.
- There are no YOLO bounding-box labels in the repo; this export prepares a classification/embedding dataset (one folder per class).

Limitations:
- Some parts have few images; classes with fewer than 3 images should be considered low-data and may require additional photos for robust training.
- Detection datasets (YOLO) require bounding-box labels which are not present.
