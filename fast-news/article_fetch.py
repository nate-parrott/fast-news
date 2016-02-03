import urllib2, urllib
import datetime
import json

def article_fetch(article):
    content = ""
    title = ""
    try:
        print 'URL:', 'https://fast-news-parser.herokuapp.com/parse?' + urllib.urlencode({"url": article.url})
        data = json.load(urllib2.urlopen('https://fast-news-parser.herokuapp.com/parse?' + urllib.urlencode({"url": article.url})))
        if data['title']: article.title = data['title']
        article.parsed = data
    except ValueError as e:
        print "JSON parse error fetching {0}: {1}".format(article.url, e)
        article.fetch_failed = True
    except urllib2.URLError as e:
        print "URL error fetching {0}: {1}".format(article.url, e)
        article.fetch_failed = True
    article.fetch_date = datetime.datetime.now()
    article.put()
