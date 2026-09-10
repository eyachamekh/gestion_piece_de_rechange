# Dataset quality investigation
Read-only investigation of the exported dataset, existing LOO results, and per-part report. No images, database rows, app code, models, or thresholds were modified.
## 1. Dataset overview
- Parts/classes: **76**
- Images inspected: **311**
- Per-part count: **3–6**
- Read/decoding errors: **0**
- EXIF orientation tags present: **0**
- Heuristic label-like images: **114** (not proof of a label)
- Images with short side under 640 px: **0**
## 2. Cross-part duplicates and leakage
- Exact cross-part duplicate pairs: **2**
- Perceptual cross-part pairs at phash similarity >= 0.90: **21**
- PART_66 `1788611051045.jpg` ↔ PART_71 `1788719233395.jpg`; exact=True; perceptual=1.0000; sizes=102293/102293; refs=`330322028306` / `330322028206`.
- PART_66 `1788611051048.jpg` ↔ PART_71 `1788719233399.jpg`; exact=True; perceptual=1.0000; sizes=63966/63966; refs=`330322028306` / `330322028206`.
- PART_63 `1788609758215.jpg` ↔ PART_70 `1788719100281.jpg`; exact=False; perceptual=0.9424; sizes=77851/131118; refs=`330322028106` / `330322026906`.
- PART_8 `1788451498585.jpg` ↔ PART_9 `1788451850704.jpg`; exact=False; perceptual=0.9277; sizes=111670/104243; refs=`330322022506` / `330322026106`.
- PART_28 `1788471435412.jpg` ↔ PART_70 `1788719100288.jpg`; exact=False; perceptual=0.9248; sizes=87729/107108; refs=`330322012706` / `330322026906`.
- PART_46 `1788483651237.jpg` ↔ PART_57 `1788540416972.jpg`; exact=False; perceptual=0.9209; sizes=71804/65201; refs=`330322020406` / `330322031706`.
- PART_38 `1788477748442.jpg` ↔ PART_47 `1788488930424.jpg`; exact=False; perceptual=0.9189; sizes=72970/94999; refs=`3303220137` / `3303220144`.
- PART_27 `1788471179762.jpg` ↔ PART_47 `1788488930424.jpg`; exact=False; perceptual=0.9121; sizes=50629/94999; refs=`3303220169` / `3303220144`.
- PART_29 `1788471685917.jpg` ↔ PART_59 `1788541484672.jpg`; exact=False; perceptual=0.9121; sizes=55335/78402; refs=`330322008506` / `330322003806`.
- PART_8 `1788451498588.jpg` ↔ PART_70 `1788719100281.jpg`; exact=False; perceptual=0.9102; sizes=109958/131118; refs=`330322022506` / `330322026906`.
- PART_7 `1788451354795.jpg` ↔ PART_8 `1788451498606.jpg`; exact=False; perceptual=0.9092; sizes=97627/130398; refs=`330322026206` / `330322022506`.
- PART_8 `1788451498588.jpg` ↔ PART_63 `1788609758215.jpg`; exact=False; perceptual=0.9092; sizes=109958/77851; refs=`330322022506` / `330322028106`.
- PART_19 `1788457619682.jpg` ↔ PART_73 `1788720063750.jpg`; exact=False; perceptual=0.9082; sizes=87636/87502; refs=`330322022306` / `330322027206`.
- PART_56 `1788539677631.jpg` ↔ PART_59 `1788541484668.jpg`; exact=False; perceptual=0.9053; sizes=93938/84592; refs=`330322031806` / `330322003806`.
- PART_70 `1788719100281.jpg` ↔ PART_75 `1788725677220.jpg`; exact=False; perceptual=0.9043; sizes=131118/102033; refs=`330322026906` / `330322022106`.
- PART_27 `1788471179762.jpg` ↔ PART_38 `1788477748442.jpg`; exact=False; perceptual=0.9033; sizes=50629/72970; refs=`3303220169` / `3303220137`.
- PART_29 `1788471685918.jpg` ↔ PART_47 `1788488930423.jpg`; exact=False; perceptual=0.9023; sizes=42898/96517; refs=`330322008506` / `3303220144`.
- PART_6 `1788450414666.jpg` ↔ PART_8 `1788451498588.jpg`; exact=False; perceptual=0.9014; sizes=262235/109958; refs=`330322009706` / `330322022506`.
- PART_69 `1788719010163.jpg` ↔ PART_72 `1788719717757.jpg`; exact=False; perceptual=0.9014; sizes=129782/86377; refs=`330322027806` / `330322009506`.
- PART_17 `1788457271499.jpg` ↔ PART_23 `1788458304674.jpg`; exact=False; perceptual=0.9004; sizes=95032/85122; refs=`330322035606` / `330322022706`.
- PART_43 `1788482685714.jpg` ↔ PART_47 `1788488930424.jpg`; exact=False; perceptual=0.9004; sizes=140137/94999; refs=`3303220145` / `3303220144`.
These findings must be manually verified before cleanup. If the same physical photo is assigned to different parts, LOO can produce irreducible ties or confidently wrong predictions; it can also distort threshold analysis because a wrong class may have similarity 1.0.
## 3. Fifteen worst-performing parts
| Part | Reference | Images | Correct/total | Accuracy | Most common wrong prediction |
|---:|---|---:|---:|---:|---|
| 6 | `330322009706` | 5 | 0/5 | 0.000 | PART_12 (1x, max sim 0.6930) |
| 11 | `330318009406` | 5 | 0/5 | 0.000 | PART_60 (1x, max sim 0.7195) |
| 50 | `3303220176` | 5 | 0/5 | 0.000 | PART_49 (4x, max sim 0.7217) |
| 71 | `330322028206` | 5 | 0/5 | 0.000 | PART_66 (5x, max sim 1.0000) |
| 72 | `330322009506` | 5 | 0/5 | 0.000 | PART_63 (2x, max sim 0.6516) |
| 5 | `3303220111` | 4 | 0/4 | 0.000 | PART_11 (2x, max sim 0.7046) |
| 7 | `330322026206` | 4 | 0/4 | 0.000 | PART_9 (2x, max sim 0.7169) |
| 8 | `330322022506` | 4 | 0/4 | 0.000 | PART_9 (4x, max sim 0.7693) |
| 9 | `330322026106` | 4 | 0/4 | 0.000 | PART_8 (2x, max sim 0.7693) |
| 32 | `3303220100` | 4 | 0/4 | 0.000 | PART_40 (2x, max sim 0.6315) |
| 70 | `330322026906` | 4 | 0/4 | 0.000 | PART_6 (2x, max sim 0.6612) |
| 74 | `3303220104` | 4 | 0/4 | 0.000 | PART_63 (4x, max sim 0.7758) |
| 27 | `3303220169` | 3 | 0/3 | 0.000 | PART_45 (2x, max sim 0.6432) |
| 29 | `330322008506` | 3 | 0/3 | 0.000 | PART_28 (2x, max sim 0.7166) |
| 49 | `3303220175` | 3 | 0/3 | 0.000 | PART_50 (3x, max sim 0.7217) |

Detailed per-query evidence is in `loo_results.json`; full per-part evidence is in `dataset_quality_report.json`.
## 4. Most-confused pairs
- PART_66 (`330322028306`) ↔ PART_71 (`330322028206`): 9 wrong queries. Examples: [{'query': 'PART_66\\1788611051045.jpg', 'best_similarity': 0.9999998807907104, 'margin': 0.3579002618789673}, {'query': 'PART_66\\1788611051048.jpg', 'best_similarity': 1.0, 'margin': 0.24863171577453613}, {'query': 'PART_66\\1788611051054.jpg', 'best_similarity': 0.8455907106399536, 'margin': 0.2496722936630249}].
- PART_63 (`330322028106`) ↔ PART_74 (`3303220104`): 8 wrong queries. Examples: [{'query': 'PART_63\\1788609758185.jpg', 'best_similarity': 0.7758092284202576, 'margin': 0.1242329478263855}, {'query': 'PART_63\\1788609758189.jpg', 'best_similarity': 0.6646287441253662, 'margin': 0.031209588050842285}, {'query': 'PART_63\\1788609758203.jpg', 'best_similarity': 0.5804760456085205, 'margin': 0.021449685096740723}].
- PART_49 (`3303220175`) ↔ PART_50 (`3303220176`): 7 wrong queries. Examples: [{'query': 'PART_49\\1788518826556.jpg', 'best_similarity': 0.6518201231956482, 'margin': 0.03438633680343628}, {'query': 'PART_49\\1788518826558.jpg', 'best_similarity': 0.7216699123382568, 'margin': 0.10422968864440918}, {'query': 'PART_50\\1788519813099.jpg', 'best_similarity': 0.6818874478340149, 'margin': 0.046879708766937256}].
- PART_40 (`330322014706`) ↔ PART_43 (`3303220145`): 6 wrong queries. Examples: [{'query': 'PART_40\\1788481292636.jpg', 'best_similarity': 0.610646665096283, 'margin': 0.021777749061584473}, {'query': 'PART_40\\1788481292642.jpg', 'best_similarity': 0.6389161944389343, 'margin': 0.02231079339981079}, {'query': 'PART_43\\1788482685709.jpg', 'best_similarity': 0.6301050782203674, 'margin': 0.007169783115386963}].
- PART_8 (`330322022506`) ↔ PART_9 (`330322026106`): 6 wrong queries. Examples: [{'query': 'PART_8\\1788451498585.jpg', 'best_similarity': 0.7693384885787964, 'margin': 0.060683608055114746}, {'query': 'PART_8\\1788451498588.jpg', 'best_similarity': 0.6983388662338257, 'margin': 0.00780940055847168}, {'query': 'PART_9\\1788451850704.jpg', 'best_similarity': 0.7693384885787964, 'margin': 0.08130580186843872}].
- PART_28 (`330322012706`) ↔ PART_29 (`330322008506`): 4 wrong queries. Examples: [{'query': 'PART_28\\1788471435405.jpg', 'best_similarity': 0.6622765064239502, 'margin': 0.005862534046173096}, {'query': 'PART_28\\1788471435407.jpg', 'best_similarity': 0.7166118621826172, 'margin': 0.060243070125579834}, {'query': 'PART_29\\1788471685917.jpg', 'best_similarity': 0.6622765064239502, 'margin': 0.006228923797607422}].
- PART_32 (`3303220100`) ↔ PART_40 (`330322014706`): 4 wrong queries. Examples: [{'query': 'PART_40\\1788481292640.jpg', 'best_similarity': 0.6156671643257141, 'margin': 0.020390450954437256}, {'query': 'PART_32\\1788472292589.jpg', 'best_similarity': 0.6156671643257141, 'margin': 0.004014015197753906}, {'query': 'PART_32\\1788472292590.jpg', 'best_similarity': 0.6314656734466553, 'margin': 0.024203181266784668}].
- PART_2 (`330322011306`) ↔ PART_6 (`330322009706`): 3 wrong queries. Examples: [{'query': 'PART_2\\1788424613906.jpg', 'best_similarity': 0.6920993328094482, 'margin': 0.005842983722686768}, {'query': 'PART_2\\1788424613917.jpg', 'best_similarity': 0.6750187873840332, 'margin': 0.02170586585998535}, {'query': 'PART_6\\1788450414658.jpg', 'best_similarity': 0.6750187873840332, 'margin': 0.04468536376953125}].
- PART_27 (`3303220169`) ↔ PART_45 (`3303220152`): 3 wrong queries. Examples: [{'query': 'PART_27\\1788471179759.jpg', 'best_similarity': 0.6364928483963013, 'margin': 0.003687262535095215}, {'query': 'PART_27\\1788471179762.jpg', 'best_similarity': 0.6431884169578552, 'margin': 0.01038283109664917}, {'query': 'PART_45\\1788483040997.jpg', 'best_similarity': 0.6431884169578552, 'margin': 0.007404983043670654}].
- PART_5 (`3303220111`) ↔ PART_11 (`330318009406`): 3 wrong queries. Examples: [{'query': 'PART_5\\1788450237355.jpg', 'best_similarity': 0.6525644063949585, 'margin': 0.03365945816040039}, {'query': 'PART_11\\1788452269932.jpg', 'best_similarity': 0.7045507431030273, 'margin': 0.0887444019317627}, {'query': 'PART_5\\1788450237372.jpg', 'best_similarity': 0.7045507431030273, 'margin': 0.08987540006637573}].
- PART_6 (`330322009706`) ↔ PART_70 (`330322026906`): 3 wrong queries. Examples: [{'query': 'PART_6\\1788450414650.jpg', 'best_similarity': 0.6612206101417542, 'margin': 0.018410027027130127}, {'query': 'PART_70\\1788719100281.jpg', 'best_similarity': 0.6128426790237427, 'margin': 0.007367968559265137}, {'query': 'PART_70\\1788719100290.jpg', 'best_similarity': 0.6612206101417542, 'margin': 0.033740341663360596}].
- PART_7 (`330322026206`) ↔ PART_9 (`330322026106`): 3 wrong queries. Examples: [{'query': 'PART_7\\1788451354795.jpg', 'best_similarity': 0.7168818712234497, 'margin': 0.007824897766113281}, {'query': 'PART_7\\1788451354824.jpg', 'best_similarity': 0.7117276191711426, 'margin': 0.04100733995437622}, {'query': 'PART_9\\1788451850719.jpg', 'best_similarity': 0.711727499961853, 'margin': 0.06379234790802002}].
- PART_2 (`330322011306`) ↔ PART_11 (`330318009406`): 2 wrong queries. Examples: [{'query': 'PART_11\\1788452269916.jpg', 'best_similarity': 0.6326060891151428, 'margin': 0.02204221487045288}, {'query': 'PART_2\\1788424613903.jpg', 'best_similarity': 0.5963620543479919, 'margin': 0.006611526012420654}].
- PART_7 (`330322026206`) ↔ PART_11 (`330318009406`): 2 wrong queries. Examples: [{'query': 'PART_11\\1788452269918.jpg', 'best_similarity': 0.8017175197601318, 'margin': 0.028792738914489746}, {'query': 'PART_7\\1788451354802.jpg', 'best_similarity': 0.8017175197601318, 'margin': 0.041155457496643066}].
- PART_5 (`3303220111`) ↔ PART_12 (`3303220109`): 2 wrong queries. Examples: [{'query': 'PART_12\\1788455263022.jpg', 'best_similarity': 0.7507228255271912, 'margin': 0.013815224170684814}, {'query': 'PART_5\\1788450237361.jpg', 'best_similarity': 0.7507228255271912, 'margin': 0.04279220104217529}].
- PART_11 (`330318009406`) ↔ PART_12 (`3303220109`): 2 wrong queries. Examples: [{'query': 'PART_12\\1788455263034.jpg', 'best_similarity': 0.6683527231216431, 'margin': 0.05559808015823364}, {'query': 'PART_11\\1788452269929.jpg', 'best_similarity': 0.6683527231216431, 'margin': 0.01578831672668457}].
- PART_13 (`3303220120`) ↔ PART_15 (`3303220323`): 2 wrong queries. Examples: [{'query': 'PART_13\\1788455879603.jpg', 'best_similarity': 0.7394241094589233, 'margin': 0.11613333225250244}, {'query': 'PART_15\\1788456788622.jpg', 'best_similarity': 0.7394241094589233, 'margin': 0.06537479162216187}].
- PART_15 (`3303220323`) ↔ PART_41 (`330322029606`): 2 wrong queries. Examples: [{'query': 'PART_15\\1788456788627.jpg', 'best_similarity': 0.6587599515914917, 'margin': 0.039189934730529785}, {'query': 'PART_41\\1788481469369.jpg', 'best_similarity': 0.6587599515914917, 'margin': 0.03726613521575928}].
- PART_17 (`330322035606`) ↔ PART_18 (`330322035606`): 2 wrong queries. Examples: [{'query': 'PART_17\\1788457271496.jpg', 'best_similarity': 0.7768657207489014, 'margin': 0.16698002815246582}, {'query': 'PART_18\\1788457522914.jpg', 'best_similarity': 0.7768657207489014, 'margin': 0.08064919710159302}].
- PART_24 (`330322034006`) ↔ PART_38 (`3303220137`): 2 wrong queries. Examples: [{'query': 'PART_24\\1788458395030.jpg', 'best_similarity': 0.6377390623092651, 'margin': 0.005775332450866699}, {'query': 'PART_24\\1788458395033.jpg', 'best_similarity': 0.74961918592453, 'margin': 0.07326674461364746}].

## 5. Image consistency findings
Parts flagged by metadata/heuristics for internal inconsistency: **43**. A flag means aspect-ratio spread > 0.8 or a mix of label-like/full-part heuristic results; it is not a definitive visual diagnosis.
- PART_1 (`330322031306`): dimensions=['1200x1600']; aspect range=(0.75, 0.75); label-like/full-part=4/1; EXIF={'none': 5}.
- PART_2 (`330322011306`): dimensions=['1200x1600', '1600x1200', '688x1600']; aspect range=(0.43, 1.3333333333333333); label-like/full-part=3/3; EXIF={'none': 6}.
- PART_3 (`33032201206`): dimensions=['1200x1600', '1600x1200']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/5; EXIF={'none': 6}.
- PART_4 (`3303220107`): dimensions=['1200x1600', '1600x1200']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=3/1; EXIF={'none': 4}.
- PART_5 (`3303220111`): dimensions=['1200x1600']; aspect range=(0.75, 0.75); label-like/full-part=2/2; EXIF={'none': 4}.
- PART_6 (`330322009706`): dimensions=['1200x1600', '1600x1200']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=2/3; EXIF={'none': 5}.
- PART_7 (`330322026206`): dimensions=['1200x1600', '1600x1200']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_8 (`330322022506`): dimensions=['1600x1200']; aspect range=(1.3333333333333333, 1.3333333333333333); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_9 (`330322026106`): dimensions=['1200x1600', '1280x740', '1600x1200']; aspect range=(0.75, 1.7297297297297298); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_10 (`330322016306`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=2/1; EXIF={'none': 3}.
- PART_11 (`330318009406`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/4; EXIF={'none': 5}.
- PART_12 (`3303220109`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=2/3; EXIF={'none': 5}.
- PART_13 (`3303220120`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_17 (`330322035606`): dimensions=['1280x960']; aspect range=(1.3333333333333333, 1.3333333333333333); label-like/full-part=1/2; EXIF={'none': 3}.
- PART_18 (`330322035606`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_19 (`330322022306`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_21 (`330322005806`): dimensions=['1216x1280', '960x1280']; aspect range=(0.75, 0.95); label-like/full-part=2/1; EXIF={'none': 3}.
- PART_22 (`330322029706`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_23 (`330322022706`): dimensions=['1280x960']; aspect range=(1.3333333333333333, 1.3333333333333333); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_29 (`330322008506`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/2; EXIF={'none': 3}.
- PART_30 (`330322020806`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=2/1; EXIF={'none': 3}.
- PART_32 (`3303220100`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=3/1; EXIF={'none': 4}.
- PART_33 (`3303220173`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=2/1; EXIF={'none': 3}.
- PART_34 (`330322025406`): dimensions=['1200x1600', '960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/2; EXIF={'none': 3}.
- PART_35 (`330322018906`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=4/1; EXIF={'none': 5}.
- PART_36 (`330322024606`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_38 (`3303220137`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_40 (`330322014706`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=4/2; EXIF={'none': 6}.
- PART_42 (`330322029806`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/2; EXIF={'none': 3}.
- PART_43 (`3303220145`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=3/2; EXIF={'none': 5}.
- PART_49 (`3303220175`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/2; EXIF={'none': 3}.
- PART_50 (`3303220176`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=3/2; EXIF={'none': 5}.
- PART_55 (`330322012806`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=2/2; EXIF={'none': 4}.
- PART_58 (`3303220139`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/2; EXIF={'none': 3}.
- PART_59 (`330322003806`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=2/3; EXIF={'none': 5}.
- PART_60 (`3303220179`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/4; EXIF={'none': 5}.
- PART_66 (`330322028306`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=1/4; EXIF={'none': 5}.
- PART_68 (`330322031506`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=2/4; EXIF={'none': 6}.
- PART_69 (`330322027806`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=3/2; EXIF={'none': 5}.
- PART_70 (`330322026906`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/3; EXIF={'none': 4}.
- PART_72 (`330322009506`): dimensions=['1280x960', '960x1280']; aspect range=(0.75, 1.3333333333333333); label-like/full-part=1/4; EXIF={'none': 5}.
- PART_73 (`330322027206`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=2/3; EXIF={'none': 5}.
- PART_75 (`330322022106`): dimensions=['960x1280']; aspect range=(0.75, 0.75); label-like/full-part=2/4; EXIF={'none': 6}.

## 6. Evidence limits
The requested categories hand/occlusion, background, rotation, and multiple objects cannot be proven from filenames, hashes, dimensions, and embedding results alone. The JSON includes representative image paths for targeted visual review; no unsupported diagnosis is asserted here. The label-like classification is a heuristic based on edge density and is not OCR or object detection.

## 7. Recommendations
- Manually review every cross-part exact/perceptual duplicate before training or threshold tuning.
- Confirm each database image-to-part association; do not delete automatically.
- Keep query/gallery images disjoint during evaluation.
- Separate label close-ups and full-part photos as explicit image roles if possible.

New photos to collect:
- Collect at least 8-12 images per part: overall views, multiple rotations, consistent distance, varied lighting/backgrounds.
- Add a dedicated readable-label close-up when a reference exists.
- Capture no-hand images and separately labeled hand-held images.
- Prioritize parts with 0% or low LOO accuracy and the most confused pairs.

## 8. Training/model decision
- Current dataset: **not ready for reliable automatic fine-tuning or production visual identification** until cross-part assignments and duplicates are reviewed.
- MobileNetV2: **keep as a baseline**, but do not integrate for automatic identification based on the current 51.77% LOO Recall@1 and observed cross-part high-similarity errors.
- YOLO: **not necessary yet** for one-part-per-photo; revisit only if visual inspection confirms localization is needed.

## 9. Final recommendation
**Option D: OCR-first + visual fallback, with dataset cleanup and additional data collection.** OCR remains the strongest evidence when a printed reference is readable. The visual fallback should remain non-automatic until duplicate/misassignment issues are resolved and the expanded dataset is reevaluated. Fine-tuning (Option B) should come only after data quality is verified; changing the visual approach (Option C) is premature without first fixing the dataset evidence.

## Files
- `dataset_quality_report.json`
- `dataset_quality_report.md`

## 10. Targeted visual review of the 15 worst parts
Representative images were inspected in `quality_contact_sheets/worst_parts_all.jpg`. The following diagnoses are evidence-based but limited to visible content plus LOO/duplicate results:

| Part | Categories | Factual evidence |
|---:|---|---|
| 6 | C different views of same part, D label close-up vs full-part mismatch | Contact sheet shows the same black Siemens module photographed from several sides plus a close label view. No cross-part exact duplicate was found for this part. |
| 11 | C different views of same part, D label close-up vs full-part mismatch | Contact sheet shows a black rectangular Siemens component with broad/full views and separate label/detail views; the views differ substantially in composition. |
| 50 | B visually similar parts, C different views of same part | The five photos show a small mechanical assembly from different angles. LOO chose PART_49 for 4/5 queries (mean similarity about 0.6901), indicating visual confusion with that assembly. |
| 71 | A duplicate/misassigned images | Two images are byte-identical to PART_66 images. All five LOO queries were predicted as PART_66; exact duplicate pairs have similarity 1.0. |
| 72 | C different views of same part, D label close-up vs full-part mismatch | Contact sheet shows a yellow module photographed front, rear, side, and label/detail orientations. The composition changes strongly across the five images. |
| 5 | B visually similar parts, C different views of same part, D label close-up vs full-part mismatch | Contact sheet shows a black Siemens device with several side/face views and a label/detail image. LOO confusion is distributed across similar black industrial components. |
| 7 | B visually similar parts, C different views of same part | Contact sheet shows a black rectangular device from multiple orientations. LOO most commonly confused it with PART_9 and also with PART_5. |
| 8 | B visually similar parts, C different views of same part | Contact sheet shows a black Siemens module photographed from multiple orientations. All four LOO queries were predicted as PART_9; cross-part perceptual pairs also link PART_8 with PART_9 and PART_70. |
| 9 | B visually similar parts, C different views of same part | Contact sheet shows a visually similar black module to PART_8/PART_70. LOO most commonly predicted PART_8; the confusion is consistent with similar shape and black housing. |
| 32 | C different views of same part, G poor image quality | Contact sheet shows a motor/industrial component with broad, label, and side/detail views. The visible scale and composition vary; no duplicate assignment was established. |
| 70 | B visually similar parts, C different views of same part, D label close-up vs full-part mismatch | Contact sheet shows a black Siemens unit with label close-ups and full/side views. Cross-part perceptual pairs link it to PART_8 and PART_63; LOO also confused it with PART_6. |
| 74 | C different views of same part, D label close-up vs full-part mismatch | Contact sheet shows yellow modules in front, rear, side, and connector/detail views. All four LOO queries were predicted as PART_63, indicating strong visual overlap in this dataset. |
| 27 | G poor image quality, H rotation/orientation, J insufficient number of images | Only three images exist and the contact sheet shows a very small metal cylinder photographed at different orientations/scales on a plain background. LOO accuracy is 0/3. |
| 29 | B visually similar parts, C different views of same part, J insufficient number of images | Only three images exist and show a ring-like mechanical part from different angles. LOO most commonly predicted PART_28; the contact sheet shows similar circular hardware across the confused samples. |
| 49 | B visually similar parts, C different views of same part, J insufficient number of images | Only three images exist and show a compact mechanical valve/assembly from different angles. All queries were predicted as PART_50, consistent with a visually similar assembly pair. |
