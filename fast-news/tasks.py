import webapp2
from model import Article, Source, ErrorReport
from google.appengine.ext import ndb

class ArticleFetchHandler(webapp2.RequestHandler):
    def post(self):
        article = ndb.Key('Article', self.request.get('id')).get()
        try:
            article.fetch_now()
        except Exception as e:
            article.fetch_failed = True
            article.put()
            ErrorReport.with_current_exception('article_fetch')

class SourceFetchHandler(webapp2.RequestHandler):
    def post(self):
        source = ndb.Key('Source', self.request.get('id')).get()
        source.fetch_now()
        source.enqueue_fetch()

app = webapp2.WSGIApplication([
    ('/tasks/articles/fetch', ArticleFetchHandler),
    ('/tasks/sources/fetch', SourceFetchHandler)
], debug=True)
