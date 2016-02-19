#!/usr/bin/env python
# -*- coding: utf-8 -*-

from google.appengine.ext import ndb
import urllib2
from httplib import HTTPException
import calendar
from cookielib import CookieJar

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
    cj = CookieJar()
    opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
    opener.addheaders.append(("User-Agent", "fast-news-bot"))
    print "url_fetch('{0}')".format(url)
    try:
        return opener.open(url).read()
    except HTTPException as e:
        print "{0}: {1}".format(url, e)
    except urllib2.URLError as e:
        print "{0}: {1}".format(url, e)
    return None

def truncate(text, words=None):
    # ensure we're operating on unicode strings:
    if type(text) == str:
        return truncate(text.decode('utf-8'), words, chars).encode('utf-8')
    
    split = text.split(' ')
    if words and len(split) > words:
        return u" ".join(split[:words]) + u"…"
    return text

def timestamp_from_datetime(adatetime):
    return calendar.timegm(adatetime.utctimetuple())
