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

class MainHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write('Hello world!')

class SubscribeHandler(webapp2.RequestHandler):
    def post(self):
        url = self.request.get('url')
        uid = self.request.get('uid')
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(api.subscribe(uid, url)))

class SourceHandler(webapp2.RequestHandler):
    def get(self):
        id = self.request.get('id')
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(ndb.Key('Source', id).get().json(include_articles=True)))

class ArticleHandler(webapp2.RequestHandler):
    def get(self):
        id = self.request.get('id')
        url = self.request.get('url')
        
        if id:
            article = ndb.Key('Article', id).get()
            article.fetch_if_needed(ignore_previous_failure=True)
        else:
            article = api.ensure_article_at_url(url)
        
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(article.json(include_article_json=True)))

class FeedHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('uid')
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(api.feed(uid)))

class SubscriptionsHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('uid')
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(api.subscriptions(uid)))

class UnsubscribeHandler(webapp2.RequestHandler):
    def post(self):
        self.delete()
    
    def delete(self):
        uid = self.request.get('uid')
        url = self.request.get('url')
        api.unsubscribe(uid, url)
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps({"success": True}))

class BookmarksHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('uid')
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(api.bookmarks(uid)))
    
    def post(self):
        uid = self.request.get('uid')
        article_id = self.request.get('article_id')
        article_url = self.request.get('article_url')
        reading_pos = self.request.get('reading_position')
        if reading_pos: reading_pos = json.loads(reading_pos)
        bookmark = api.add_or_update_bookmark(uid, reading_pos, article_id, article_url)
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps({"bookmark": bookmark.json() if bookmark else None}))
    
    def delete(self):
        uid = self.request.get('uid')
        article_id = self.request.get('article_id')
        api.delete_bookmark(uid, article_id)
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps({"success": True}))
    
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
        html = """
        <form method=POST action='subscriptions/add'>
            <h1>Test subscribe</h1>
            <input name=url placeholder=url>
            <input name=uid placeholder=uid>
            <input type=submit>
        </form>
        <form method=POST>
            <h1>Test source fetch</h1>
            <input type=hidden name=test value=source>
            <input name=url>
            <input type=submit>
        </form>
        <form method=POST action='/subscriptions/delete'>
            <h1>Test unsubscribe</h1>
            <input name=url placeholder=url>
            <input name=uid placeholder=uid>
            <input type=submit>
        </form>
        <form method=POST action='test/article_fetch'>
            <h1>Test article fetch</h1>
            <input name=url placeholder=url>
            <p><input type=radio name=type value=default checked>Default json</p>
            <p><input type=radio name=type value=html>Extracted HTML</p>
            <p><input type=radio name=type value=article_json>Article JSON</p>
            <input type=submit>
        </form>
        <form method=POST action='bookmarks'>
            <h1>Bookmark</h1>
            <input name=article_url type=url placeholder=article_url>
            <input name=uid placeholder=uid>
            <input type=submit>
        </form>
        """
        self.response.write(html)
    
    def post(self):
        test = self.request.get('test')
        if test == 'source':
            from source_fetch import _source_fetch
            from api import ensure_source
            url = self.request.get('url')
            source = ensure_source(url, suppress_immediate_fetch=True)
            self.response.headers.add_header('Content-Type', 'text/plain')
            pprint(_source_fetch(source), self.response.out)

app = webapp2.WSGIApplication([
    ('/', MainHandler),
    ('/article', ArticleHandler),
    ('/source', SourceHandler),
    ('/feed', FeedHandler),
    ('/subscriptions', SubscriptionsHandler),
    ('/subscriptions/add', SubscribeHandler),
    ('/subscriptions/delete', UnsubscribeHandler),
    ('/bookmarks', BookmarksHandler),
    ('/test', TestHandler),
    ('/test/article_fetch', ArticleTestFetchHandler),
    ('/mirror', MirrorHandler)
], debug=True)
