import json
from collections import defaultdict
ROOT = __import__('os').path.abspath(__import__('os').path.join(__import__('os').path.dirname(__file__),'..'))
LOO = __import__('os').path.join(ROOT,'spare_parts_dataset','loo_results.json')
with open(LOO,'r',encoding='utf8') as f:
    data = json.load(f)
parts = defaultdict(lambda: {'total':0,'correct':0,'queries':[]})
for r in data['results']:
    pid = r['actual_part']
    parts[pid]['total'] += 1
    parts[pid]['correct'] += 1 if r['correct'] else 0
    parts[pid]['queries'].append(r)

lst = []
for pid, v in parts.items():
    acc = v['correct']/v['total'] if v['total']>0 else None
    lst.append((pid, v['total'], v['correct'], acc))
lst.sort(key=lambda x: (x[3] if x[3] is not None else -1))
# write report
out = {'per_part': [{'part_id':p,'total':t,'correct':c,'accuracy':acc} for p,t,c,acc in lst], 'worst_10': []}
for p,t,c,acc in lst[:20]:
    out['worst_10'].append({'part_id': p, 'total': t, 'correct': c, 'accuracy': acc, 'examples': parts[p]['queries'][:3]})
with open(__import__('os').path.join(ROOT,'spare_parts_dataset','per_part_report.json'),'w',encoding='utf8') as f:
    json.dump(out, f, indent=2)
print('Wrote per_part_report.json')
