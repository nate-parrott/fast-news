class FetchResult(object):
    def __init__(self, method, feed_title, entries):
        self.method = method
        self.feed_title = feed_title
        self.entries = entries # {"url": url, "title": title, "published": datetime}
        self.brand = None
    
    def __repr__(self):
        return (u"FetchResult.{0}('{1}'): {2} ".format(self.method, self.feed_title, self.entries)).encode('utf-8')
