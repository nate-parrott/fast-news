from google.appengine.ext import ndb
from canonical_url import canonical_url
from google.appengine.api import taskqueue
from util import truncate, timestamp_from_datetime, first_present
import util
import sys, traceback, StringIO
import datetime
import random
from article_title_processor import article_title_processor
from google.appengine.api import memcache
from strip_twitter_handle import strip_twitter_handle_from_title

MINUTES = 60
HOURS = 60 * MINUTES
DAYS = 24 * HOURS

class Subscription(ndb.Model):
    url = ndb.StringProperty()
    added = ndb.DateTimeProperty(auto_now_add=True)
    uid = ndb.StringProperty()
    
    @classmethod
    def id_for_subscription(cls, url, uid):
        return canonical_url(url) + u" " + uid
    
    def json(self, return_promise=False):
        source_future = Source.from_url_async(self.url)
        def promise():
            source = source_future.get_result()
            return {
                "id": self.key.id(),
                "url": self.url,
                "source": source.json() if source else None
            }
        return promise if return_promise else promise()

class Source(ndb.Model):
    url = ndb.StringProperty()
    last_fetched = ndb.DateTimeProperty()
    title = ndb.TextProperty()
    short_title = ndb.TextProperty()
    most_recent_article_added_date = ndb.DateTimeProperty()
    brand = ndb.JsonProperty()
    
    shared_title_suffix = ndb.TextProperty()
    shared_hostname = ndb.StringProperty()
    
    fetch_url_override = ndb.StringProperty()
    direct_fetch_data = ndb.JsonProperty() # this is updated directly by source_fetch when fetching; it's okay to delete
    title_override = ndb.TextProperty()
    color = ndb.StringProperty()
    icon_url = ndb.StringProperty()
    featured_priority = ndb.FloatProperty()
    categories = ndb.StringProperty(repeated=True)
    keywords = ndb.TextProperty()
    
    last_fetch_failed = ndb.BooleanProperty(default=False)
    
    def display_title(self):
        if self.title_override:
            return self.title_override
        title = self.title
        if title:
            title = strip_twitter_handle_from_title(title)
        return title
    
    def fetch_now(self):
        source_fetch(self)
    
    def next_fetch_delay(self):
        if self.most_recent_article_added_date is None:
            return 20 * MINUTES
        time_since_last_new_article = (datetime.datetime.now() - self.most_recent_article_added_date).total_seconds()
        if time_since_last_new_article > 10 * DAYS:
            return 7 * HOURS
        if time_since_last_new_article > 3 * DAYS:
            return 3 * HOURS
        if time_since_last_new_article > 1 * DAYS:
            return 1.5 * HOURS
        if time_since_last_new_article > 3 * HOURS:
            return 1 * HOURS
        return 20 * MINUTES
    
    def create_fetch_task(self, delay):
        retry_options = taskqueue.TaskRetryOptions(task_retry_limit=2, min_backoff_seconds=20*MINUTES)
        return taskqueue.Task(url='/tasks/sources/fetch', params={'id': self.key.id()}, countdown=delay, retry_options=retry_options)
    
    def enqueue_fetch(self, delay=None, rand=True):
        if delay is None: delay = self.next_fetch_delay()
        if rand: delay = int(delay * random.random())
        taskqueue.Queue('sources').add_async(self.create_fetch_task(delay=delay))
    
    @classmethod
    def id_for_source(cls, url):
        return canonical_url(url)
        
    @classmethod
    def from_url(cls, url):
        return cls.from_url_async(url).get_result()
    
    @classmethod
    def from_url_async(cls, url):
        return ndb.Key(Source, cls.id_for_source(url)).get_async()
    
    def json(self, include_articles=False, article_limit=50, return_promise=False):
        articles_future = None
        if include_articles:
            # this returns an async wrapper:
            articles_future = Article.query(Article.source == self.key).order(-Article.added_date, Article.added_order).fetch_async(article_limit)
        def promise():
            d = {
                "id": self.key.id(),
                "url": self.url,
                "title": self.display_title(),
                "short_title": self.short_title,
                "brand": self.brand,
                "color": self.color,
                "icon_url": self.icon_url,
                "shared_hostname": self.shared_hostname
            }
            if include_articles:
                d['articles'] = [a.json() for a in articles_future.get_result()]
                d['articles'] = util.deduplicate_json(d['articles'], ['published', 'title'])
                d['articles'] = article_title_processor(d['articles'])
            return d
        return promise if return_promise else promise()
    
    def feed_cache_key(self):
        return "source/feed_cache/{0}".format(self.url)
    
    def invalidate_cache(self):
        memcache.delete(self.feed_cache_key())
    
    def _pre_put_hook(self):
        self.invalidate_cache()

class ArticleContent(ndb.Model):
    html = ndb.TextProperty()
    text = ndb.TextProperty()
    article_json = ndb.JsonProperty()
    is_low_quality_parse = ndb.BooleanProperty()

class Article(ndb.Model):
    source = ndb.KeyProperty(kind=Source)
    url = ndb.StringProperty()
    submission_url = ndb.StringProperty()
    added_date = ndb.DateTimeProperty()
    added_order = ndb.IntegerProperty()
    title = ndb.TextProperty()
    published = ndb.DateTimeProperty()
    top_image = ndb.TextProperty()
    top_image_tiny_json = ndb.JsonProperty()
    description = ndb.TextProperty()
    author = ndb.TextProperty()
    section = ndb.StringProperty()
    site_name = ndb.StringProperty()
    
    fetch_failed = ndb.BooleanProperty()
    fetch_date = ndb.DateTimeProperty()
    content = ndb.KeyProperty(kind=ArticleContent)
    
    """
    ml_service_time is None unless eligible for being sent to ML service; i.e. there is article content and ml service hasn't processed it before.
    the time is set to now when the item is dispensed to ml service, and
    it's set to None when ml-service calls back.
    """
    ml_service_time = ndb.DateTimeProperty()
    processed_by_ml_service = ndb.BooleanProperty(default=False)
    ml_topics = ndb.StringProperty(repeated=True)
    
    @classmethod
    def id_for_article(cls, url, source_url):
        source_string = canonical_url(source_url) if source_url else u"standalone"
        return canonical_url(url) + u" " + source_string
    
    def fetch_now(self):
        article_fetch(self)
    
    def fetch_if_needed(self, ignore_previous_failure=False):
        if not self.content and (ignore_previous_failure or not self.fetch_failed):
            self.fetch_now()
    
    def create_fetch_task(self, delay=0):
        retry_options = taskqueue.TaskRetryOptions(task_retry_limit=2, min_backoff_seconds=10*60)
        return taskqueue.Task(url='/tasks/articles/fetch', params={'id': self.key.id()}, countdown=delay, retry_options=retry_options)
    
    def enqueue_fetch(self, **kwargs):
        taskqueue.Queue('articles').add_async(self.create_fetch_task(**kwargs))
    
    def json(self, include_article_json=False):
        d = {
            "id": self.key.id(),
            "url": self.url,
            "submission_url": self.submission_url,
            "title": self.title.strip() if self.title else "",
            "fetch_failed": self.fetch_failed,
            "top_image": self.top_image,
            "top_image_tiny_json": self.top_image_tiny_json,
            "author": self.author,
            "site_name": self.site_name,
            "published": timestamp_from_datetime(self.published) if self.published else None,
            "description": self.description
        }
        if include_article_json:
            # print 'getting json; j: ', (not not self.content)
            d['article_json'] = self.content.get().article_json if self.content else None
        return d

from source_fetch import source_fetch
from article_fetch import article_fetch

class Bookmark(ndb.Model):
    article = ndb.KeyProperty(kind=Article)
    added = ndb.DateTimeProperty(auto_now_add=True)
    last_modified = ndb.DateTimeProperty(auto_now_add=True)
    reading_position = ndb.JsonProperty()
    uid = ndb.StringProperty()
    deleted = ndb.BooleanProperty(default=False)
    
    @classmethod
    def id_for_bookmark(cls, uid, article_id):
        return '{0} {1}'.format(uid, article_id)
    
    def json(self):
        return {
            "id": self.key.id(),
            "deleted": self.deleted,
            "article_id": self.article.id(),
            "added": timestamp_from_datetime(self.added),
            "last_modified": timestamp_from_datetime(self.last_modified),
            "reading_position": self.reading_position
        }

class ErrorReport(ndb.Model):
    @classmethod
    def with_current_exception(cls, cur_action):
        exc_type, exc_value, tb = sys.exc_info()
        f = StringIO.StringIO()
        traceback.print_tb(tb, file=f)
        trace = f.getvalue()
        payload = {
            "exc_type": str(exc_type),
            "exc_value": str(exc_value),
            "trace": trace
        }
        error_report = ErrorReport(action=cur_action, payload=payload)
        error_report.put()
        print "CREATING {0} ERROR REPORT FOR ERROR {1}: {2} (saved as {3})".format(cur_action, exc_type, exc_value, error_report)
        return error_report
    
    action = ndb.StringProperty()
    payload = ndb.JsonProperty()
    added = ndb.DateTimeProperty(auto_now_add=True)        
