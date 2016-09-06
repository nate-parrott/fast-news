from google.appengine.ext import ndb

class EmailEntry(ndb.Model):
    email = ndb.StringProperty()
    added = ndb.DateTimeProperty(auto_now_add=True)

def add_email(email):
    EmailEntry(email=email).put()
