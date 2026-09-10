# Hybrid spare-part identification implementation plan

This is a planning document only. It does not modify Flutter code, OCR, YOLO, model files, MySQL schema, database rows, or existing images.

## Architecture objective

Use the existing database part photos as the visual gallery. The system must preserve every existing part and image, use OCR as the strongest identity evidence, and return ranked candidates rather than guessing when evidence is weak.

```text
Query photo
  |
  +--> OCR preprocessing and Windows OCR
  |      |
  |      +--> raw text and reference candidates
  |      +--> normalized/controlled fuzzy database search
  |
  +--> visual preprocessing
         |
         +--> MobileNetV2 feature vector
                |
                +--> L2-normalized cosine similarity
                       |
                       +--> per-part ranked visual candidates

OCR evidence + visual evidence
  |
  +--> exact OCR match: prioritize that database part
  +--> partial OCR: rank matching parts above visual-only candidates
  +--> no useful OCR: show ranked visual candidates
  +--> weak/ambiguous evidence: NO_CONFIDENT_MATCH plus candidates
```

## A. OCR extraction

Keep the existing Windows OCR bridge and its preprocessing. For each query photo:

1. Apply EXIF orientation correction.
2. Preserve aspect ratio while enlarging small images.
3. Generate the existing corrected/enhanced OCR variant(s).
4. Run the Windows OCR bridge on the original and useful variants.
5. Preserve the complete raw OCR text for logs.
6. Extract:
   - alphanumeric tokens,
   - multi-token combinations,
   - long reference-like strings,
   - number-heavy strings,
   - words that may identify a manufacturer or model family.
7. Keep candidate provenance: source variant, raw token, normalized value, and confidence/heuristic score.

OCR extraction must not hardcode any known reference. It should produce candidates even when punctuation, spaces, or separators are misread.

## B. OCR search against the existing database

The existing `/api/parts/search-reference` endpoint remains the first database lookup surface.

For every high-quality OCR candidate:

1. Normalize to uppercase alphanumeric form.
2. Search exact normalized reference.
3. Search punctuation/spacing-equivalent references.
4. Search controlled fuzzy variants only when the candidate is reference-like.
5. Use controlled OCR confusion alternatives (`O/0`, `I/1`, `S/5`, `B/8`) only for candidate comparison, never as global text replacement.
6. Deduplicate results by part ID.
7. Record match type:
   - `EXACT_REFERENCE`
   - `NORMALIZED_REFERENCE`
   - `FUZZY_REFERENCE`
   - `NO_REFERENCE_MATCH`

Decision behavior:

- One exact normalized database reference is strong OCR evidence and takes priority over visual ranking.
- Multiple OCR hits remain candidates; they must not be silently collapsed into the first row.
- Partial/fuzzy OCR results are evidence, not automatic identity.
- OCR logs must include the query, normalized candidate, database results, and match type.

## C. Existing images as the visual gallery

The 311 existing exported photos remain the gallery. No photos are discarded, moved, merged, or replaced.

Each gallery entry should retain:

- database part ID,
- database reference,
- original image filename,
- image role if later annotated (`overall`, `label`, `connector`, etc.),
- embedding model/version,
- preprocessing version,
- normalized embedding.

Similarity is computed per gallery image, then aggregated per part. The recommended initial per-part score is the maximum similarity among that part's gallery images, while also retaining the strongest matching gallery filename for explanation. A later evaluation can compare max, mean-of-top-k, and robust-average aggregation without changing the gallery.

## D. Ranking multiple candidate parts

For each query:

1. Calculate cosine similarity against every valid gallery embedding.
2. Group scores by part ID.
3. Produce one candidate per part, with:
   - best gallery-image score,
   - second-best gallery-image score if useful,
   - matched gallery filename,
   - reference,
   - part name/details,
   - rank.
4. Sort visual candidates by per-part score.
5. Calculate the best-part versus second-part margin.
6. Keep the top several candidates for display, not only the first.

The existing 51.77% LOO result must remain the baseline. Thresholds must not be changed as part of this plan. Any later threshold decision must be based on a new evaluation using the same metrics and a documented acceptance policy.

## E. Combining OCR and visual evidence

Use a staged evidence policy rather than an uncalibrated arithmetic score:

### Strong OCR

If OCR produces an exact or verified normalized reference:

- return that database part as the prioritized result;
- retain visual candidates for diagnostics;
- do not let a lower visual score override a strong reference match.

### Partial or fuzzy OCR

If OCR returns one or more partial/fuzzy database candidates:

- place those parts above visual-only candidates when the OCR match is meaningful;
- attach OCR match type and candidate text;
- use visual similarity as supporting evidence and tie-breaking;
- if OCR and visual evidence disagree, show the conflicting candidates instead of silently selecting one.

### No useful OCR

Use visual ranking only:

- show multiple candidates;
- apply the approved confidence and margin policy once formally integrated;
- if evidence is weak, show `NO_CONFIDENT_MATCH` rather than selecting rank one automatically.

The combined result should carry evidence fields such as `ocrMatchType`, `ocrCandidate`, `visualScore`, `secondVisualScore`, `margin`, `matchSource`, and `decision`.

## F. Flutter loading/scan flow changes required later

No Flutter files are changed now. During implementation, the main changes will be:

### Scan flow

- Keep the current single-photo flow.
- Optionally add a second-photo mode later:
  - overall/shape photo for visual evidence,
  - label/reference photo for OCR.
- Pass one or two query files into the recognition coordinator.

### Loading flow

Replace the current single-result behavior with a recognition result object containing:

- OCR raw text and candidates,
- database reference candidates,
- visual candidates,
- combined ranking,
- confidence/margin,
- final decision.

The current loading code still reads `embedding1...embedding7` and currently has automatic-navigation paths. The eventual implementation must stop treating those legacy fields as the visual gallery and must not use the existing 7-output classifier values as embeddings.

The loading page should:

- show progress by stage,
- preserve detailed logs,
- navigate directly only for strong OCR,
- navigate to a candidate-selection result for multiple plausible matches,
- show a no-confident-match state when neither branch is reliable.

### Result/candidate flow

Use a dedicated candidate-selection model or result payload instead of overloading a single-part detail map.

## G. Visual embedding model

Use the verified MobileNetV2 feature-vector TFLite model as the initial offline extractor:

- input: `[1, 224, 224, 3]`
- type: `float32`
- preprocessing: RGB, aspect-ratio-preserving resize/crop, MobileNetV2 `[-1, 1]` normalization
- output: `[1, 1280]`
- postprocessing: finite-value check and L2 normalization

It is a general visual baseline, not a guarantee of correct identity. The current `model_unquant.tflite` `[1,7]` classifier must remain excluded from cosine similarity. The generic COCO YOLO model must remain excluded from spare-part identity.

## H. Generating embeddings for the existing 311 images

This should be a controlled offline gallery-build step:

1. Read the existing database-to-image associations.
2. Validate that every referenced image exists and is decodable.
3. Resolve each image to exactly one gallery part entry for the evaluation dataset.
4. Apply the same preprocessing used for query images.
5. Run MobileNetV2.
6. Convert output to float32.
7. Verify dimension `1280`, finite values, and nonzero norm.
8. L2-normalize.
9. Save a local versioned gallery artifact containing:
   - embedding binary,
   - part ID,
   - reference,
   - filename,
   - model checksum/version,
   - preprocessing version.
10. Generate a manifest and duplicate/similarity audit before it becomes production data.

For the first production integration, do not write these vectors into `embedding1...embedding7`. Those fields contain legacy classifier outputs and are not a scalable per-image gallery design.

## I. Embeddings for newly added part images

When an administrator adds a part:

1. Create the part record and upload its own images.
2. Verify each uploaded image belongs to exactly one part ID.
3. Generate embeddings immediately or through a queued local generation job using the same model and preprocessing version.
4. Store one embedding record per image in the future gallery storage.
5. Mark the gallery entry as ready only after finite/dimension checks pass.
6. Include the new part automatically in future visual searches.

No model retraining is required for adding a new part. The gallery grows by adding correctly labeled reference embeddings.

Recommended eventual storage is a separate per-image embedding table or equivalent versioned store with:

- embedding ID,
- part ID,
- image filename,
- embedding bytes/vector,
- dimension,
- model version,
- preprocessing version,
- created timestamp,
- validity/status.

The existing database schema must not be changed until this design is explicitly approved.

## J. Result page with multiple candidates

The result UI should distinguish:

### Strong OCR result

- Show the identified part details.
- Show `Matched by exact/normalized reference`.
- Optionally show the OCR text and reference candidate.

### Candidate list

Show a ranked list such as:

```text
Possible matches
1. PART_A — visual 0.92 — OCR normalized candidate
2. PART_B — visual 0.89 — visually similar
3. PART_C — visual 0.83 — visually similar
```

Each row should include:

- reference,
- part name/description,
- thumbnail/gallery image,
- OCR evidence if present,
- visual score,
- optional margin/confidence explanation.

The user can open/select a candidate to see the existing detail page. Selection must be explicit when the system has not established a strong identity.

## K. No confident match

When evidence is insufficient:

- do not select rank one automatically;
- show `No confident match found`;
- show top candidates when available;
- explain whether the cause was no readable OCR, conflicting OCR, low visual score, small margin, or no usable gallery embeddings;
- allow the user to retry with a label close-up or choose a candidate manually;
- preserve the diagnostics for later review.

This state is a valid outcome, not an error and not a fallback to a random part.

## Future implementation order

1. Freeze the current baseline and preserve all existing gallery images.
2. Approve the candidate-result data model and UI behavior.
3. Build a versioned local gallery manifest for the existing 311 images.
4. Integrate MobileNetV2 extraction without enabling automatic production selection.
5. Add visual candidate ranking and explicit selection.
6. Add OCR/visual evidence merging with strong OCR precedence.
7. Add new-part embedding generation using the same model/version.
8. Run Windows real-image tests, including visually similar pairs.
9. Only then decide whether any confidence/margin policy is appropriate.

## Files expected to change only after approval

- `lib/services/text_recognition_service.dart`: only if candidate metadata or two-photo OCR coordination requires it; preserve the Windows bridge.
- `lib/screens/loading_page.dart`: orchestrate OCR, visual ranking, evidence combination, and no-confident-match behavior.
- `lib/services/image_classifier_service.dart`: replace legacy classifier use with the verified MobileNetV2 embedding interface.
- `lib/services/api_service.dart`: expose gallery/embedding/candidate endpoints if the chosen storage is backend-backed.
- `lib/screens/result_page.dart`: render candidate lists and explicit selection.
- Backend embedding/gallery service and a separate storage migration only after schema approval.

## Explicitly excluded

- Deleting or merging parts/images.
- Treating high visual similarity as proof of bad data.
- Using `model_unquant.tflite` as an embedding.
- Mapping COCO classes to spare parts.
- Hardcoding references.
- Automatic selection from weak visual rank one.
- Claiming perfect or production-ready accuracy before real evaluation.
