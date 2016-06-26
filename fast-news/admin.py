#!/usr/bin/env python

import webapp2
from model import Source

class RescheduleSourceFetchesHandler(webapp2.RequestHandler):
    def post(self):
        sources = Source.query().fetch(10000, projection=['url'])
        for source in sources:
            source.enqueue_fetch()
        self.response.write('done')

app = webapp2.WSGIApplication([
    ('/admin/reschedule_source_fetches', RescheduleSourceFetchesHandler)
], debug=True)
