from google.appengine.ext import ndb
from canonical_url import canonical_url
from google.appengine.api import taskqueue
from util import truncate, timestamp_from_datetime
from article_json import article_json

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
    
    shared_title_suffix = ndb.TextProperty()
    
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

class ArticleContent(ndb.Model):
    html = ndb.TextProperty()
    text = ndb.TextProperty()
    article_json = ndb.JsonProperty()

class Article(ndb.Model):
    source = ndb.KeyProperty(kind=Source)
    url = ndb.StringProperty()
    added_date = ndb.DateTimeProperty()
    added_order = ndb.IntegerProperty()
    title = ndb.TextProperty()
    published = ndb.DateTimeProperty()
    top_image = ndb.TextProperty()
    description = ndb.TextProperty()
        
    fetch_failed = ndb.BooleanProperty()
    fetch_date = ndb.DateTimeProperty()
    content = ndb.KeyProperty(kind=ArticleContent)
        
    @classmethod
    def id_for_article(cls, url, source_url):
        return canonical_url(url) + u" " + canonical_url(source_url)
    
    def fetch_now(self):
        article_fetch(self)
    
    def fetch_if_needed(self, ignore_previous_failure=False):
        if not self.content and (ignore_previous_failure or not self.fetch_failed):
            self.fetch_now()
    
    def create_fetch_task(self, delay=0):
        return taskqueue.Task(url='/tasks/articles/fetch', params={'id': self.key.id()}, countdown=delay)
    
    def enqueue_fetch(self, **kwargs):
        taskqueue.Queue().add_async(self.create_fetch_task(**kwargs))
    
    def json(self, include_article_json=False):
        d = {
            "id": self.key.id(),
            "url": self.url,
            "title": self.title,
            "fetch_failed": self.fetch_failed,
            "top_image": self.top_image,
            "published": timestamp_from_datetime(self.published) if self.published else None,
            "description": self.description
        }
        if include_article_json:
            print 'getting json; j: ', (not not self.content)
            d['article_json'] = self.content.get().article_json if self.content else None
        return d

from source_fetch import source_fetch
from article_fetch import article_fetch
