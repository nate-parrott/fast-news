from google.appengine.api import memcache
from model import Source, Article, Subscription, Bookmark

class SubscribedUrlsForUserCache(object):
    def __init__(self, uid):
        self.uid = uid
        self.key = 'subscribed_urls/{0}'.format(uid)
    
    def invalidate(self):
        memcache.delete(self.key)
    
    def update(self, just_inserted=[]):
        subs = Subscription.query(Subscription.uid == self.uid).fetch(limit=100)
        items = list(set([sub.url for sub in subs if sub.url] + just_inserted))
        memcache.set(self.key, items)
        return items
    
    def get(self):
        d = memcache.get(self.key)
        print "Subscriptions cache hit" if d else "Subscriptions cache miss"
        return d if d is not None else self.update()

class RecentArticlesCache(object):
    def __init__(self, count=10):
        self.count = count
    
    def key_for_url(self, url):
        return "sources/{0}/{1}".format(url, self.count)
    
    def invalidate(self, url):
        memcache.delete(self.key_for_url(url))
    
    def update(self, url, articles_just_added=[]):
        pass
    
    def get(self, urls):
        pass