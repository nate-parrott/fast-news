from model import Source, Article, Subscription
from util import get_or_insert
from canonical_url import canonical_url
from google.appengine.ext import ndb

def subscribe(uid, url):
    url = canonical_url(url)
    
    # create source if not yet created:
    source_id = Source.id_for_source(url)
    source, inserted = get_or_insert(Source, source_id)
    if inserted:
        source.url = url
        source.put()
        source.fetch_now()
        source.enqueue_fetch()
    
    id = Subscription.id_for_subscription(url, uid)
    sub, inserted = get_or_insert(Subscription, id)
    if inserted:
        sub.url = url
        sub.uid = uid
        sub.put()
    
    return source.json(include_articles=True)

def feed(uid):
    subscriptions = Source.query(Source.uid == uid).order(-Source.most_recent_article_added_date).fetch(100)
    
