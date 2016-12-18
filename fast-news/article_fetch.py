import urllib2, urllib
import datetime
import json
from util import url_fetch, first_present, truncate, url_fetch_future
from bs4 import BeautifulSoup
from model import ArticleContent
from urlparse import urljoin
from article_json import populate_article_json
import re
import article_extractor
import util
import mercury
from find_tags import find_tags
# also look at https://github.com/seomoz/dragnet/blob/master/README.md

def find_meta_value(soup, prop):
    tag = soup.find('meta', attrs={'property': prop})
    if tag:
        return tag['content']

def find_title(soup):
    if soup.title:
        return soup.title.text

def article_fetch(article, force_mercury=False):
    if article.content:
        content = article.content.get()
    else:
        content = ArticleContent()
        content.put()
        print 'KEY', content.key
        article.content = content.key
    
    def make_url_absolute(url):
        return urljoin(article.url, url) if url else None
    
    FORCE_AMP = False
    if FORCE_AMP:
        url = article.amp_url or article.url
    else:
        url = article.url
    DEFAULT_TO_MERCURY = True
    
    def fetch_normal():
        response = url_fetch(url, return_response_obj=True)
        # print 'INFO', response.info()
        if response and response.info().getheader('content-type', 'text/html').lower().split(';')[0].strip() == 'text/html':
            markup = response.read()
        else:
            print 'BAD MIME TYPE' if response else 'NO SUCCESSFUL RESPONSE'
            markup = None
    
        if markup:
            # process markup:
            markup_soup = BeautifulSoup(markup, 'lxml')
            og_title = find_meta_value(markup_soup, 'og:title')
            og_image = find_meta_value(markup_soup, 'og:image')
            og_description = find_meta_value(markup_soup, 'og:description')
            title_field = find_title(markup_soup)
        
            article.site_name = find_meta_value(markup_soup, 'og:site_name')
            
            article.tags = list(find_tags(markup_soup))
            
            # find author:
            article.author = find_author(markup_soup)
        
            # parse and process article content:
            content.html = article_extractor.extract(markup, article.url)
            doc_soup = BeautifulSoup(content.html, 'lxml')
        
            article.title = first_present([og_title, title_field, article.title])
            article.top_image = make_url_absolute(first_present([article.top_image, og_image]))
        
            populate_article_json(article, content)
        
            # compute description:
            description = None
            if og_description and len(og_description.strip()):
                description = truncate(og_description.strip(), words=40)
            elif content.text and len(content.text.strip()) > 0:
                description = truncate(content.text, words=40)
            article.description = re.sub(r"[\r\n\t ]+", " ", description).strip() if description else None
                
            return True
        else:
            return False
    
    def fetch_mercury():
        force_sync_doc_fetch = 'nytimes.com' in article.url # cookie-jar issue prevents using async urlfetch to get page content
        
        merc_future = mercury.fetch(article.url, future=True)
        if not force_sync_doc_fetch: doc_future = url_fetch_future(article.url)
        
        merc = merc_future()
        doc = url_fetch(article.url) if force_sync_doc_fetch else doc_future()
        
        print 'article fetch'
        print 'has doc:', doc is not None
        if doc:
            markup_soup = BeautifulSoup(doc, 'lxml')
            article.tags = list(find_tags(markup_soup))
            article.site_name = find_meta_value(markup_soup, 'og:site_name')
        
        if merc and len(merc.get('content') or "") >= 50:
            article.title = merc['title']
            article.top_image = merc['lead_image_url']
            if merc['date_published'] and not article.published:
                pass # TODO
            article.author = merc['author']
            content.html = merc['content']
            if not article.description:
                article.description = merc['excerpt']
            populate_article_json(article, content)
            return True
        else:
            return False
    
    if (force_mercury or DEFAULT_TO_MERCURY) and fetch_mercury():
        article.fetch_failed = False
        print "Successfully fetched {0} via mercury".format(url)
    else:
        article.fetch_failed = not fetch_normal()
    
    article.fetch_date = datetime.datetime.now()
    article.ml_service_time = util.datetime_from_timestamp(0) # mark this article as ready to be consumed by the ml service
    content.put()
    article.put()
    if article.source: article.source.get().invalidate_cache()

def find_author(markup_soup):
    print 'LOOKING FOR AUTHOR'
    # author = find_meta_value(markup_soup, 'article:author') # this actually returns FB urls; we don't want that
    author = None
    byline_meta = markup_soup.find('meta', attrs={'name': 'byl'})
    if byline_meta:
        author = byline_meta['content']
    print 'BYLINE: ', author
    author_link = markup_soup.find('a', rel='author')
    print 'AUTHOR LINK', author_link
    if author_link:
        author = author_link.get_text()
    if author and author.lower().startswith('by '):
        author = author[len('by '):]
    return author
