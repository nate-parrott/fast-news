import datetime
from google.appengine.ext import ndb
from google.appengine.api import taskqueue
from util import get_or_insert
from google.appengine.api import memcache
from model import Subscription, Source
import copy

UPDATE_INTERVAL = 5 * 60 # every 5 mins
FEED_ARTICLE_LIMIT = 4 # per source

class Feed(ndb.Model):
    uid = ndb.StringProperty()
    feed = ndb.JsonProperty(compressed=True)
    updated = ndb.DateTimeProperty()
    
    # TODO: make feed updates transactional
    
    def update_in_place(self, just_added_sources_json=[], just_removed_source_urls=[]):
        # just_added_articles and just_added_sources should be passed in such that the most recent are FIRST        
        content = self.feed or {'sources': []}
        sources = content['sources']
        remove_src_urls = set(just_removed_source_urls + [s.get('url') for s in just_added_sources_json])
        sources = [s for s in sources if s.get('url') not in remove_src_urls]
        
        just_added_sources_json = copy.deepcopy(just_added_sources_json)
        for source in just_added_sources_json:
            articles = source.get('articles', [])
            source['articles'] = articles[:min(len(articles), FEED_ARTICLE_LIMIT)]
        
        content['sources'] = just_added_sources_json + sources
        self.feed = content
        self.put()
    
    def update(self):
        self.feed = generate_feed(self.uid)
        self.updated = datetime.datetime.now()
        self.put()
    
    def ensure_feed_content(self, force=False):
        print ('has feed with {0} items; force={1}'.format(len(self.feed['sources']), force) if self.feed else 'no feed')
        if not self.feed or force: self.update()
        return self.feed
    
    def schedule_update(self):
        task = taskqueue.Task(url='/tasks/feeds/update', params={'uid': self.uid}, countdown=UPDATE_INTERVAL)
        taskqueue.Queue('feeds').add_async(task)
    
    @classmethod
    def get_for_user(cls, uid):
        item, inserted = get_or_insert(Feed, uid)
        if inserted:
            item.uid = uid
            item.put()
            item.schedule_update()
        return item

def generate_feed(uid):
    subscriptions = Subscription.query(Subscription.uid == uid).fetch(200)
    subscription_urls = [sub.url for sub in subscriptions if sub.url]
    if len(subscription_urls) > 0:
        sources = Source.query(Source.url.IN(subscription_urls)).order(-Source.most_recent_article_added_date).fetch(len(subscription_urls))
        
        source_jsons = {}
        for source_json in memcache.get_multi([source.feed_cache_key() for source in sources]).itervalues():
            source_jsons[source_json['id']] = source_json
        
        to_fetch = [source for source in sources if source.key.id() not in source_jsons]
        print 'HITS {0} TO_FETCH {1}'.format(len(source_jsons), len(to_fetch))
        if len(to_fetch):
            source_promises = [src.json(include_articles=True, article_limit=FEED_ARTICLE_LIMIT, return_promise=True) for src in to_fetch]
            for promise in source_promises:
                data = promise()
                source_jsons[data['id']] = data
        
        # put the cache keys:
        if len(to_fetch):
            memcache.set_multi({source.feed_cache_key(): source_jsons[source.key.id()] for source in to_fetch if (source.key.id() in source_jsons)})
        
        source_json = [source_jsons[source.key.id()] for source in sources if source.key.id() in source_jsons]
    else:
        source_json = []
    return {
        "sources": source_json
    }
