import webapp2
from model import Article, Source, ErrorReport
from google.appengine.ext import ndb
from feed import Feed

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

class FeedUpdateHandler(webapp2.RequestHandler):
    def post(self):
        # TODO: wrap in try-catch
        feed = Feed.get_for_user(self.request.get('uid'))
        feed.update()
        feed.schedule_update()

app = webapp2.WSGIApplication([
    ('/tasks/articles/fetch', ArticleFetchHandler),
    ('/tasks/sources/fetch', SourceFetchHandler),
    ('/tasks/feeds/update', FeedUpdateHandler)
], debug=True)
