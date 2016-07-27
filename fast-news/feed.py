from google.appengine.ext import ndb

UPDATE_INTERVAL = 10 * 60 # every 10 mins

class Feed(ndb.Model):
    @classmethod
    def key_for_uid(cls, uid):
        return ndb.Key(Feed, name=uid)
    
    @classmethod
    def update(cls, just_added_sources=[], just_added_articles={}, just_removed_sources=[]):
        pass
    
    def schedule_update(self):
        pass
    
    @classmethod
    def get_for_user(cls, uid):
        pass


def generate_feed(uid):
    pass

