import json
from bs4 import BeautifulSoup
import urllib2
from multiprocessing import Pool
from cookielib import CookieJar

def url_fetch(url, timeout=10, return_response_obj=False):
    cj = CookieJar()
    opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
    opener.addheaders = [("User-Agent", "fast-news-bot")]
    try:
        resp = opener.open(url, timeout=timeout)
        if return_response_obj:
            return resp
        else:
            return resp.read()
    except HTTPException as e:
        print "{0}: {1}".format(url, e)
    except urllib2.URLError as e:
        print "{0}: {1}".format(url, e)
    return None

def title_for_url(url):
    return BeautifulSoup(url_fetch(url)).title.text

def title_for_url_safe(url):
    try:
        t = title_for_url(url)
        print url, ':', t
        return t
    except Exception as e:
        print url, 'failed:', e
        return None

items = json.load(open('top.json'))['sites']
titles = Pool(15).map(title_for_url_safe, [i['url'] for i in items])
for item, title in zip(items, titles):
    item['title'] = title
open('top-with-titles.json', 'w').write(json.dumps({"sites": items}))
