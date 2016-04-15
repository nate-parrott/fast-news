from google.appengine.datastore.datastore_query import Cursor
from model import Article

def stats():
    article_count = Article.query(Article.content != None).count()
    return {
        "article_count": article_count
    }

def dump_items(cursor=None):
    q = Article.query().order(Article._key)
    count = 100
    if cursor:
        articles, next_cursor, has_more = q.fetch_page(count, start_cursor=Cursor(urlsafe=cursor))
    else:
        articles, next_cursor, has_more = q.fetch_page(count)
    return {
        "articles": [article.json(include_article_json=True) for article in articles if article.content != None],
        "cursor": next_cursor.urlsafe() if next_cursor else None,
        "has_more": has_more
    }
