#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import webapp2
import api
from model import Source, Article, Subscription
from google.appengine.ext import ndb
import json
from pprint import pprint
from mirror import MirrorHandler
import dump
import util
import file_storage
from template import template

def send_json(handler, content):
    handler.response.headers.add_header('Content-Type', 'application/json')
    handler.response.write(json.dumps(content))

class MainHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write('Hello world!')

class SubscribeHandler(webapp2.RequestHandler):
    def post(self):
        url = self.request.get('url')
        uid = self.request.get('uid')
        send_json(self, api.subscribe(uid, url))

class SourceHandler(webapp2.RequestHandler):
    def get(self):
        id = self.request.get('id')
        send_json(self, ndb.Key('Source', id).get().json(include_articles=True))

class ArticleHandler(webapp2.RequestHandler):
    def get(self):
        id = self.request.get('id')
        url = self.request.get('url')
        
        if id:
            article = ndb.Key('Article', id).get()
            article.fetch_if_needed(ignore_previous_failure=True)
        else:
            article = api.ensure_article_at_url(url)
        
        send_json(self, article.json(include_article_json=True))

class FeedHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('uid')
        send_json(self, api.feed(uid))

class SubscriptionsHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('uid')
        send_json(self, api.subscriptions(uid))

class UnsubscribeHandler(webapp2.RequestHandler):
    def post(self):
        self.delete()
    
    def delete(self):
        uid = self.request.get('uid')
        url = self.request.get('url')
        api.unsubscribe(uid, url)
        send_json(self, {"success": True})

class BookmarksHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('uid')
        since = float(self.request.get('since')) if self.request.get('since') else None
        send_json(self, api.bookmarks(uid, since=since))
    
    def post(self):
        uid = self.request.get('uid')
        article_id = self.request.get('article_id')
        article_url = self.request.get('article_url')
        reading_pos = self.request.get('reading_position')
        if reading_pos: reading_pos = json.loads(reading_pos)
        bookmark = api.add_or_update_bookmark(uid, reading_pos, article_id, article_url)
        send_json(self, {"bookmark": bookmark.json() if bookmark else None})
    
    def delete(self):
        uid = self.request.get('uid')
        article_id = self.request.get('article_id')
        api.delete_bookmark(uid, article_id)
        send_json(self, {"success": True})
    
class ArticleTestFetchHandler(webapp2.RequestHandler):
    def post(self):
        url = self.request.get('url')
        article = api.ensure_article_at_url(url, force_fetch=True)
        type = self.request.get('type')
        if type == 'html':
            self.response.write(article.content.get().html)
        elif type == 'article_json':
            self.response.headers.add_header('Content-Type', 'application/json')
            self.response.write(json.dumps({
                "article": article.content.get().article_json
            }))
        else:
            self.response.headers.add_header('Content-Type', 'application/json')
            self.response.write(json.dumps({
                "article": article.json(include_article_json=True)
            }))

class TestHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write(template('test.html'))
    
    def post(self):
        test = self.request.get('test')
        if test == 'source':
            from source_fetch import _source_fetch
            from api import ensure_source
            url = self.request.get('url')
            source = ensure_source(url, suppress_immediate_fetch=True)
            self.response.headers.add_header('Content-Type', 'text/plain')
            pprint(_source_fetch(source), self.response.out)

class StatsHandler(webapp2.RequestHandler):
    def get(self):
        send_json(dump.stats())

class ArticleDumpHandler(webapp2.RequestHandler):
    def get(self):
        send_json(dump.dump_items(cursor=self.request.get('cursor')))

class SimpleExtractHandler(webapp2.RequestHandler):
    def get(self):
        from bs4 import BeautifulSoup as bs
        from article_extractor import extract
        url = self.request.get('url')
        markup = util.url_fetch(url)
        soup = bs(markup, 'lxml')
        text = u""
        if soup.title:
            title = soup.title.string
            h1 = soup.new_tag('h1')
            h1.string = title
            text += unicode(h1)
        # print create_soup_with_ids(markup).prettify()
        text += extract(markup, url)
        self.response.headers['Access-Control-Allow-Origin'] = '*'
        self.response.write(text)

class FeaturedSourcesHandler(webapp2.RequestHandler):
    def get(self):
        send_json(self, api.featured_sources_by_category(category=self.request.get('category')))

class SourceSearchHandler(webapp2.RequestHandler):
    def get(self):
        send_json(self, api.source_search(self.request.get('query')))

class OkHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write('ok')
    
    def post(self):
        self.response.write('ok')

app = webapp2.WSGIApplication([
    ('/', MainHandler),
    ('/article', ArticleHandler),
    ('/source', SourceHandler),
    ('/feed', FeedHandler),
    ('/subscriptions', SubscriptionsHandler),
    ('/subscriptions/add', SubscribeHandler),
    ('/subscriptions/delete', UnsubscribeHandler),
    ('/bookmarks', BookmarksHandler),
    ('/sources/featured', FeaturedSourcesHandler),
    ('/sources/search', SourceSearchHandler),
    ('/test', TestHandler),
    ('/test/article_fetch', ArticleTestFetchHandler),
    ('/mirror', MirrorHandler),
    ('/stats', StatsHandler),
    ('/dump/articles', ArticleDumpHandler),
    ('/extract', SimpleExtractHandler),
    ('/_dbFile', file_storage._DBFileHandler),
    ('/_ah/start', OkHandler)
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

