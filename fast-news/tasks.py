import webapp2
from model import Article, Source, ErrorReport
from google.appengine.ext import ndb
from feed import Feed
import ml

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
        try:
            source.fetch_now()
        except Exception as e:
            source.last_fetch_failed = True
            source.put()
            ErrorReport.with_current_exception('source_fetch')
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
    ('/tasks/feeds/update', FeedUpdateHandler),
    ('/tasks/ml/articles', ml.ArticlesHandler)
], debug=True)

if False:
    def cprofile_wsgi_middleware(app):
        """
        Call this middleware hook to enable cProfile on each request.  Statistics are dumped to
        the log at the end of the request.
        :param app: WSGI app object
        :return: WSGI middleware wrapper
        """
        def _cprofile_wsgi_wrapper(environ, start_response):
            import cProfile, cStringIO, pstats, logging
            profile = cProfile.Profile()
            try:
                return profile.runcall(app, environ, start_response)
            finally:
                stream = cStringIO.StringIO()
                stats = pstats.Stats(profile, stream=stream)
                stats.strip_dirs().sort_stats('cumulative', 'time', 'calls').print_stats(50)
                logging.info('cProfile data:\n%s', stream.getvalue())
        return _cprofile_wsgi_wrapper

    def webapp_add_wsgi_middleware(app):
        return cprofile_wsgi_middleware(app)

    app = webapp_add_wsgi_middleware(app)

