import bs4
from urlparse import urljoin
import speedparser
# import feedparser as speedparser

def find_linked_rss(soup, url):
    links = soup.find_all('link', attrs={'rel': 'alternate', 'type': ['application/rss+xml', 'application/atom+xml']})
    print "ALL LINKS:", links
    link = soup.find('link', attrs={'rel': 'alternate', 'type': ['application/rss+xml', 'application/atom+xml']})
    if link and type(link) == bs4.element.Tag and link['href']:
        feed_url = urljoin(url, link['href'])
        return feed_url
    return None

def parse_as_feed(markup):
    # TODO: do some fail-fast checks for rss-feedliness to avoid parsing the whole document
    parsed = speedparser.parse(markup)
    # print 'PARSED:', parsed
    if parsed:
        if len(parsed.get('entries', [])) > 0:
            return parsed
