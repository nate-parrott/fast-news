from google.appengine.api import search
import re
import webapp2
from template import template
import json
import model
from google.appengine.api import memcache

index = search.Index('Sources')
WORD_END_TOKEN = '_END'

def tokenize(text, remove_empty=True):
    if text:
        text = re.sub(r"[\.\,\'\"\:\!\?]", " ", text.lower())
        words = re.split(r"\s+", text)
        if remove_empty:
            return [w for w in words if len(w)]
        else:
            return words
    else:
        return []

def expand_tokens(tokens, max_tokens):
    """
    Expand tokens into all prefixes (e.g. "hey" becomes "hey", "he", "h"
    -- and also "hey" + WORD_END_TOKEN.
    """
    tokens = set(tokens)
    token_set = set([t + WORD_END_TOKEN for t in tokens] + list(tokens))
    if len(tokens) == 0: return token_set
    max_token_len = max(map(len, tokens))
    for cut in xrange(1, max_token_len):
        new_tokens = set()
        for token in tokens:
            if len(token) > cut:
                new_tokens.add(token[:-cut])
        if len(new_tokens) == 0:
            return tokens
        for t in new_tokens:
            if len(token_set) >= max_tokens:
                return tokens
            else:
                token_set.add(t)  
    return token_set

"""def tokenize_url(url):
    tokens = [url]
    for prefix in ['https://', 'http://', 'www.']:
        if url.index(prefix) == 0:
            url = url[len(prefix):]
            tokens.append(url)
    return tokens
"""

DEFAULT_RANK = 9999

def add_to_index(url, title, category=None, rank=None, keywords=""):
    print "ADDING {0} to source search index".format(url)
    if rank is None:
        existing = index.get(url)
        if existing and doc_to_dict(existing).get('doc_rank') is not None:
            rank = doc_to_dict(existing).get('doc_rank')
        else:
            rank = DEFAULT_RANK
    
    title_tokens = list(expand_tokens(tokenize(title), 600))
    url_tokens = list(expand_tokens(tokenize(url), 100))
    keyword_tokens = list(expand_tokens(tokenize(keywords), 100))
    index_text = u" ".join(url_tokens + title_tokens + keyword_tokens)
    doc = search.Document(doc_id=url, fields=[
        search.TextField(name='tokens', value=index_text),
        search.AtomField(name='title', value=title),
        search.AtomField(name='url', value=url),
        search.AtomField(name='category', value=category),
        search.NumberField(name='doc_rank', value=rank)
    ])
    index.put(doc)

def add_source_to_index(source):
    add_to_index(source.url, source.display_title() or source.url, rank=source.featured_priority, keywords=source.keywords)

def doc_to_json(doc):
    doc = doc_to_dict(doc)
    return {
        "title": doc.get('title'),
        "url": doc.get('url'),
        "category": doc.get('category'),
        "id": model.Source.id_for_source(doc.get('url'))
    }

def doc_to_dict(doc):
    return {field.name: field.value for field in doc.fields}

def _search_sources(query):
    words = tokenize(query, remove_empty=False)
    for i in xrange(len(words)-1): words[i] = words[i] + WORD_END_TOKEN
    query = u" ".join(words)
    sort_rank = search.SortExpression(expression='doc_rank', direction=search.SortExpression.ASCENDING, default_value=DEFAULT_RANK)
    options = search.QueryOptions(limit=10, sort_options=search.SortOptions(expressions=[sort_rank]))
    results = index.search(search.Query(query_string=query, options=options))
    return map(doc_to_json, results)

def search_sources(query):
    CACHE_SECONDS = 20 * 60
    key = 'source_search/' + query.encode('utf-8')
    res = memcache.get(key)
    if not res:
        res = _search_sources(query)
        memcache.set(key, res, CACHE_SECONDS)
    return res

def add_existing_sources(offset=0):
    i = 0
    for source in model.Source.query().iter(offset=offset, limit=100):
        add_source_to_index(source)
        i += 1
    return i

class SourceSearchAdmin(webapp2.RequestHandler):
    def get(self):
        self.response.write(template('source_search.html'))
    
    def post(self):
        if self.request.get('action') == 'add_existing_sources':
            count = add_existing_sources(offset=int(self.request.get('offset')))
            self.response.write("Added {0} entries".format(count))
        elif self.request.get('action') == 'upload_sites':
            sites = json.loads(self.request.get('json'))['sites']
            for site in sites:
                add_to_index(site['url'], site['title'], site.get('category'), site.get('rank', DEFAULT_RANK))
            self.response.write("Added {0} entries".format(len(sites)))

if __name__ == '__main__':
    print expand_tokens(tokens('im nate'), 500)
