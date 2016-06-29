from model import Source, Article, Subscription, Bookmark
from util import get_or_insert
from canonical_url import canonical_url
from google.appengine.ext import ndb
import datetime
import logging

def subscribe(uid, url):
    source = ensure_source(url)
    source_json = source.json(include_articles=True)
    if len(source_json['articles']) == 0:
        print "Refusing to subscribe to {0} because no articles were fetched".format(source.url)
        return {"success": False}
    
    url = source.url
    id = Subscription.id_for_subscription(url, uid)
    sub, inserted = get_or_insert(Subscription, id)
    if inserted:
        sub.url = url
        sub.uid = uid
        sub.put()
    
    return {"success": True, "source": source.json(include_articles=True), "subscription": sub.json()}

def ensure_article_at_url(url, force_fetch=False):
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

def feed(uid, article_limit=10, source_limit=100):
    subscriptions = Subscription.query(Subscription.uid == uid).fetch(source_limit)
    source_json = []
    if len(subscriptions) > 0:
        subscription_urls = set([s.url for s in subscriptions])
        sources = Source.query(Source.url.IN(list(subscription_urls))).order(-Source.most_recent_article_added_date).fetch(len(subscription_urls))
        source_promises = [src.json(include_articles=True, article_limit=article_limit, return_promise=True) for src in sources]
        source_json = [p() for p in source_promises]
    return {
        "sources": source_json
    }

def bookmarks(uid):
    bookmarks = Bookmark.query(Bookmark.uid == uid).order(-Bookmark.last_modified).fetch(100)
    articles = ndb.get_multi([b.article for b in bookmarks])
    def to_json(bookmark, article):
        j = bookmark.json()
        j['article'] = article.json() if article else None
        return j
    return {
        "bookmarks": [to_json(bookmark, article) for bookmark, article in zip(bookmarks, articles)]
    }

def add_or_update_bookmark(uid, reading_pos, article_id=None, article_url=None):
    # provide EITHER article_id or article_url
    if not (article_id or article_url):
        logging.error("Attempt to update bookmark without article_id or article_url")
        return None
    if not article_id and article_url:
        article = ensure_article_at_url(article_url)
        if article:
            article_id = article.key.id()
        else:
            logging.error("Tried to get article {0} for bookmarking, but failed".format(article_url))
            return None
    
    id = Bookmark.id_for_bookmark(uid, article_id)
    bookmark, inserted = get_or_insert(Bookmark, id)
    bookmark.article = ndb.Key(Article, article_id)
    if reading_pos:
        bookmark.reading_position = reading_pos
    bookmark.last_modified = datetime.datetime.now()
    bookmark.uid = uid
    bookmark.put()
    return bookmark

def delete_bookmark(uid, article_id):
    id = Bookmark.id_for_bookmark(uid, article_id)
    ndb.Key(Bookmark, id).delete()
