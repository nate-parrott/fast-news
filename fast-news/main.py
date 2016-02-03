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

class MainHandler(webapp2.RequestHandler):
    def get(self):
        self.response.write('Hello world!')

class SubscribeHandler(webapp2.RequestHandler):
    def post(self):
        url = self.request.get('url')
        uid = self.request.get('uid')
        self.response.write(json.dumps(api.subscribe(uid, url)))

class SourceHandler(webapp2.RequestHandler):
    def get(self):
        id = self.request.get('id')
        self.response.write(json.dumps(ndb.Key('Source', id).get().json()))

class ArticleHandler(webapp2.RequestHandler):
    def get(self):
        id = self.request.get('id')
        self.response.write(json.dumps(ndb.Key('Article', id).get().json()))

class FeedHandler(webapp2.RequestHandler):
    def get(self):
        uid = self.request.get('id')
        self.response.write(json.dumps(api.feed(uid)))

app = webapp2.WSGIApplication([
    ('/', MainHandler),
    ('/subscribe', SubscribeHandler),
    ('/article', ArticleHandler),
    ('/source', SourceHandler),
    ('/feed', FeedHandler)
], debug=True)
