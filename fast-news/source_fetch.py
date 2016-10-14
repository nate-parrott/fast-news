from logging import info as debug
import datetime
import util
from shared_suffix import shared_suffix, shared_hostname
from model import Article, Source
from canonical_url import canonical_url
import twitter_source_fetch
from source_entry_processor import create_source_entry_processor
import rss_tools
from rss_tools import parse_as_feed
import bs4
from fetch_result import FetchResult
from urlparse import urljoin
from time import mktime
import source_search
from google.appengine.ext import ndb
from google.appengine.api import taskqueue
import amp

def source_fetch(source):
    debug("SF: Doing fetch for source: {0}".format(source.url))
    result = _source_fetch(source)
    debug("SF: Done with source fetch for {0}; result type: {1}".format(source.url, (result.method if result else None)))
    added_any = False
    now = datetime.datetime.now()
    new_articles = []
    tasks_to_enqueue = []
    if result:
        if result.feed_title:
            source.title = result.feed_title
        if result.brand:
            source.brand = result.brand
        
        # too many entries? limit max:
        # result.entries = result.entries[:min(len(result.entries), 15)]
        
        # titles = [entry['title'] for entry in result.entries if entry['title']]
        urls = [entry['url'] for entry in result.entries]
        if len(urls) >= 3:
            print 'SHARED:', shared_hostname(urls)
            source.shared_hostname = shared_hostname(urls)
            print 'gOT', source.shared_hostname
        else:
            print 'NAHHH'
            source.shared_hostname = None
        
        entries = result.entries[:min(25, len(result.entries))]
        entry_ids = [Article.id_for_article(entry['url'], source.url) for entry in entries]
        print "ENTRY IDs:", entry_ids
        print "ENtry id lens: ", str(map(len, entry_ids))
        article_futures = [Article.get_or_insert_async(id) for id in entry_ids]
        articles = [future.get_result() for future in article_futures]
        print "ARTICLE_OBJECTS:", articles
        
        for i, (entry, article) in enumerate(zip(entries, articles)):
            if not article.url:
                added_any = True
                article.added_date = now
                article.added_order = i
                article.source = source.key
                article.url = canonical_url(entry.get('url'))
                article.submission_url = canonical_url(entry.get('submission_url'))
                if entry['published']:
                    article.published = entry['published']
                else:
                    article.published = datetime.datetime.now()
                if not article.title:
                    article.title = entry['title']
                new_articles.append(article)
                delay = (i+1) * 4 # wait 5 seconds between each
                tasks_to_enqueue.append(article.create_fetch_task(delay=delay))
    debug("SF: About to put {0} items".format(len(new_articles)))
    if len(new_articles):
        amp.fetch_amp_urls_for_articles(new_articles)
        ndb.put_multi(new_articles)
    debug("SF: About to enqueue")
    if len(tasks_to_enqueue):
        taskqueue.Queue('articles').add_async(tasks_to_enqueue)
    debug("SF: done enqueuing")
    if added_any:
        source.most_recent_article_added_date = now
    elif source.most_recent_article_added_date is None:
        source.most_recent_article_added_date = now
    source_search.add_source_to_index(source)
    source.last_fetched = now
    source.last_fetch_failed = False
    source.put()

def _source_fetch(source):
    fetch_functions = {
        "twitter": twitter_fetch,
        "rss": rss_fetch
    }
    feed_content = None
    print "FETCH DATA ALREADY EXISTS" if source.direct_fetch_data else "FETCH DATA NEEDS TO BE CREATED"
    if not source.direct_fetch_data:
        data, feed_content = detect_fetch_data(source)
        source.direct_fetch_data = data
        # source.put()

    print "FETCH DATA:", source.direct_fetch_data    
    
    if source.direct_fetch_data:    
        fn = fetch_functions[source.direct_fetch_data['type']]
        return fn(source.direct_fetch_data, feed_content)

def detect_fetch_data(source):
    url = util.first_present([source.fetch_url_override, source.url])
    
    twitter_data = twitter_source_fetch.twitter_fetch_data_from_url(url)
    if twitter_data:
        return twitter_data, None
    
    markup = util.url_fetch(url)
    if not markup:
        return None, None
    
    # is this an rss feed itself?
    feed = parse_as_feed(markup)
    if feed:
        return {"type": "rss", "url": url}, feed
    
    # try finding some linked rss:
    soup = bs4.BeautifulSoup(markup, 'lxml')
    feed_url = rss_tools.find_linked_rss(soup, url)
    if feed_url:
        return {"type": "rss", "url": feed_url}, None
    
    wp_rss_link = url + "/?feed=rss"
    feed = parse_as_feed(util.url_fetch(wp_rss_link))
    if feed:
        return {"type": "rss", "url": wp_rss_link}, feed
    
    # is there a twitter account linked?
    twitter_data = twitter_source_fetch.linked_twitter_fetch_data(soup)
    if twitter_data:
        return twitter_data, None
    
    return None, None
      
def twitter_fetch(data, _):
    return twitter_source_fetch.fetch_timeline(data['username'])

def rss_fetch(data, feed_content):
    url = data['url']
    if not feed_content:
        markup = util.url_fetch(url)
        if markup:
            feed_content = parse_as_feed(markup)
    
    if not feed_content:
        return None
    
    parsed = feed_content
    
    source_entry_processor = create_source_entry_processor(url)
    feed_title = parsed['feed']['title']
    entries = []
    latest_date = None
    for entry in parsed['entries']:
        if 'link' in entry and 'title' in entry:
            # print entry
            link_url = urljoin(url, entry['link'].strip())
            title = entry['title']
            
            pub_time = entry.get('published_parsed', entry.get('updated_parsed'))
            if pub_time:
                published = datetime.datetime.fromtimestamp(mktime(pub_time))
            else:
                published = None
            result_entry = {"title": title, "url": link_url, "published": published}
            source_entry_processor(result_entry, entry)
            entries.append(result_entry)
    
    return FetchResult('rss', feed_title, entries)

