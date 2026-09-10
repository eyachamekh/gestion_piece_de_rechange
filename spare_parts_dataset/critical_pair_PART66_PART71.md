# Critical visual-disambiguation case: PART_66 vs PART_71

This is an investigation only. No image, database row, production code, model, or threshold was modified. Byte identity is not treated as proof that either part is incorrect.

## References

- PART_66: `330322028306`
- PART_71: `330322028206`

## All current images

### PART_66
- `1788611051045.jpg`
- `1788611051048.jpg`
- `1788611051054.jpg`
- `1788611051058.jpg`
- `1788611051059.jpg`

### PART_71
- `1788719233395.jpg`
- `1788719233399.jpg`
- `1788719233402.jpg`
- `1788719233405.jpg`
- `1788719233408.jpg`

## Visual evidence

- The contact sheet is `quality_contact_sheets/critical_pair_PART66_PART71.jpg`.
- Both parts show the same-looking yellow safety component across front, side, rear/plate, and detail views.
- Two pairs are byte-identical: `1788611051045.jpg` ↔ `1788719233395.jpg`, and `1788611051048.jpg` ↔ `1788719233399.jpg`.
- No reliable dimensional, connector, mounting, shape, or suffix difference is visible in the current photos.
- A small real product/version difference remains possible; the current images do not prove or disprove it.

## Printed reference/label

The images contain printed/detail regions, but the present image scale and views do not establish a readable reference-specific suffix for both parts. A dedicated high-resolution label close-up is required.

## Answers

- **A. MobileNetV2:** No reliable conclusion that MobileNetV2 can distinguish PART_66 from PART_71. Current LOO results show PART_71 was predicted as PART_66 for all five queries, including similarity 1.0 for the byte-identical images.
- **B. Additional photos:** Collect controlled side-by-side photos of each part with a scale/ruler, connector and mounting faces, top/bottom/side views, and macro close-ups of every label, suffix, connector, hole pattern, and dimensional marking. Capture the same view and lighting for both references.
- **C. OCR:** Yes, OCR is likely better if the distinguishing reference/suffix is printed and readable. OCR should be performed on a dedicated high-resolution label close-up; it should win over visual similarity.
- **D. Fine-tuning:** Fine-tuning may be necessary only if a repeatable physical difference is visible but not represented by the generic feature extractor. It cannot solve identical pixels or missing visual evidence; the first requirement is correctly labeled, discriminative photos.

## Required photo set

For each reference, capture the same controlled set: full front/back/top/bottom/left/right views; connector face; mounting face and hole pattern; ruler/caliper or dimension-marking view; macro label close-up; and one neutral-background overall photo. Keep the two references physically separated and manually verified.
