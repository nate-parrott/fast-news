
def find_tags(soup):
    tags = set()
    
    for meta in soup.find_all('meta', {'property': 'article:tag'}):
        if meta.has_attr('content'):
            tags.add(meta['content'])
    
    keyword_meta = soup.find('meta', {'name': 'keywords'})
    if keyword_meta and keyword_meta.has_attr('content'):
        for keyword in keyword_meta['content'].split(','):
            tags.add(keyword.strip())
    
    for a in soup.find_all('a'):
        
        is_tag_rel = a.has_attr('rel') and a['rel'] == 'tag'
        has_tag_class = a.has_attr('class') and 'tag' in a['class']
        
        if is_tag_rel or has_tag_class:
            tag = a.text.strip()
            tags.add(tag)   
         
    return [tag for tag in tags if len(tag) > 0 and len(tag) < 128]

if __name__ == '__main__':
    import urllib2
    from bs4 import BeautifulSoup
    from cookielib import CookieJar
    
    def fetch(url):
        cj = CookieJar()
        opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
        p = opener.open(url)
        return p.read()
    
    urls = [
        'https://hackaday.io/project/18491-worlds-first-32-bit-homebrew-cpu'
        # 'http://www.nytimes.com/2016/12/17/opinion/sunday/the-tent-cities-of-san-francisco.html?smid=fb-nytimes&smtyp=cur'
        # 'http://www.vice.com/read/how-weed-is-curbing-opioid-addiction-for-some-canadians',
        # 'http://gothamist.com/2016/11/02/smooth_subway_map_nyc.php',
        # 'http://www.vice.com/read/the-14-year-old-syrian-refugee-who-built-the-aleppo-of-his-dreams'
    ]
    for url in urls:
        soup = BeautifulSoup(fetch(url), 'lxml')
        print url
        print find_tags(soup)
