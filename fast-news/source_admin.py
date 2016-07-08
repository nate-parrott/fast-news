from google.appengine.ext import ndb
import webapp2
from template import template
from model import Source
import api
import copy

class SourcesAdminHandler(webapp2.RequestHandler):
    def get(self):
        vars = {
            "featured_sources": Source.query().filter(Source.featured_priority >= 0).order(-Source.featured_priority).fetch()
        }
        self.response.write(template('sources.html', vars))
    
    def post(self):
        print "URL:", self.request.get('url')
        source = api.ensure_source(self.request.get('url'))
        self.redirect('sources/' + source.key.urlsafe())

source_fields = [
    {"name": "title"},
    {"name": "title_override", "type": "text"},
    {"name": "featured_priority", "type": "number"},
    {"name": "categories", "type": "text", "split": "//"},
    {"name": "color", "type": "text"},
    {"name": "icon_url", "type": "file_url", "image": True, "max_size": 200},
    {"name": "keywords", "type": "text"}
]

class SourceAdminHandler(webapp2.RequestHandler):
    def get(self, id):
        source = ndb.Key(urlsafe=id).get()
        fields = copy.deepcopy(source_fields)
        for field in fields:
            val = getattr(source, field['name'])
            if val:
                if field.get('split'): val = field.get('split').join(val)
                field['value'] = val
        vars = {
            "source": source,
            "fields": fields
        }
        self.response.write(template('source.html', vars))
    
    def post(self, id):
        source = ndb.Key(urlsafe=id).get()
        for field in source_fields:
            not_set = 28479847385045
            val = not_set
            content = self.request.get(field['name'])
            if content:
                t = field.get('type')
                if t == 'text':
                    val = content
                    if field.get('split'):
                        val = [v.strip() for v in val.split(field['split'])]
                elif t == 'number':
                    val = float(content)
            if val != not_set:
                setattr(source, field['name'], val)
        source.put()
        self.redirect('')
