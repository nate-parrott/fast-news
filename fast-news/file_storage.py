import cloudstorage as gcs
from google.appengine.api import app_identity
import os
import uuid
from google.appengine.ext import ndb
import util
import urllib
import webapp2

class _DBFile(ndb.Model):
    data = ndb.BlobProperty()
    mime = ndb.StringProperty()

class _DBFileHandler(webapp2.RequestHandler):
    def get(self):
        f = ndb.Key(urlsafe=self.request.get('id')).get()
        self.response.headers.add_header('Content-Type', f.mime.encode('utf-8'))
        self.response.write(f.data)

def upload_file_and_get_url(data, mimetype='application/octet-stream'):
    if util.is_local_server():
        f = _DBFile(data=data, mime=mimetype)
        f.put()
        return '/_dbFile?id=' + urllib.quote(f.key.urlsafe())
    else:
        bucket_name = 'fast-news' # os.environ.get('BUCKET_NAME', app_identity.get_default_gcs_bucket_name())
        filename = uuid.uuid4().hex
        write_retry_params = gcs.RetryParams(backoff_factor=1.1)
        gcs_file = gcs.open('/' + bucket_name + '/' + filename,
                            'w',
                            content_type=mimetype,
                            options={'x-goog-acl': 'public-read'},
                            retry_params=write_retry_params)
        gcs_file.write(data)
        gcs_file.close()
        return "https://storage.googleapis.com/{0}/{1}".format(bucket_name,
                                                               filename)
