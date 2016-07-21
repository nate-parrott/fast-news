from google.appengine.ext import ndb
import util
import json

class KeyValue(ndb.Model):
    @classmethod
    def get(cls, key, default=None):
        pair = ndb.Key(KeyValue, key).get()
        return pair.value if pair and pair.value is not None else default
    
    @classmethod
    def set(cls, key, val):
        pair = util.get_or_insert(KeyValue, key, value=val)
        pair.value = val
        pair.put()
    
    value = ndb.TextProperty()
    
    @classmethod
    def categories(cls):
        return KeyValue.get('categories', json.dumps(["Newspapers", "Magazines", "Longform", "Tech", "Arts + Music", "Sports", "Humor"]))
    
    @classmethod
    def set_categories(cls, categories):
        KeyValue.set('categories', json.dumps(categories))
