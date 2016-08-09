import urlparse
import tweepy
from fetch_result import FetchResult

def twitter_fetch_data_from_url(url):
    parsed = urlparse.urlparse(url)
    path_comps = parsed.path.split('/')
    if parsed.netloc.endswith('twitter.com') and len(path_comps) == 2:
        username = path_comps[1]
        if username not in ['i']:
            return {"type": "twitter", "username": username}
    return None

def linked_twitter_fetch_data(soup):
    meta = soup.find('meta', attrs={'name': 'twitter:site'})
    if meta:
        content = meta.get('content')
        if len(content) > 0 and content[0] == '@':
            return {"type": "twitter", "username": content[1:]}

def fetch_twitter(source, markup, url, add_rpc, got_result):
    parsed = urlparse.urlparse(url)
    path_comps = parsed.path.split('/')
    if parsed.netloc.endswith('twitter.com') and len(path_comps) == 2:
        username = path_comps[1]
        if username not in ['i']:
            got_result(fetch_timeline(username))

def fetch_timeline(username):
    consumer_key = 'tcWVrI4F96XMGvpvc1XJBB5PI'
    consumer_secret = 'btjKIApOnCWRDaqPhUmm0bNNtEE7BRZoVFTDxRMjm897Ieq6Rg'
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    api = tweepy.API(auth)
    
    name = None
    entries = []
    for status in api.user_timeline(username, count=100):
        if status.in_reply_to_status_id: continue
        name = status.author._json['name']
        text = status.text
        urls = status.entities['urls']
        if len(urls):
            url = urls[0]['expanded_url']
            start, end = urls[0]['indices']
            if url.startswith('https://twitter.com'):
                continue
            entries.append({'url': url, 'title': text, 'published': status.created_at})
    
    source_name = u"{0} (@{1})".format(name, username) if name else u"@{0}".format(username)
    return FetchResult('twitter', source_name, entries)

# if __name__=='__main__':
#     print fetch_timeline("nateparrott")
