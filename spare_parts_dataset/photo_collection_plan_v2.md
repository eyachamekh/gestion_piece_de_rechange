# Photo collection plan v2

This plan prepares a second objective MobileNetV2 evaluation. It does not modify production code, OCR, YOLO, MySQL, existing images, models, or thresholds. The goal is to collect **distinguishing information**, not merely increase the image count.

## 1. Overall collection strategy

- Current baseline remains unchanged: 76 parts, 311 images, LOO Recall@1 approximately 51.77%.
- Target approximately 8–12 correctly labeled images per part after collection. The exact number may be lower when an angle has no physical meaning.
- For every confusing pair, collect the same controlled view of each physical part so the distinguishing feature can be compared directly.
- Capture the feature that actually separates the parts: connector, mounting pattern, dimensions, shape detail, printed suffix, pin count, or another verified feature. Do not assume which feature exists.
- Keep label/reference close-ups separate from overall/shape photos in the collection notes, while retaining the same single part ID for every image.

## Priority counts

- Priority 1: **30 parts** (15 worst-performing parts plus both sides of every recorded high-confusion pair)
- Priority 2: **18 parts** (remaining parts with exactly 3 current images)
- Priority 3: **28 parts** (all remaining parts)

## 2. Priority 1 parts

These parts need targeted collection first. The CSV contains the complete reason and confusion list for each part.

| Part | Reference | Current images | Problem/confusion | New images |
|---:|---|---:|---|---|
| PART_2 | `330322011306` | 6 | Baseline part not in the 15 worst-performing classes; confused with: PART_6; PART_11 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_5 | `3303220111` | 4 | LOO accuracy 0.0%; B visually similar parts and C different views of same part and D label close-up vs full-part mismatch; confused with: PART_11 (2 wrong, max sim 0.705); PART_12 (1 wrong, max sim 0.751); PART_7 (1 wrong, max sim 0.661) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_6 | `330322009706` | 5 | LOO accuracy 0.0%; C different views of same part and D label close-up vs full-part mismatch; confused with: PART_12 (1 wrong, max sim 0.693); PART_70 (1 wrong, max sim 0.661); PART_71 (1 wrong, max sim 0.693) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_7 | `330322026206` | 4 | LOO accuracy 0.0%; B visually similar parts and C different views of same part; confused with: PART_9 (2 wrong, max sim 0.717); PART_5 (1 wrong, max sim 0.661); PART_11 (1 wrong, max sim 0.802) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_8 | `330322022506` | 4 | LOO accuracy 0.0%; B visually similar parts and C different views of same part; confused with: PART_9 (4 wrong, max sim 0.769) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_9 | `330322026106` | 4 | LOO accuracy 0.0%; B visually similar parts and C different views of same part; confused with: PART_8 (2 wrong, max sim 0.769); PART_7 (1 wrong, max sim 0.712); PART_11 (1 wrong, max sim 0.773) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_11 | `330318009406` | 5 | LOO accuracy 0.0%; C different views of same part and D label close-up vs full-part mismatch; confused with: PART_60 (1 wrong, max sim 0.720); PART_2 (1 wrong, max sim 0.633); PART_7 (1 wrong, max sim 0.802) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_12 | `3303220109` | 5 | Baseline part not in the 15 worst-performing classes; confused with: PART_5; PART_11 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_13 | `3303220120` | 4 | Baseline part not in the 15 worst-performing classes; confused with: PART_15 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_15 | `3303220323` | 3 | Baseline part not in the 15 worst-performing classes; confused with: PART_13; PART_41 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_17 | `330322035606` | 3 | Baseline part not in the 15 worst-performing classes; confused with: PART_18 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_18 | `330322035606` | 4 | Baseline part not in the 15 worst-performing classes; confused with: PART_17 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_24 | `330322034006` | 3 | Baseline part not in the 15 worst-performing classes; confused with: PART_38 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_27 | `3303220169` | 3 | LOO accuracy 0.0%; G poor image quality and H rotation/orientation and J insufficient number of images; confused with: PART_45 (2 wrong, max sim 0.643); PART_69 (1 wrong, max sim 0.554) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_28 | `330322012706` | 4 | Baseline part not in the 15 worst-performing classes; confused with: PART_29 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_29 | `330322008506` | 3 | LOO accuracy 0.0%; B visually similar parts and C different views of same part and J insufficient number of images; confused with: PART_28 (2 wrong, max sim 0.717); PART_42 (1 wrong, max sim 0.651) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_32 | `3303220100` | 4 | LOO accuracy 0.0%; C different views of same part and G poor image quality; confused with: PART_40 (2 wrong, max sim 0.631); PART_69 (1 wrong, max sim 0.560); PART_68 (1 wrong, max sim 0.699) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_38 | `3303220137` | 4 | Baseline part not in the 15 worst-performing classes; confused with: PART_24 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_40 | `330322014706` | 6 | Baseline part not in the 15 worst-performing classes; confused with: PART_43; PART_32 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_41 | `330322029606` | 3 | Baseline part not in the 15 worst-performing classes; confused with: PART_15 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_43 | `3303220145` | 5 | Baseline part not in the 15 worst-performing classes; confused with: PART_40 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_45 | `3303220152` | 3 | Baseline part not in the 15 worst-performing classes; confused with: PART_27 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_49 | `3303220175` | 3 | LOO accuracy 0.0%; B visually similar parts and C different views of same part and J insufficient number of images; confused with: PART_50 (3 wrong, max sim 0.722) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_50 | `3303220176` | 5 | LOO accuracy 0.0%; B visually similar parts and C different views of same part; confused with: PART_49 (4 wrong, max sim 0.722); PART_25 (1 wrong, max sim 0.657) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_63 | `330322028106` | 6 | Baseline part not in the 15 worst-performing classes; confused with: PART_74 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_66 | `330322028306` | 5 | Critical visual-disambiguation pair; current images include byte-identical cross-part pairs; confused with: PART_66 and PART_71 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_70 | `330322026906` | 4 | LOO accuracy 0.0%; B visually similar parts and C different views of same part and D label close-up vs full-part mismatch; confused with: PART_6 (2 wrong, max sim 0.661); PART_75 (1 wrong, max sim 0.599); PART_11 (1 wrong, max sim 0.543) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_71 | `330322028206` | 5 | Critical visual-disambiguation pair; current images include byte-identical cross-part pairs; confused with: PART_66 and PART_71 | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_72 | `330322009506` | 5 | LOO accuracy 0.0%; C different views of same part and D label close-up vs full-part mismatch; confused with: PART_63 (2 wrong, max sim 0.652); PART_75 (1 wrong, max sim 0.574); PART_65 (1 wrong, max sim 0.572) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |
| PART_74 | `3303220104` | 4 | LOO accuracy 0.0%; C different views of same part and D label close-up vs full-part mismatch; confused with: PART_63 (4 wrong, max sim 0.776) | 5-9 new images: matched overall/front/back/side views, connector or mounting detail as applicable, and a high-resolution label plus the suspected distinguishing feature. |

## 3. Priority 2 parts

These classes have only three current images, so their evaluation is especially sensitive to viewpoint and photo quality.

| Part | Reference | Current images | Problem/confusion | New images |
|---:|---|---:|---|---|
| PART_10 | `330322016306` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_21 | `330322005806` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_30 | `330322020806` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_31 | `330322025206` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_33 | `3303220173` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_34 | `330322025406` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_37 | `330322008106` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_39 | `3303220069` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_42 | `330322029806` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_46 | `330322020406` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_47 | `3303220144` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_51 | `3303220133` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_52 | `330322031906` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_54 | `330322031106` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_57 | `330322031706` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_58 | `3303220139` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_61 | `3303220005` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |
| PART_76 | `330322029006` | 3 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 5-9 new images: consistent overall views, at least two different orientations, label/reference close-up, and the most likely distinguishing detail. |

## 4. Priority 3 parts

These parts are not currently the highest risk, but should still receive consistent reference and distinguishing-feature photos.

| Part | Reference | Current images | Problem/confusion | New images |
|---:|---|---:|---|---|
| PART_1 | `330322031306` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_3 | `33032201206` | 6 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_4 | `3303220107` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_14 | `3303220178` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_16 | `330322021706` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_19 | `330322022306` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_20 | `330322005406` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_22 | `330322029706` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_23 | `330322022706` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_25 | `330322015806` | 6 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_26 | `330322015806` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_35 | `330322018906` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_36 | `330322024606` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_44 | `330322022906` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_48 | `3303220001` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_53 | `` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_55 | `330322012806` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_56 | `330322031806` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_59 | `330322003806` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_60 | `3303220179` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_62 | `330322025606` | 6 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_64 | `330322026406` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_65 | `3303220105` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_67 | `330322029106` | 4 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_68 | `330322031506` | 6 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_69 | `330322027806` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_73 | `330322027206` | 5 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |
| PART_75 | `330322022106` | 6 | Baseline part not in the 15 worst-performing classes; confused with: None recorded | 3-6 new images: overall view, one alternate orientation, readable label/reference close-up, and any part-specific distinguishing feature. |

## 5. PART_66 / PART_71 special plan

- PART_66 reference: `330322028306`
- PART_71 reference: `330322028206`
- Do not delete, merge, relabel, or copy any existing image.
- The current photos include byte-identical pairs, but this is not treated as proof of incorrect data. The two physical references may differ by a small feature that the photos do not show.
- Photograph each physical part independently, then compare the matched views side-by-side:
  1. full front and full back;
  2. left and right sides;
  3. top and bottom;
  4. connector/interface face and pin count;
  5. mounting face, holes, clips, and keying;
  6. dimensions or ruler/caliper view where relevant;
  7. high-resolution label and exact reference/suffix;
  8. macro of any feature that differs when the parts are placed side-by-side;
  9. one neutral-background overall view for each part.
- Do not invent a difference. If no difference is visible, record that the distinction remains unknown and rely on a readable reference/OCR close-up.

## 6. Standard photo protocol

For each part, aim for the following set, omitting only physically meaningless views:

1. Full overall view
2. Front
3. Back
4. Side
5. Opposite side
6. Connector/interface
7. Mounting area
8. Label/reference close-up
9. Close-up of the known or suspected distinguishing feature
10. Different orientation
11. Hand-held example, if hand-held use is expected
12. Different lighting/background

The most important image is the one showing the feature that separates this part from its closest confusing part. A generic additional angle is less valuable than a clear connector, suffix, hole pattern, dimension, or shape-detail photo.

## 7. Image labeling rules

- Every image must belong to exactly one database part ID.
- Record the database part ID and reference at capture time.
- Use a filename that preserves the single part identity, for example `PART_66_label_closeup_01.jpg`.
- Record the view/condition in accompanying collection notes: `overall`, `connector`, `mounting`, `label`, `distinguishing_feature`, `handheld`, `low_light`, etc.
- Verify the physical item and printed reference before assigning the image.

## 8. Rules preventing cross-part image duplication

- Never reuse one physical photo under two part IDs.
- Never copy an image between class folders.
- If the same scene contains two parts, photograph and crop each part separately only if each resulting image is independently captured/verified and assigned to one part; do not use one identical crop for both.
- Before the next evaluation, compute byte hashes and perceptual similarity again, but treat high similarity as a review flag—not an automatic data error.
- For visually identical-looking parts, collect separate photos with the two physical items separated and the distinguishing evidence visible.

## 9. Recommended collection amount and evaluation split

- Collect enough new images to reach approximately 8–12 total images per part, prioritizing discriminative views over volume.
- Keep newly collected images separate from the current baseline until verified.
- Do not change the existing baseline or thresholds before rerunning the same evaluation protocol.
- After collection, re-run duplicate review, then evaluate with leave-one-out and repeated 1-shot/2-shot tests using the same metrics. Compare results objectively to the 51.77% LOO baseline.

## 10. Exact conditions to photograph

- Printed reference, model number, suffix, and dimensions at readable resolution.
- Connector face, pin count, keying, terminal arrangement, and cable/interface details.
- Mounting holes, clips, tabs, brackets, threads, and physical interfaces.
- Profile, height, width, thickness, openings, grooves, and other shape details.
- Front/back/top/bottom/side views with consistent scale for confusing pairs.
- Clean neutral background plus realistic hand-held/background examples.
- Lighting that avoids glare on labels and dark shadows on physical details.

## 11. Files

- `photo_collection_priority.csv`: one row per part with priority, confusion, problem, and recommended new images.
- This plan intentionally does not modify production code, database contents, OCR, YOLO, model files, or thresholds.
