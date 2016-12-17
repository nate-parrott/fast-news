import urllib2, urllib, json
from util import url_fetch_future

def fetch(article_url, future=False):
    URL = "https://mercury.postlight.com/parser?" + urllib.urlencode({"url": article_url})
    content_future = url_fetch_future(URL, headers={"x-api-key": 'bktV0YzhaQ7pL8lriDrfS1ehxat1bicT4y5sSAAF'})
    
    def future_fn():
        return json.loads(content_future())
    
    return future_fn if future else future_fn()
    """
    Cool fields:
    - lead_image_url (og:image)
    - excerpt (text description, truncated)
    - author
    - date_published (json date string)
    - next_page_url
    - title
    - content (HTML) (is an empty div if unparseable)
    """
    

if __name__ == '__main__':
    print json.dumps(fetch('http://google.com'))
    # print json.dumps(fetch('http://www.nytimes.com/2016/10/26/us/politics/donald-trump-interviews.html?hp&action=click&pgtype=Homepage&clickSource=story-heading&module=first-column-region&region=top-news&WT.nav=top-news&_r=0'))
