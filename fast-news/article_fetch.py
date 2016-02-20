import urllib2, urllib
import datetime
import json
from util import url_fetch, first_present, truncate
import readability
from bs4 import BeautifulSoup
from model import ArticleContent
from urlparse import urljoin
from article_json import article_json
# also look at https://github.com/seomoz/dragnet/blob/master/README.md

def find_meta_value(soup, prop):
    tag = soup.find('meta', attrs={'property': prop})
    if tag:
        return tag['content']

def article_fetch(article):
    if article.content:
        content = article.content.get()
    else:
        content = ArticleContent()
        content.put()
        print 'KEY', content.key
        article.content = content.key
    
    def make_url_absolute(url):
        return urljoin(article.url, url) if url else None
    
    markup = url_fetch(article.url)
    if markup:
        # process markup:
        markup_soup = BeautifulSoup(markup, 'lxml')
        og_title = find_meta_value(markup_soup, 'og:title')
        og_image = find_meta_value(markup_soup, 'og:image')
        og_description = find_meta_value(markup_soup, 'og:description')
        
        # parse and process article content:
        doc = readability.Document(markup)
        content.html = doc.summary()
        doc_soup = BeautifulSoup(content.html, 'lxml')
        content.text = unicode(doc_soup.get_text()).strip()
        
        article.title = first_present([article.title, doc.short_title(), og_title])
        article.top_image = make_url_absolute(first_present([article.top_image, og_image]))
        
        # compute description:
        description = None
        if og_description and len(og_description.strip()):
            description = truncate(og_description.strip(), words=60)
        elif content.text and len(content.text.strip()) > 0:
            description = truncate(content.text, words=60)
        article.description = description
        
        content.article_json = article_json(article, content)
        
        article.fetch_failed = False
    else:
        article.fetch_failed = True
    article.fetch_date = datetime.datetime.now()
    content.put()
    article.put()

def article_fetch_old(article):
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
