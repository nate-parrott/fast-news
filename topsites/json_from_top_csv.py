import csv
import json

def int_from_str(s):
    try:
        return int(s)
    except Exception:
        return None

sites = []
for line in csv.reader(open('top.csv')):
    rank = int_from_str(line[0])
    if rank is not None:
        sites.append({"rank": rank, "url": "http://" + line[1], "category": line[3]})

open('top.json', 'w').write(json.dumps({"sites": sites}))


