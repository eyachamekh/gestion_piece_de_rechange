import os
import json
import math
import numpy as np
from PIL import Image, ImageOps
import tensorflow as tf

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
MODEL_DIR = os.path.join(ROOT, 'tools', 'models')
os.makedirs(MODEL_DIR, exist_ok=True)
TFLITE_PATH = os.path.join(MODEL_DIR, 'mobilenet_v2_feature_vector.tflite')
DATASET_DIR = os.path.join(ROOT, 'spare_parts_dataset')
IMAGES_DIR = os.path.join(DATASET_DIR, 'images')
EMBED_DIR = os.path.join(DATASET_DIR, 'embeddings')
os.makedirs(EMBED_DIR, exist_ok=True)
METADATA_PATH = os.path.join(DATASET_DIR, 'embeddings_metadata.json')

INPUT_SIZE = 224

# Step A: Build and convert MobileNetV2 feature extractor if TFLite not present
if not os.path.exists(TFLITE_PATH):
    print('Building MobileNetV2 feature extractor (Keras) and converting to TFLite...')
    base = tf.keras.applications.MobileNetV2(weights='imagenet', include_top=False, pooling='avg', input_shape=(INPUT_SIZE, INPUT_SIZE, 3))
    # base.summary()
    # Create a model that outputs the pooled features
    model = tf.keras.Model(inputs=base.input, outputs=base.output)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # Use default float conversion
    tflite_model = converter.convert()
    with open(TFLITE_PATH, 'wb') as f:
        f.write(tflite_model)
    print('Saved TFLite model to', TFLITE_PATH)
else:
    print('TFLite model already exists at', TFLITE_PATH)

# Step B: Inspect TFLite model with Interpreter
interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print('MODEL INSPECT:')
print(' Input tensors:')
for d in input_details:
    print('  index', d['index'], 'shape', d['shape'], 'dtype', d['dtype'])
print(' Output tensors:')
for d in output_details:
    print('  index', d['index'], 'shape', d['shape'], 'dtype', d['dtype'])

# Expect single input [1,224,224,3] and output [1,1280]
out_shape = output_details[0]['shape']
out_dtype = output_details[0]['dtype']
print('Detected output shape', out_shape, 'dtype', out_dtype)
embedding_dim = int(out_shape[-1])

# Preprocessing function: EXIF transpose, resize preserving aspect ratio, center crop to 224, convert RGB, normalize to [-1,1]
def preprocess_image(path):
    img = Image.open(path)
    img = ImageOps.exif_transpose(img)
    img = img.convert('RGB')
    # resize preserving aspect ratio then center crop
    w, h = img.size
    scale = max(INPUT_SIZE / w, INPUT_SIZE / h)
    nw = int(math.ceil(w * scale))
    nh = int(math.ceil(h * scale))
    img = img.resize((nw, nh), Image.BILINEAR)
    # center crop
    left = (nw - INPUT_SIZE) // 2
    top = (nh - INPUT_SIZE) // 2
    img = img.crop((left, top, left + INPUT_SIZE, top + INPUT_SIZE))
    arr = np.array(img).astype(np.float32)
    # MobileNetV2 preprocessing: (x / 127.5) - 1.0
    arr = (arr / 127.5) - 1.0
    arr = np.expand_dims(arr, axis=0)
    return arr

# Step C: Walk exported dataset and build list of images
images = []  # tuples: (part_id, reference, filename, fullpath)
for split in ['train', 'val', 'test']:
    split_dir = os.path.join(IMAGES_DIR, split)
    if not os.path.exists(split_dir):
        continue
    for part_name in os.listdir(split_dir):
        if not part_name.startswith('PART_'):
            continue
        pid = int(part_name.split('_')[1])
        part_dir = os.path.join(split_dir, part_name)
        for fname in os.listdir(part_dir):
            if fname.lower().endswith(('.jpg', '.jpeg', '.png')):
                images.append((pid, split, fname, os.path.join(part_dir, fname)))

print('Found', len(images), 'exported images')

# Step D: Generate embeddings
metadata = {}
failures = []
interpreter.allocate_tensors()
input_index = input_details[0]['index']
output_index = output_details[0]['index']

for pid, split, fname, fullpath in images:
    out_dir = os.path.join(EMBED_DIR, f'PART_{pid}')
    os.makedirs(out_dir, exist_ok=True)
    try:
        arr = preprocess_image(fullpath)
    except Exception as e:
        failures.append({'file': fullpath, 'error': str(e)})
        continue
    # set input
    try:
        interpreter.set_tensor(input_index, arr.astype(input_details[0]['dtype']))
        interpreter.invoke()
        emb = interpreter.get_tensor(output_index)[0]
    except Exception as e:
        failures.append({'file': fullpath, 'error': 'inference:' + str(e)})
        continue
    # convert to float32 numpy
    emb = emb.astype(np.float32)
    # check finite
    if not np.isfinite(emb).all():
        failures.append({'file': fullpath, 'error': 'non-finite output'})
        continue
    # L2-normalize
    norm = np.linalg.norm(emb)
    if norm == 0 or not np.isfinite(norm):
        failures.append({'file': fullpath, 'error': 'zero or invalid norm'})
        continue
    emb = emb / norm
    # save as .npy and .bin
    base_name = os.path.splitext(fname)[0]
    npy_path = os.path.join(out_dir, base_name + '.npy')
    bin_path = os.path.join(out_dir, base_name + '.bin')
    np.save(npy_path, emb)
    emb.tobytes()
    with open(bin_path, 'wb') as f:
        f.write(emb.tobytes())
    # add metadata entry
    rel_bin = os.path.relpath(bin_path, ROOT)
    metadata_key = os.path.join(f'PART_{pid}', fname)
    metadata[metadata_key] = {'part_id': pid, 'split': split, 'filename': fname, 'embedding_file': rel_bin}

# write metadata and failures
with open(METADATA_PATH, 'w', encoding='utf8') as f:
    json.dump({'embedding_dim': embedding_dim, 'model': os.path.basename(TFLITE_PATH), 'metadata': metadata, 'failures': failures}, f, indent=2)

print('Embeddings generated:', len(metadata), 'failures:', len(failures))

# Step E: Load embeddings into arrays for evaluation
keys = list(metadata.keys())
embs = []
parts = []
filenames = []
references = {}
# need to read part reference info from dataset_report.json
report_path = os.path.join(DATASET_DIR, 'dataset_report.json')
part_refs = {}
if os.path.exists(report_path):
    with open(report_path, 'r', encoding='utf8') as f:
        rpt = json.load(f)
    for p in rpt.get('parts', []):
        part_refs[int(p['id'])] = p.get('reference')

for key in keys:
    info = metadata[key]
    pid = info['part_id']
    binfile = os.path.join(ROOT, info['embedding_file'])
    arr = np.frombuffer(open(binfile, 'rb').read(), dtype=np.float32)
    embs.append(arr)
    parts.append(pid)
    filenames.append(key)
    references[pid] = part_refs.get(pid, '')
embs = np.vstack(embs)
print('Loaded', embs.shape[0], 'embeddings of dim', embs.shape[1])

# Step F: LOO evaluation
from collections import defaultdict

def cosine(a, b):
    return float(np.dot(a, b))

N = embs.shape[0]
correct = 0
correct_at5 = 0
results = []
per_part_stats = defaultdict(lambda: {'total':0, 'correct':0})

for i in range(N):
    q_emb = embs[i]
    q_pid = parts[i]
    q_fname = filenames[i]
    # build gallery excluding i (exclude same image)
    gallery_embs = np.delete(embs, i, axis=0)
    gallery_parts = [parts[j] for j in range(N) if j != i]
    # compute similarities to all gallery embeddings
    sims = gallery_embs.dot(q_emb)
    # group by part: max similarity per part
    part_best = {}
    for s, p in zip(sims, gallery_parts):
        if p not in part_best or s > part_best[p]:
            part_best[p] = float(s)
    # sort parts by best score
    sorted_parts = sorted(part_best.items(), key=lambda x: x[1], reverse=True)
    best_pid, best_score = sorted_parts[0]
    second_score = sorted_parts[1][1] if len(sorted_parts) > 1 else -1.0
    # check recall@1
    is_correct = (best_pid == q_pid)
    if is_correct:
        correct += 1
        per_part_stats[q_pid]['correct'] += 1
    # recall@5: check if q_pid in top 5
    top5 = [p for p, s in sorted_parts[:5]]
    if q_pid in top5:
        correct_at5 += 1
    per_part_stats[q_pid]['total'] += 1
    results.append({'query': q_fname, 'actual_part': q_pid, 'predicted_part': best_pid, 'best_score': best_score, 'second_score': second_score, 'margin': best_score - second_score, 'correct': is_correct})

recall1 = correct / N
recall5 = correct_at5 / N
print('LOO results: N=', N, 'Recall@1=', recall1, 'Recall@5=', recall5)

# gather distributions
correct_sims = [r['best_score'] for r in results if r['correct']]
incorrect_sims = [r['best_score'] for r in results if not r['correct']]
correct_margins = [r['margin'] for r in results if r['correct']]
incorrect_margins = [r['margin'] for r in results if not r['correct']]

summary = {
    'N': N,
    'recall1': recall1,
    'recall5': recall5,
    'correct_best_sim_mean': float(np.mean(correct_sims)) if correct_sims else None,
    'incorrect_best_sim_mean': float(np.mean(incorrect_sims)) if incorrect_sims else None,
    'correct_margin_mean': float(np.mean(correct_margins)) if correct_margins else None,
    'incorrect_margin_mean': float(np.mean(incorrect_margins)) if incorrect_margins else None,
    'min_correct_similarity': float(np.min(correct_sims)) if correct_sims else None,
    'max_incorrect_similarity': float(np.max(incorrect_sims)) if incorrect_sims else None
}

with open(os.path.join(DATASET_DIR, 'loo_results.json'), 'w', encoding='utf8') as f:
    json.dump({'summary': summary, 'results': results}, f, indent=2)

print('Saved LOO results to spare_parts_dataset/loo_results.json')

# Step G: 1-shot and 2-shot experiments (random repeats)
import random
random.seed(1234)

def run_k_shot(k, repeats=20):
    recalls1 = []
    recalls5 = []
    for _ in range(repeats):
        # build gallery: sample k images per class (if class has <k images, skip class)
        gallery_idx = set()
        valid = True
        class_to_idxs = defaultdict(list)
        for idx, pid in enumerate(parts):
            class_to_idxs[pid].append(idx)
        for pid, idxs in class_to_idxs.items():
            if len(idxs) <= k:
                valid = False
                break
            chosen = random.sample(idxs, k)
            gallery_idx.update(chosen)
        if not valid:
            continue
        # queries are all images not in gallery
        gallery_idx = sorted(list(gallery_idx))
        gallery_embs = embs[gallery_idx]
        gallery_parts = [parts[i] for i in gallery_idx]
        query_idx = [i for i in range(N) if i not in gallery_idx]
        correct = 0
        correct5 = 0
        for qi in query_idx:
            q_emb = embs[qi]
            sims = gallery_embs.dot(q_emb)
            # best per part
            part_best = {}
            for s, p in zip(sims, gallery_parts):
                if p not in part_best or s > part_best[p]:
                    part_best[p] = float(s)
            sorted_parts = sorted(part_best.items(), key=lambda x: x[1], reverse=True)
            best_pid = sorted_parts[0][0]
            if best_pid == parts[qi]:
                correct += 1
            top5 = [p for p, s in sorted_parts[:5]]
            if parts[qi] in top5:
                correct5 += 1
        recalls1.append(correct / len(query_idx))
        recalls5.append(correct5 / len(query_idx))
    return {'k': k, 'repeats': repeats, 'mean_recall1': float(np.mean(recalls1)) if recalls1 else None, 'mean_recall5': float(np.mean(recalls5)) if recalls5 else None}

one_shot = run_k_shot(1, repeats=50)
two_shot = run_k_shot(2, repeats=50)
with open(os.path.join(DATASET_DIR, 'shot_results.json'), 'w', encoding='utf8') as f:
    json.dump({'1-shot': one_shot, '2-shot': two_shot}, f, indent=2)
print('1-shot/2-shot results saved to spare_parts_dataset/shot_results.json')

# Finish
print('Pipeline complete.')
