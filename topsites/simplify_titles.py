import json

splits = ['-', '\u2013', ':']
def simplify_title(title):
    for s in splits:
        title = title.split(s)[0]
    return title.strip()

def process_site(item):
    if item['title']: item['title'] = simplify_title(item['title'])
    return item

sites = json.load(open('top-with-titles.json'))['sites']
sites = map(process_site, sites)
open('top-simplified.json', 'w').write(json.dumps({"sites": sites}))
