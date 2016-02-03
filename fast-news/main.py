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
        self.response.write(json.dumps(ndb.Key('Source', id).get().json()))

class ArticleHandler(webapp2.RequestHandler):
    def get(self):
        id = self.request.get('id')
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(ndb.Key('Article', id).get().json(include_content=True)))

class FeedHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('uid')
        self.response.headers.add_header('Content-Type', 'application/json')
        self.response.write(json.dumps(api.feed(uid)))

class TestHandler(webapp2.RequestHandler):
    def get(self):
        html = """
        <form method=POST action='/subscribe'>
            <h1>Test subscribe</h1>
            <input type=hidden name=test value=subscribe>
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
        """
        self.response.write(html)
    
    def post(self):
        test = self.request.get('test')
        if test == 'source':
            from source_fetch import _source_fetch
            from api import ensure_source
            url = self.request.get('url')
            source = ensure_source(url)
            self.response.headers.add_header('Content-Type', 'text/plain')
            pprint(_source_fetch(source), self.response.out)
        

app = webapp2.WSGIApplication([
    ('/', MainHandler),
    ('/subscribe', SubscribeHandler),
    ('/article', ArticleHandler),
    ('/source', SourceHandler),
    ('/feed', FeedHandler),
    ('/test', TestHandler)
], debug=True)
