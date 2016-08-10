#!/usr/bin/env python

import webapp2
from model import Source, Article
from canonical_url import canonical_url
from google.appengine.ext import ndb
import source_admin
import template
import source_search

class RescheduleSourceFetchesHandler(webapp2.RequestHandler):
    def post(self):
        sources = Source.query().fetch(10000)
        for source in sources:
            source.most_recent_article_added_date = None
            source.enqueue_fetch()
        self.response.write('done')

class PurgeSourceHandler(webapp2.RequestHandler):
    def post(self):
        url = canonical_url(self.request.get('url'))
        source_id = Source.id_for_source(url)
        source = ndb.Key(Source, source_id).get()
        while True:
            articles = Article.query(Article.source == source.key).order(-Article.added_date, Article.added_order).fetch(limit=100, keys_only=True)
            if len(articles) == 0: break
            ndb.delete_multi(articles)
        source.key.delete()
        self.response.write('Done')
                
class AdminHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write(template.template("admin.html", {}))

app = webapp2.WSGIApplication([
    ('/admin', AdminHandler),
    ('/admin/reschedule_source_fetches', RescheduleSourceFetchesHandler),
    ('/admin/purge_source', PurgeSourceHandler),
    ('/admin/sources', source_admin.SourcesAdminHandler),
    ('/admin/sources/(.+)', source_admin.SourceAdminHandler),
    ('/admin/source_search', source_search.SourceSearchAdmin)
], debug=True)
