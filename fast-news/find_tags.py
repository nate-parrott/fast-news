
def find_tags(soup):
    tags = set()
    
    for meta in soup.find_all('meta', {'property': 'article:tag'}):
        if meta.has_attr('content'):
            tags.add(meta['content'])
    
    keyword_meta = soup.find('meta', {'name': 'keywords'})
    if keyword_meta and keyword_meta.has_attr('content'):
        for keyword in keyword_meta['content'].split(','):
            tags.add(keyword.strip())
    
    for a in soup.find_all('a', {'rel': 'tag'}):
        tag = a.text.strip()
        if len(tag):
            tags.add(tag)
    
    return tags

if __name__ == '__main__':
    import urllib2
    from bs4 import BeautifulSoup
    for url in ['http://www.vice.com/read/how-weed-is-curbing-opioid-addiction-for-some-canadians', 'http://gothamist.com/2016/11/02/smooth_subway_map_nyc.php', 'http://www.vice.com/read/the-14-year-old-syrian-refugee-who-built-the-aleppo-of-his-dreams']:
        soup = BeautifulSoup(urllib2.urlopen(url).read(), 'lxml')
        print url
        print find_tags(soup)
