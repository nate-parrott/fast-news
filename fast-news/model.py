from google.appengine.ext import ndb
from canonical_url import canonical_url
from google.appengine.api import taskqueue

class Subscription(ndb.Model):
    url = ndb.StringProperty()
    added = ndb.DateTimeProperty(auto_now_add=True)
    uid = ndb.StringProperty()
    
    @classmethod
    def id_for_subscription(cls, url, uid):
        return canonical_url(url) + u" " + uid

class Source(ndb.Model):
    url = ndb.StringProperty()
    last_fetched = ndb.DateTimeProperty()
    title = ndb.TextProperty()
    most_recent_article_added_date = ndb.DateTimeProperty()
    
    def fetch_now(self):
        source_fetch(self)
    
    def enqueue_fetch(self, delay=0):
        taskqueue.add(url='/tasks/sources/fetch', params={'id': self.key.id()}, countdown=delay)
    
    @classmethod
    def id_for_source(cls, url):
        return canonical_url(url)
        
    @classmethod
    def from_url(cls, url):
        return ndb.Key(cls.id_for_source(url)).get()
    
    def json(self, include_articles=False, article_limit=50, return_promise=False):
        articles_future = None
        if include_articles:
            # this returns an async wrapper:
            articles_future = Article.query(Article.source == self.key).order(-Article.added_date, Article.added_order).fetch_async(article_limit)
        def promise():
            d = {
                "url": self.url,
                "title": self.title
            }
            if include_articles:
                d['articles'] = [a.json() for a in articles_future.get_result()]
            return d
        return promise if return_promise else promise()

class Article(ndb.Model):
    source = ndb.KeyProperty(kind=Source)
    url = ndb.StringProperty()
    html = ndb.TextProperty()
    article_html = ndb.TextProperty()
    article_text = ndb.TextProperty()
    added_date = ndb.DateTimeProperty()
    added_order = ndb.IntegerProperty()
    data = ndb.JsonProperty()
    fetch_date = ndb.DateTimeProperty()
    title = ndb.TextProperty()
    thumbnail_url = ndb.StringProperty()
    fetch_failed = ndb.BooleanProperty()
        
    @classmethod
    def id_for_article(cls, url, source_url):
        return canonical_url(url) + u" " + canonical_url(source_url)
    
    def fetch_now(self):
        article_fetch(self)
    
    def enqueue_fetch(self):
        taskqueue.add(url='/tasks/articles/fetch', params={'id': self.key.id()})
    
    def json(self, include_content=False):
        d = {
            "id": self.key.id(),
            "url": self.url,
            "title": self.title,
            "thumbnail_url": self.thumbnail_url,
            "fetch_failed": self.fetch_failed
        }
        if include_content:
            d['data'] = self.data()
        return d
    
    def data(self):
        return {
            "article_html": self.article_html,
            "article_title": self.article_title,
            "top_image": self.top_image
        }

from source_fetch import source_fetch
from article_fetch import article_fetch
