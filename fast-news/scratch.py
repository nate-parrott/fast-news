import feedparser, urllib2
import pprint

def url_fetch(url): # returns file-like object
    headers = {"User-Agent": "fast-news-bot"}
    req = urllib2.Request(url, None, headers)
    return urllib2.urlopen(req)

if __name__ == '__main__':
    feed = url_fetch('http://feeds.arstechnica.com/arstechnica/index')
    parsed = feedparser.parse(feed)
    # pprint.pprint(parsed)
    
    if len(parsed['feed']) == 0 and len(parsed['entries']) == 0:
        print 'none'
    
    title = parsed['feed']['title']
    print title
    # print title
    # pprint.pprint(parsed)
    for entry in parsed['entries']:
        # print 'hey'
        # print entry
        if 'link' in entry:
            print entry['link']
        print entry.get('published_parsed')
