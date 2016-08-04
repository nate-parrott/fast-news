#!/usr/bin/env python
# -*- coding: utf-8 -*-

import time
import bs4
from pprint import pprint
import urlparse
from util import url_fetch, normalized_compare
from soup_tools import iterate_tree
from StringIO import StringIO
from PIL import Image
from tinyimg import tinyimg
import re
import relative_time
import article_extractor
from collections import defaultdict

def url_fetch_and_time(url, timeout):
    t1 = time.time()
    res = url_fetch(url, timeout=timeout)
    t2 = time.time()
    return res, (t2 - t1)

MAX_TIME_FOR_EXTERNAL_FETCHES = 4.0

class Segment(object):
    def __init__(self):
        self.is_part_of_title = False
        # measured in em:
        self.left_padding = 0
        self.right_padding = 0

    def is_text_segment(self):
        return False

    def json(self):
        d = {"type": None, "is_part_of_title": self.is_part_of_title}
        if self.left_padding: d['left_padding'] = self.left_padding
        if self.right_padding: d['right_padding'] = self.right_padding
        return d

    def is_empty(self):
        return True

    def text_content(self):
        return ""

class TextSegment(Segment):
    def __init__(self, kind):
        super(TextSegment, self).__init__()
        self.kind = kind # 'title', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'caption' only
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
        self.is_top_image = False

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

def first_non_null(items):
    for i in items:
        if i: return i

def populate_article_json(article, content):
    if not content.html: return

    root_url = article.url

    def process_url(url):
        if url:
            return urlparse.urljoin(root_url, url)
        else:
            return None

    time_left = 3

    soup = bs4.BeautifulSoup(content.html, 'lxml')
    segments = []

    cur_segment = None
    tag_stack = []
    class_stack = []
    block_elements = set(['p', 'div', 'table', 'header', 'section', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'caption', 'pre', 'blockquote', 'li', 'figcaption'])
    text_tag_attributes = {'strong': {'bold': True}, 'b': {'bold': True}, 'em': {'italic': True}, 'i': {'italic': True}, 'a': {}, 'code': {'monospace': True}, 'span': {}}

    def create_text_segment(kind):
        s = TextSegment(kind)
        if 'blockquote' in tag_stack: s.left_padding += 1
        return s

    def ensure_text(segment):
        # if the segment passed in is text, returns it
        # otherwise, creates a new one:
        if segment == None or not segment.is_text_segment():
            # create a new text segment:
            segment = create_text_segment('p')
            segments.append(segment)
        return segment

    def is_descendant_of_class(class_name):
        return len([c for c in class_stack if c is not None and class_name in c]) > 0

    for (event, data) in iterate_tree(soup):
        if event == 'enter' and data.name == 'br':
            event = 'text'
            data = u"\n"

        if event == 'enter':
            tag_stack.append(data.name)
            class_stack.append(data.get('class'))
            if data.name in block_elements:
                # open a new block segment:
                kind = {'h1': 'h1', 'h2': 'h2', 'h3': 'h3', 'h4': 'h4', 'h5': 'h5', 'h6': 'h6', 'blockquote': 'blockquote', 'caption': 'caption', 'li': 'li', 'figcaption': 'caption'}.get(data.name, 'p')
                cur_segment = create_text_segment(kind)

                attrs = cur_segment.content[0]
                if data.name == 'pre': attrs['monospace'] = True

                segments.append(cur_segment)
            elif data.name == 'img':
                cur_segment = ImageSegment(process_url(data.get('src')))
                time_left -= cur_segment.fetch_image_data(time_left)
                segments.append(cur_segment)
            else:
                # this is an inline (text) tag:
                cur_segment = ensure_text(cur_segment)
                attrs = dict(text_tag_attributes.get(data.name, {}))
                if data.name == 'a':
                    attrs['link'] = process_url(data.get('href'))
                cur_segment.open_text_section(attrs)
        elif event == 'text':
            cur_segment = ensure_text(cur_segment)
            if is_descendant_of_class('twitter-tweet'):
                cur_segment.content[0]['color'] = 'twitter'
            cur_segment.add_text(data)
        elif event == 'exit':
            if data.name in block_elements:
                cur_segment = None
            elif data.name in text_tag_attributes and cur_segment != None and cur_segment.is_text_segment():
                cur_segment.close_text_section()

            tag_stack.pop()
            class_stack.pop()

    segments = [s for s in segments if not s.is_empty()]

    # discard small images:
    segments = [s for s in segments if not (isinstance(s, ImageSegment) and s.size and s.size[0] * s.size[1] < (100 * 100))]

    content.article_text = u"\n"

    title_segment = None
    if article.title:
        for seg in segments[:min(3,len(segments))]:
            if normalized_compare(seg.text_content(), article.title):
                title_segment = seg

    early_h1s = [seg for seg in segments[:min(3,len(segments))] if seg.is_text_segment() and seg.kind == 'h1']
    early_h1 = early_h1s[0] if len(early_h1s) else None

    early_images = [seg for seg in segments[:min(3,len(segments))] if isinstance(seg, ImageSegment)]
    early_image = early_images[0] if len(early_images) else None

    if article.title and not (title_segment or early_h1):
        title_segment = TextSegment('title')
        title_segment.add_text(article.title)
        segments = [title_segment] + segments

    top_image = None
    if article.top_image and not early_image:
        top_image = ImageSegment(article.top_image)
        time_left -= top_image.fetch_image_data(time_left)
        segments = [top_image] + segments

    # identify parts of the title:
    title_seg = first_non_null([title_segment, early_h1])
    if title_seg: title_seg.is_part_of_title = True

    title_image = first_non_null([early_image, top_image])
    if title_image: title_image.is_part_of_title = True

    index_to_insert_meta_line = ([0] + [i+1 for i, seg in enumerate(segments) if seg.is_part_of_title])[-1]
    meta_line = create_meta_line(article)
    meta_line.is_part_of_title = True
    segments.insert(index_to_insert_meta_line, meta_line)

    content.text = u"\n".join([seg.text_content() for seg in segments if seg.is_text_segment() and seg.kind != 'title'])
    content.is_low_quality_parse = len(content.text.split(" ")) < 50
    content.article_json = {"segments": [s.json() for s in segments], "is_low_quality_parse": content.is_low_quality_parse}

    if title_image:
        article.top_image = title_image.src
        article.top_image_tiny_json = title_image.tiny

def create_meta_line(article):
    seg = TextSegment('meta')
    parts = []
    if article.published:
        parts.append(article.published.strftime("%B %-d, %Y"))
        # parts.append(u"{0} ago".format(relative_time.get_age(article.published)))
    if article.author:
        parts.append(u"{0}".format(article.author))
    if article.site_name:
        parts.append(u"{0}".format(article.site_name))
    elif article.url:
        display = article_extractor.normalize_url(article.url)
        parts.append(u"{0}".format(display))
    seg.add_text(u" • ".join(parts))
    return seg

if __name__ == '__main__':
    import json
    pprint(_article_json(open('samples/table.html').read()))
    # print json.dumps(_article_json(open('samples/table.html').read()))
