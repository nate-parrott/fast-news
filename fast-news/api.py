from model import Source, Article, Subscription
from util import get_or_insert
from canonical_url import canonical_url
from google.appengine.ext import ndb
import datetime

def subscribe(uid, url):
    source = ensure_source(url)
    url = source.url
    
    id = Subscription.id_for_subscription(url, uid)
    sub, inserted = get_or_insert(Subscription, id)
    if inserted:
        sub.url = url
        sub.uid = uid
        sub.put()
    
    return {"source": source.json(include_articles=True), "subscription": sub.json()}

def ensure_article_at_url(url, force_fetch=True):
    id = Article.id_for_article(url, None)
    article, inserted = get_or_insert(Article, id)
    if inserted:
        article.added_date = datetime.datetime.now()
        article.added_order = 0
    article.url = canonical_url(url)
    # article.published = datetime.datetime.now()
    # article.title = "A test"
    # article.title = None
    article.put()
    if not article.content or force_fetch:
        article.fetch_now()
    return article

def unsubscribe(uid, url):
    ndb.Key(Subscription, Subscription.id_for_subscription(url, uid)).delete()
    return True

def subscriptions(uid):
    subs = Subscription.query(Subscription.uid == uid).fetch()
    return {"subscriptions": [sub.json() for sub in subs]}

def ensure_source(url, suppress_immediate_fetch=False):
    url = canonical_url(url)
    source_id = Source.id_for_source(url)
    source, inserted = get_or_insert(Source, source_id)
    if inserted:
        source.url = url
        source.put()
        source.enqueue_fetch()
    if inserted and not suppress_immediate_fetch:
        source.fetch_now()
    return source

def feed(uid):
    subscriptions = Subscription.query(Subscription.uid == uid).fetch(100)
    source_json = []
    if len(subscriptions) > 0:
        
        subscription_urls = set([s.url for s in subscriptions])
        sources = Source.query(Source.url.IN(list(subscription_urls))).order(-Source.most_recent_article_added_date).fetch(len(subscription_urls))
        source_promises = [src.json(include_articles=True, article_limit=10, return_promise=True) for src in sources]
        source_json = [p() for p in source_promises]
    return {
        "sources": source_json
    }
