#!/usr/bin/env python
# -*- coding: utf-8 -*-

from google.appengine.ext import ndb
import urllib2
from httplib import HTTPException
import calendar
from cookielib import CookieJar
import unicodedata

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

def first_present(items):
    for item in items:
        if item:
            return item

def url_fetch(url, timeout=10):
    cj = CookieJar()
    opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
    opener.addheaders = [("User-Agent", "fast-news-bot")]
    print "url_fetch('{0}')".format(url)
    try:
        return opener.open(url, timeout=timeout).read()
    except HTTPException as e:
        print "{0}: {1}".format(url, e)
    except urllib2.URLError as e:
        print "{0}: {1}".format(url, e)
    return None

def truncate(text, words=None):
    # ensure we're operating on unicode strings:
    if type(text) == str:
        return truncate(text.decode('utf-8'), words).encode('utf-8')
    
    split = text.split(' ')
    if words and len(split) > words:
        return u" ".join(split[:words]) + u"…"
    return text

def timestamp_from_datetime(adatetime):
    return calendar.timegm(adatetime.utctimetuple())

def normalized_compare(string1, string2):
    def normalize(string):
        if type(string) == str:
            return normalize(string.decode('utf-8'))
        return unicodedata.normalize('NFC', string.replace(u"\u00a0", " ").strip().lower())
    return normalize(string1) == normalize(string2)
