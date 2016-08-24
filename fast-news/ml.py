import json
from util import send_json
from google.appengine.ext import ndb
import webapp2
from model import Article
import datetime
import util

def get_articles(count=10, force=False):
    max_time = datetime.datetime.now() if force else datetime.datetime.now() - datetime.timedelta(hours=1)
    q = Article.query(Article.ml_service_time <= max_time, Article.ml_service_time != None).order(-Article.ml_service_time)
    articles = q.fetch(count)
    for a in articles:
        a.ml_service_time = datetime.datetime.now()
    ndb.put_multi(articles)
    return articles

def backfill_articles_for_ml():
    count = 500
    put_batch = []
    for article in Article.query().order(-Article.added_date).iter(count):
        if not article.ml_service_time and not article.processed_by_ml_service:
            article.ml_service_time = util.datetime_from_timestamp(0)
            put_batch.append(article)
        if len(put_batch) > 50:
            ndb.put_multi(put_batch)
            put_batch = []
    if len(put_batch): ndb.put_multi(put_batch)

def article_json(article):
    content = article.content.get() if article.content else None
    text = content.text if content else ""
    return {
        "id": article.key.id(),
        "title": article.title,
        "text": text,
        "description": article.description,
        "site": article.source.id() if article.source else None
    }

class ArticlesHandler(webapp2.RequestHandler):
    def get(self):
        force = True if self.request.get('force') else False
        count = int(self.request.get('count', '5'))
        resp = {
            "articles": map(article_json, get_articles(force=force, count=count))
        }
        send_json(self, resp)
    
    def post(self):
        # TODO: have some security here maybe?
        payload = json.loads(self.request.body)
        to_put = []
        for id, data in payload['articles'].iteritems():
            article = ndb.Key(Article, id).get() # TODO: do a get_multi on all these
            apply_ml_payload_to_article(data, article)
            to_put.append(article)
        if len(to_put): ndb.put_multi(to_put)
        send_json(self, {"success": True})

def apply_ml_payload_to_article(payload, article):
    article.ml_topics = payload.get('topics', [])
    article.ml_service_time = None
    article.processed_by_ml_service = True
