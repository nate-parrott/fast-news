import urllib2
from bs4 import BeautifulSoup
import datetime

def article_fetch(article):
    content = ""
    title = ""
    try:
        data = urllib2.urlopen(article.url).read()
        soup = BeautifulSoup(data, 'lxml')
        article.html_content = data
        article.title = soup.find('title').string if soup.find('title') else ""
    except urllib2.URLError as e:
        print "URL error fetching {0}: {1}".format(article.url, e)
        article.fetch_failed = True
    article.fetch_date = datetime.datetime.now()
    article.put()
