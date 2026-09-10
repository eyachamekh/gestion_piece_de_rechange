import json
from collections import defaultdict

ROOT = __import__('os').path.abspath(__import__('os').path.join(__import__('os').path.dirname(__file__), '..'))
LOO = __import__('os').path.join(ROOT, 'spare_parts_dataset', 'loo_results.json')
with open(LOO,'r',encoding='utf8') as f:
    data = json.load(f)
results = data['results']
N = len(results)

# prepare arrays
best_scores = [r['best_score'] for r in results]
margins = [r['margin'] for r in results]
corrects = [r['correct'] for r in results]

# grid search for thresholds
import math
best_choices = []
for t in [x/100.0 for x in range(45,96,1)]:
    for m in [x/1000.0 for x in range(0,201,5)]:
        accepted = 0
        accepted_correct = 0
        accepted_incorrect = 0
        for r in results:
            if r['best_score'] >= t and r['margin'] >= m:
                accepted += 1
                if r['correct']: accepted_correct += 1
                else: accepted_incorrect += 1
        # prefer conservative: low accepted_incorrect
        best_choices.append((accepted_incorrect, -accepted_correct, accepted, t, m))
# sort by fewest false positives, then most accepted_correct
best_choices.sort()
# take top few
top = best_choices[:10]
print('Top threshold candidates (false_positives, -true_positives, accepted, sim_threshold, margin):')
for item in top:
    print(item)

# pick the one with zero false positives and highest accepted_correct among those
candidates = [c for c in best_choices if c[0]==0]
if candidates:
    # pick min negative true positives => max true positives
    candidates.sort(key=lambda x: (x[0], x[1], -x[2]))
    chosen = candidates[0]
else:
    chosen = best_choices[0]

fp, neg_tp, accepted, t_choice, m_choice = chosen
print('\nChosen thresholds:')
print('SIM_THRESHOLD=', t_choice, 'MARGIN=', m_choice)
print('Accepted:', accepted, 'False positives:', fp, 'True positives:', -neg_tp)

# compute final stats with chosen thresholds
accepted = 0
accepted_correct = 0
accepted_incorrect = 0
no_confident = 0
for r in results:
    if r['best_score'] >= t_choice and r['margin'] >= m_choice:
        accepted += 1
        if r['correct']: accepted_correct += 1
        else: accepted_incorrect += 1
    else:
        no_confident += 1

print('\nFinal evaluation for chosen thresholds:')
print('accepted:', accepted)
print('accepted_correct:', accepted_correct)
print('accepted_incorrect:', accepted_incorrect)
print('no_confident:', no_confident)

# list worst false positives (accepted_incorrect cases) and low-margin ambiguous cases
false_positives = [r for r in results if (r['best_score'] >= t_choice and r['margin'] >= m_choice and not r['correct'])]
false_positives_sorted = sorted(false_positives, key=lambda x: x['best_score'], reverse=True)
ambiguous = sorted(results, key=lambda x: x['margin'])[:20]

with open(__import__('os').path.join(ROOT, 'spare_parts_dataset', 'threshold_analysis.json'),'w',encoding='utf8') as f:
    json.dump({'chosen': {'sim_threshold': t_choice, 'margin': m_choice, 'accepted': accepted, 'accepted_correct': accepted_correct, 'accepted_incorrect': accepted_incorrect, 'no_confident': no_confident}, 'false_positives_top': false_positives_sorted[:20], 'most_ambiguous': ambiguous[:50]}, f, indent=2)

print('Saved threshold_analysis.json')
