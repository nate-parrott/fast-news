import urllib2
import bs4
from bs4 import BeautifulSoup
import datetime
from model import Article, Source
from google.appengine.ext import ndb
from model import Article
from util import get_or_insert, url_fetch, strip_url_prefix
from shared_suffix import shared_suffix
from canonical_url import canonical_url
import feedparser
from pprint import pprint
from urlparse import urljoin
import random
from brand import extract_brand
from time import mktime
import datetime
from google.appengine.api import taskqueue
import re
from logging import warning
from logging import info as debug

def source_fetch(source):
    debug("SF: Doing fetch for source: {0}".format(source.url))
    result = _source_fetch(source)
    debug("SF: Done with source fetch for {0}; result type: {1}".format(source.url, (result.method if result else None)))
    added_any = False
    now = datetime.datetime.now()
    to_put = []
    tasks_to_enqueue = []
    if result:
        if result.feed_title:
            source.title = result.feed_title
        if result.brand:
            source.brand = result.brand
        
        titles = [entry['title'] for entry in result.entries if entry['title']]
        source.shared_title_suffix = shared_suffix(titles)
        
        for i, entry in enumerate(result.entries[:min(25, len(result.entries))]):
            id = Article.id_for_article(entry['url'], source.url)
            article, inserted = get_or_insert(Article, id)
            if inserted:
                added_any = True
                article.added_date = now
                article.added_order = i
                article.source = source.key
                article.url = canonical_url(entry['url'])
                if entry['published']:
                    article.published = entry['published']
                else:
                    article.published = datetime.datetime()
                article.title = entry['title']
                to_put.append(article)
                delay = random.randint(0, 60)
                tasks_to_enqueue.append(article.create_fetch_task(delay=delay))
    debug("SF: About to put")
    if len(to_put):
        ndb.put_multi(to_put)
    debug("SF: About to enqueue")
    if len(tasks_to_enqueue):
        taskqueue.Queue().add_async(tasks_to_enqueue)
    debug("SF: done enqueuing")
    if added_any:
        source.most_recent_article_added_date = now
    source.last_fetched = now
    source.put()

class FetchResult(object):
    def __init__(self, method, feed_title, entries):
        self.method = method
        self.feed_title = feed_title
        self.entries = entries # {"url": url, "title": title, "published": datetime}
        self.brand = None
    
    def __repr__(self):
        return "FetchResult.{0}('{1}'): {2} ".format(self.method, self.feed_title, self.entries)

def _source_fetch(source):
    fetch_type = None
    markup = url_fetch(source.url)
    if markup:
        result = None
        for fn in [fetch_hardcoded_rss_url, rss_fetch, fetch_wordpress_default_rss, fetch_linked_rss]:
            debug('SF: starting fetch method {0}'.format(fn))
            result = fn(source, markup, source.url)
            debug('SF: finished this fetch method')
            if result: break
        if result:
            debug("SF: Fetched {0} as {1} source".format(source.url, result.method))
        else:
            warning("SF: Couldn't fetch {0} using any method".format(source.url))
        if result:
            debug("SF: starting brand fetch")
            result.brand = extract_brand(markup, source.url)
            debug("SF: done with brand fetch")
        return result
    else:
        print "URL error fetching {0}".format(source.url)
    return None

def rss_fetch(source, markup, url):    
    parsed = feedparser.parse(markup)
    # pprint(parsed)
    
    if len(parsed['entries']) == 0:
        return None
    
    feed_title = parsed['feed']['title']
    entries = []
    latest_date = None
    for entry in parsed['entries']:
        if 'link' in entry:
            link_url = urljoin(url, entry['link'].strip())
            title = entry['title']
            
            pub_time = entry.get('published_parsed')
            if pub_time:
                published = datetime.datetime.fromtimestamp(mktime(pub_time))
            else:
                published = None
            entries.append({"title": title, "url": link_url, "published": published})
    
    return FetchResult('rss', feed_title, entries)

def fetch_linked_rss(source, markup, url):
    soup = BeautifulSoup(markup, 'lxml')
    link = soup.find('link', attrs={'rel': 'alternate', 'type': ['application/rss+xml', 'application/atom+xml']})
    if link and type(link) == bs4.element.Tag and link['href']:
        feed_url = urljoin(url, link['href'])
        print 'Found rss URL: ', feed_url
        feed_markup = url_fetch(feed_url)
        if feed_markup:
            result = rss_fetch(source, feed_markup, feed_url)
            if result:
                result.method = 'linked_rss'
                return result
            else:
                print 'failed to parse markup'
        else:
            print "Error fetching linked rss {0}".format(feed_url) 
    return None

def fetch_wordpress_default_rss(source, markup, url):
    link = url + "/?feed=rss"
    # print "Trying", link
    feed_markup = url_fetch(link)
    # print "MARKUP:", feed_markup
    if feed_markup:
        res = rss_fetch(source, feed_markup, link)
        # print 'res', res
        if res:
            res.method = 'wordpress_default_rss'
            return res

def fetch_hardcoded_rss_url(source, markup, url):
    lookup = {
        'news.ycombinator.com': 'http://hnrss.org/newest?points=25',
        'newyorker.com': 'http://www.newyorker.com/feed/everything'
    }
    rss_url = lookup.get(strip_url_prefix(url))
    if rss_url:
        feed_markup = url_fetch(rss_url)
        res = rss_fetch(source, feed_markup, rss_url)
        if res:
            res.method = 'hardcoded_rss'
            return res
