from google.appengine.ext import ndb
import urllib2
from httplib import HTTPException

@ndb.transactional
def get_or_insert(cls, id, **kwds):
  key = ndb.Key(cls, id)
  ent = key.get()
  if ent is not None:
    return (ent, False)  # False meaning "not created"
  ent = cls(**kwds)
  ent.key = key
  ent.put()
  return (ent, True)  # True meaning "created"

def url_fetch(url):
    headers = {"User-Agent": "fast-news-bot"}
    req = urllib2.Request(url, None, headers)
    try:
        return urllib2.urlopen(req).read()
    except HTTPException as e:
        print "{0}: {1}".format(url, e)
    except urllib2.URLError as e:
        print "{0}: {1}".format(url, e)
    return None
