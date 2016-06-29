import urllib2, urllib
import datetime
import json
from util import url_fetch, first_present, truncate
from bs4 import BeautifulSoup
from model import ArticleContent
from urlparse import urljoin
from article_json import populate_article_json
import re
import article_extractor
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
    
    response = url_fetch(article.url, return_response_obj=True)
    print 'INFO', response.info()
    if response and response.info().getheader('content-type', 'text/html').lower().split(';')[0].strip() == 'text/html':
        markup = response.read()
    else:
        print 'BAD MIME TYPE'
        markup = None
    
    if markup:
        # process markup:
        markup_soup = BeautifulSoup(markup, 'lxml')
        og_title = find_meta_value(markup_soup, 'og:title')
        og_image = find_meta_value(markup_soup, 'og:image')
        og_description = find_meta_value(markup_soup, 'og:description')
        
        article.site_name = find_meta_value(markup_soup, 'og:site_name')
        
        # find author:
        article.author = find_author(markup_soup)
        
        # parse and process article content:
        content.html = article_extractor.extract(markup, article.url)
        doc_soup = BeautifulSoup(content.html, 'lxml')
        
        article.title = first_present([article.title, og_title])
        article.top_image = make_url_absolute(first_present([article.top_image, og_image]))
        
        populate_article_json(article, content)
        
        # compute description:
        description = None
        if og_description and len(og_description.strip()):
            description = truncate(og_description.strip(), words=40)
        elif content.text and len(content.text.strip()) > 0:
            description = truncate(content.text, words=40)
        article.description = re.sub(r"[\r\n\t ]+", " ", description).strip() if description else None
                
        article.fetch_failed = False
    else:
        article.fetch_failed = True
    article.fetch_date = datetime.datetime.now()
    content.put()
    article.put()

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
