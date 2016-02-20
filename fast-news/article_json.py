import time
import bs4
from pprint import pprint
import urlparse
from util import url_fetch
from StringIO import StringIO
from PIL import Image
from tinyimg import tinyimg
import re

def article_json(article, content):
    print 'article json'
    if content and content.html:
        print 'has html'
        return _article_json(content.html, article)
    return None

def url_fetch_and_time(url, timeout):
    t1 = time.time()
    res = url_fetch(url)
    t2 = time.time()
    return res, (t2 - t1)

MAX_TIME_FOR_EXTERNAL_FETCHES = 4.0

def iterate_tree(soup):
    yield ('enter', soup)
    for child in soup:
        if type(child) == bs4.NavigableString:
            yield ('text', unicode(child.string))
        elif type(child) == bs4.Tag:
            for x in iterate_tree(child):
                yield x
    yield ('exit', soup)

class Segment(object):
    def __init__(self):
        pass
    
    def is_text_segment(self):
        return False
    
    def json(self):
        return {"type": None}
    
    def is_empty(self):
        return True
    
    def text_content(self):
        return ""

class TextSegment(Segment):
    def __init__(self, kind):
        super(TextSegment, self).__init__()
        self.kind = kind # 'p', 'h0', 'h1', 'h2', 'h3' only
        self.content = [{}] # [{attributes}, "text", "more text", [{attributes}, "some text"]]
        # attributes: {'bold': True, 'link': 'http://google.com', 'italic': True}
        self.stack = [self.content]
    
    def is_text_segment(self):
        return True
    
    def is_empty(self):
        return self.text_section_is_empty(self.content)
    
    def text_section_is_empty(self, section):
        for child in section[1:]:
            if type(child) == unicode and len(child.strip()) > 0:
                return False
            elif not self.text_section_is_empty(child):
                return False
        return True
    
    def open_text_section(self, attributes):
        section = [attributes]
        self.stack[-1].append(section)
        self.stack.append(section)
    
    def add_text(self, text):
        text = re.sub(r"\s+", " ", text)
        self.stack[-1].append(text)
    
    def close_text_section(self):
        if len(self.stack) > 1:
            self.stack.pop()
    
    def text_content(self):
        def _traverse(content):
            t = ""
            for child in content[1:]:
                if type(child) in (unicode, str):
                    t += child
                else:
                    t += _traverse(child)
            return t
        return _traverse(self.content)
    
    def json(self):
        j = super(TextSegment, self).json()
        j['type'] = 'text'
        j['kind'] = self.kind
        j['content'] = self.content
        return j

class ImageSegment(Segment):
    def __init__(self, src, size=None):
        super(ImageSegment, self).__init__()
        self.src = src
        self.size = size
        self.tiny = None
    
    def json(self):
        j = super(ImageSegment, self).json()
        j['type'] = 'image'
        j['src'] = self.src
        j['size'] = self.size
        j['tiny'] = self.tiny
        return j
    
    def fetch_image_data(self, time_left):
        elapsed = 0
        if self.src and time_left > 0:
            result, elapsed = url_fetch_and_time(self.src, time_left)
            # print "ELAPSED", elapsed
            time_left -= elapsed
            if result:
                try:
                    f = StringIO(result)
                    image = Image.open(f)
                    self.size = image.size
                    self.tiny = tinyimg(image)
                except IOError as e:
                    print "IO error during image fetch: {0}".format(e)
            else:
                print "Failed to fetch image at url:", self.src
        return elapsed
    
    def is_empty(self):
        return (self.src == None)

def _article_json(html, article):
    root_url = article.url
    
    def process_url(url):
        if url:
            return urlparse.urljoin(root_url, url)
        else:
            return None
    
    time_left = 14
    
    soup = bs4.BeautifulSoup(html, 'lxml')
    segments = []
    
    cur_segment = None
    block_elements = set(['p', 'div', 'table', 'header', 'section', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'caption'])
    text_tag_attributes = {'strong': {'bold': True}, 'b': {'bold': True}, 'em': {'italic': True}, 'i': {'italic': True}, 'a': {}}
    for (event, data) in iterate_tree(soup):
        if event == 'enter' and data.name == 'br':
            event = 'text'
            data = u"\n"
        
        if event == 'enter':
            if data.name in block_elements:
                # open a new block segment:
                kind = {'h1': 'h1', 'h2': 'h2', 'h3': 'h3', 'h4': 'h3', 'h5': 'h3', 'h6': 'h6'}.get(data.name, 'p')
                cur_segment = TextSegment(kind)
                segments.append(cur_segment)
            elif data.name == 'img':
                # TODO: fetch aspect ratio
                cur_segment = ImageSegment(process_url(data.get('src')))
                time_left -= cur_segment.fetch_image_data(time_left)
                segments.append(cur_segment)
            else:
                # this is an inline (text) tag:
                if cur_segment == None or not cur_segment.is_text_segment():
                    # create a new text segment:
                    cur_segment = TextSegment('p')
                    segments.append(cur_segment)
                attrs = text_tag_attributes.get(data, {})
                if data.name == 'a':
                    attrs['link'] = process_url(data.get('href'))
                cur_segment.open_text_section(attrs)
        elif event == 'text':
            if cur_segment == None or not cur_segment.is_text_segment():
                cur_segment = TextSegment('p')
                segments.append(cur_segment)
            cur_segment.add_text(data)
        elif event == 'exit':
            if data.name in block_elements:
                cur_segment = None
            elif data.name in text_tag_attributes and cur_segment != None and cur_segment.is_text_segment():
                cur_segment.close_text_section()
    
    segments = [s for s in segments if not s.is_empty()]
    
    # discard small images:
    segments = [s for s in segments if not (isinstance(s, ImageSegment) and s.size and s.size[0] * s.size[1] < (50 * 50))]
    
    title_already_exists = article.title and len([seg for seg in segments[:min(3,len(segments))] if seg.text_content().lower() == article.title.lower()]) > 0
    has_early_h1 = len([seg for seg in segments[:min(3,len(segments))] if seg.is_text_segment() and seg.kind == 'h1'])
    
    has_early_image = len([seg for seg in segments[:min(3,len(segments))] if isinstance(seg, ImageSegment)]) > 0
    
    if article.title and not (title_already_exists or has_early_h1):
        title = TextSegment('h1')
        title.add_text(article.title)
        segments = [title] + segments
    
    if article.top_image and not has_early_image:
        top_image = ImageSegment(article.top_image)
        time_left -= top_image.fetch_image_data(time_left)
        segments = [top_image] + segments
    
    return {"segments": [s.json() for s in segments]}

if __name__ == '__main__':
    import json
    pprint(_article_json(open('samples/table.html').read()))
    # print json.dumps(_article_json(open('samples/table.html').read()))
