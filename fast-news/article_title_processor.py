from shared_suffix import shared_suffix

def article_title_processor(articles):
    # takes article JSON, removes redundant suffixes
    
    good_titles = [a.get('title') for a in articles if a.get('fetch_failed') == False]
    suffix_to_strip = shared_suffix(good_titles) if len(good_titles) >= 2 else None
    
    def process(article):
        title = article.get('title') or ""
        if suffix_to_strip and len(title) > len(suffix_to_strip) and title[-len(suffix_to_strip):] == suffix_to_strip:
            title = title[:-len(suffix_to_strip)]
        title = title.split(u" | ")[0]
        article['title'] = title.strip()
        return article
    
    return map(process, articles)

if __name__ == '__main__':
    articles = [
        {
            "title": "wow - VICE",
            "fetch_failed": False
        },
        {
            "title": "this is cool - VICE",
            "fetch_failed": False
        },
        {
            "title": "this doesnt count",
            "fetch_failed": None
        },
        {
            "title": "but this | Author - VICE",
            "fetch_failed": False
        }
    ]
    articles = article_title_processor(articles)
    assert articles[0]['title'] == 'wow'
    assert articles[1]['title'] == 'this is cool'
    assert articles[2]['title'] == 'this doesnt count'
    assert articles[3]['title'] == 'but this'
    
