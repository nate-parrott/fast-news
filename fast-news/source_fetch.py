import urllib2
import bs4
from bs4 import BeautifulSoup
import datetime
from model import Article, Source
from google.appengine.ext import ndb
from model import Article
from util import get_or_insert
from canonical_url import canonical_url

def source_fetch(source):
    try:
        fetch_type = None
        if rss_fetch(source):
            fetch_type = 'rss'
        print "Fetched {0} as {1} source".format(source.url, fetch_type)
    except urllib2.URLError as e:
        print "URL error fetching {0}: {1}".format(source.url, e)
    source.last_fetched = datetime.datetime.now()
    source.put()

def rss_fetch(source):
    # assume `source` will be `put()` after call
    markup = urllib2.urlopen(source.url).read()
    parsed = BeautifulSoup(markup, 'lxml')
    latest_date = None
    if parsed.find('body'):
        body = parsed.find('body')
        children = list(body.children)
        if len(children) == 1 and children[0].name.lower() == 'rss':
            # this is rss
            source.title = parsed.find('title').text if parsed.find('title') else None
            now = datetime.datetime.now()
            for i, item in enumerate(parsed.find_all('item')):
                # print item.link, item.link.next_sibling, type(item.link.next_sibling)
                if item.link and item.link.next_sibling and type(item.link.next_sibling) == bs4.element.NavigableString:
                    url = unicode(item.link.next_sibling).strip()
                    id = Article.id_for_article(url, source.url)
                    title = item.find('title').text if item.find('title') else None
                    article, inserted = get_or_insert(Article, id)
                    if inserted:
                        article.added_date = datetime.datetime.now()
                        if latest_date == None or article.added_date > latest_date:
                            latest_date = article.added_date
                        article.added_order = i
                        article.source = source.key
                        article.url = canonical_url(url)
                    article.title = title
                    article.put()
                    if inserted:
                        article.enqueue_fetch()
            if latest_date:
                source.most_recent_article_added_date = latest_date
            return True
    return False
