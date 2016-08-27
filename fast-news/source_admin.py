from google.appengine.ext import ndb
import webapp2
from template import template
from model import Source
import api
import copy
import file_storage
import util
from google.appengine.api import images
import source_search

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
    {"name": "short_title", "type": "text"},
    {"name": "fetch_url_override", "type": "text"},
    {"name": "categories", "type": "text", "split": "//"},
    {"name": "color", "type": "text"},
    {"name": "icon_url", "type": "file_url", "image": True, "max_size": 200},
    {"name": "keywords", "type": "text"},
    {"name": "featured_priority", "type": "number", "hint": "For featured content, these should be NEGATIVE, or at least less than 1"},
    {"name": "shared_title_suffix", "type": "text"},
    {"name": "shared_hostname", "type": "text"}
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
                elif t == 'file_url':
                    f = util.get_uploaded_file(self.request, field['name'])
                    if f:
                        name, mime, data = f
                        if field.get('image') and 'max_size' in field:
                            val = store_resized_image(data, field['max_size'])
                        else:
                            val = file_storage.upload_file_and_get_url(data, mime)
            if val != not_set:
                setattr(source, field['name'], val)
        source.direct_fetch_data = None
        source.put()
        source_search.add_source_to_index(source)
        self.redirect('')

def store_resized_image(data, max_size):
    mime = 'image/png'
    img = images.Image(data)
    ow, oh = img.width, img.height
    scale = min(max_size*1.0/ow, max_size*1.0/oh, 1)
    img.resize(int(ow*scale), int(oh*scale))
    content_type = 'image/png'
    data = img.execute_transforms(output_encoding=images.PNG)
    return file_storage.upload_file_and_get_url(data, mime)
