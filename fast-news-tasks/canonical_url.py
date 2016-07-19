
def canonical_url(url):
    # TODO
    if url:
        if url.startswith('https://'):
            url = 'http://' + url[len('https://'):]
        return url.encode('utf-8')
