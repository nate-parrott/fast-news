import datetime
from canonical_url import canonical_url
from model import Source, Article, Subscription
from google.appengine.ext import ndb
from util import get_or_insert

def fetch_article(url):
    id = Article.id_for_article(url, 'http://example.com')
    article, inserted = get_or_insert(Article, id)
    if inserted:
        article.added_date = datetime.datetime.now()
        article.added_order = 0
    article.url = canonical_url(url)
    article.published = datetime.datetime.now()
    # article.title = "A test"
    article.title = None
    article.put()
    article.fetch_now()
    return article
