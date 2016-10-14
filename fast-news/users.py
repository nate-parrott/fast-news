from google.appengine.ext import ndb
from google.appengine.api import memcache
from feed import Feed
from api import _subscribe_multi

default_urls = [
    "http://nytimes.com",
    "http://techcrunch.com",
    "http://longform.org"
]

class User(ndb.Model):
    created = ndb.DateTimeProperty(auto_now_add=True)
    setup_yet = ndb.BooleanProperty(default=False)
    
    @classmethod
    def from_id(cls, uid):
        return cls.get_or_insert_async(uid).get_result()
    
    def do_initial_setup(self):
        _subscribe_multi(self.key.id(), default_urls)
        setup_yet = True
        self.put()

def ensure_user_exists(uid):
    print 'Checking if user exists:', uid
    key = 'user/{0}/exists'.format(uid)
    if not memcache.get(key):
        user_record = User.from_id(uid)
        if not user_record.setup_yet:
            print 'user needs initial setup:', uid
            user_record.do_initial_setup()
        memcache.set(key, True)
