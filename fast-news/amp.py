import urllib2
import json

KEY = 'AIzaSyD2SfIR_qen6zRn0nIJIg9fmgwk-AE4Xr0'
URL = 'https://acceleratedmobilepageurl.googleapis.com/v1/ampUrls:batchGet'

def amp_fetch(urls):
    body = json.dumps({"urls": urls})
    request = urllib2.Request(URL, body, headers={"X-Goog-Api-Key": KEY, "Content-Type": "application/json"})
    resp = json.loads(urllib2.urlopen(request).read())
    print resp
    results = {}
    for result in resp.get('ampUrls', []):
        orig = result['originalUrl']
        if orig in urls and result.get('cdnAmpUrl'):
            results[orig] = result['cdnAmpUrl']
    return results

def fetch_amp_urls_for_articles(articles):
    articles_by_url = {a.url: a for a in articles}
    for url, amp_url in amp_fetch(articles_by_url.keys()).iteritems():
        articles_by_url[url].amp_url = amp_url

if __name__ == '__main__':
    print amp_fetch('http://www.nytimes.com/2016/10/14/magazine/after-donald-trump-will-more-women-believe-their-own-stories.html')
