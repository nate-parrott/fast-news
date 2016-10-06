import webapp2
import template
import model
import feed
import datetime

class Handler(webapp2.RequestHandler):
    def get(self):
        self.response.write(template.template("health.html", {}))
    
    def post(self):
        t = self.request.get('type')
        result = None
        
        if t == 'unfetched_sources':
            result = unfetched_sources()
        elif t == 'unrefreshed_feeds':
            result = unrefreshed_feeds()
        
        self.response.write(template.template("health.html", {"result": result, "result_type": t}))

def unfetched_sources():
    return 'Not yet implemented'

def unrefreshed_feeds():
    old_feeds = feed.Feed.query().order(feed.Feed.updated).fetch(500, projection=[feed.Feed.updated])
    now = datetime.datetime.now()
    ages = [(now - f.updated) for f in old_feeds if f.updated]
    if len(ages) == 0:
        return "No feeds ever updated"
    else:
        def percentile(p):
            return ages[int(p * len(ages) / 100)]
        return """
        Of {0} oldest feeds,
        Newest is {1} seconds old.
        50% oldest is {2} seconds old.
        90% oldest is {3} seconds old.
        95% oldest is {4} seconds old.
        Oldest is {5} seconds old.
        """.format(len(ages), ages[0], percentile(50), percentile(90), percentile(95), ages[-1])
    