from google.appengine.ext import ndb
from canonical_url import canonical_url
from google.appengine.api import taskqueue
from util import truncate, timestamp_from_datetime

class Subscription(ndb.Model):
    url = ndb.StringProperty()
    added = ndb.DateTimeProperty(auto_now_add=True)
    uid = ndb.StringProperty()
    
    @classmethod
    def id_for_subscription(cls, url, uid):
        return canonical_url(url) + u" " + uid
    
    def json(self):
        source = Source.from_url(self.url)
        return {
            "id": self.key.id(),
            "source": source.json(),
            "url": source.url
        }

class Source(ndb.Model):
    url = ndb.StringProperty()
    last_fetched = ndb.DateTimeProperty()
    title = ndb.TextProperty()
    most_recent_article_added_date = ndb.DateTimeProperty()
    brand = ndb.JsonProperty()
    
    def fetch_now(self):
        source_fetch(self)
    
    def enqueue_fetch(self, delay=0):
        taskqueue.add(url='/tasks/sources/fetch', params={'id': self.key.id()}, countdown=delay)
    
    @classmethod
    def id_for_source(cls, url):
        return canonical_url(url)
        
    @classmethod
    def from_url(cls, url):
        return ndb.Key(Source, cls.id_for_source(url)).get()
    
    def json(self, include_articles=False, article_limit=50, return_promise=False):
        articles_future = None
        if include_articles:
            # this returns an async wrapper:
            articles_future = Article.query(Article.source == self.key).order(-Article.added_date, Article.added_order).fetch_async(article_limit)
        def promise():
            d = {
                "id": self.key.id(),
                "url": self.url,
                "title": self.title,
                "brand": self.brand
            }
            if include_articles:
                d['articles'] = [a.json() for a in articles_future.get_result()]
            return d
        return promise if return_promise else promise()

class Article(ndb.Model):
    source = ndb.KeyProperty(kind=Source)
    url = ndb.StringProperty()
    html = ndb.TextProperty()
    added_date = ndb.DateTimeProperty()
    added_order = ndb.IntegerProperty()
    fetch_date = ndb.DateTimeProperty()
    parsed = ndb.JsonProperty()
    title = ndb.TextProperty()
    fetch_failed = ndb.BooleanProperty()
    published = ndb.DateTimeProperty()
        
    @classmethod
    def id_for_article(cls, url, source_url):
        return canonical_url(url) + u" " + canonical_url(source_url)
    
    def fetch_now(self):
        article_fetch(self)
    
    def fetch_if_needed(self):
        if not self.parsed and not self.fetch_failed:
            self.fetch_now()
    
    def enqueue_fetch(self, delay=0):
        taskqueue.add(url='/tasks/articles/fetch', params={'id': self.key.id()}, countdown=delay)
    
    def json(self, include_content=False):
        d = {
            "id": self.key.id(),
            "url": self.url,
            "title": self.title,
            "fetch_failed": self.fetch_failed,
            "published": None
        }
        if self.published:
            d['published'] = timestamp_from_datetime(self.published)
        if self.parsed:
            d['description'] = self.short_description()
            d['top_image'] = self.parsed.get('top_image')
        if include_content:
            d['content'] = self.content()
        return d
    
    def short_description(self):
        if self.parsed:
            if self.parsed.get('description') and len(self.parsed.get('description')) > 0:
                return truncate(self.parsed.get('description'), words=60)
            elif self.parsed.get('article_text') and len(self.parsed.get('article_text')) > 0:
                return truncate(self.parsed.get('article_text'), words=40)
    
    def content(self):
        if self.parsed == None: return None
        return {
            "article_html": self.parsed['article_html'],
            "article_text": self.parsed['article_text'],
            "top_image": self.parsed['top_image']
        }

from source_fetch import source_fetch
from article_fetch import article_fetch
