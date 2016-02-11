from flask import Flask, request, jsonify
app = Flask(__name__)
import newspaper
import sys
from bs4 import BeautifulSoup

@app.route("/")
def hello():
    return """
    <form method=GET action=parse>
        <h1>test parse</h1>
        <input type=url name=url placeholder=URL />
    </form>
    """

def find_meta_value(soup, prop):
    tag = soup.find('meta', attrs={'property': prop})
    if tag:
        return tag['content']

def first_present(items):
    for item in items:
        if item:
            return item

@app.route('/parse')
def parse():
    url = request.args['url']
    article = newspaper.Article(url, keep_article_html=True, request_timeout=4, fetch_images=False)
    print('article')
    article.download()
    soup = BeautifulSoup(article.html, 'lxml')
    
    og_title = find_meta_value(soup, 'og:title')
    og_image = find_meta_value(soup, 'og:image')
    og_description = find_meta_value(soup, 'og:description')
    
    print('download')
    article.parse()
    print('parse')
    d = {
        "title": first_present([og_title, article.title]),
        "top_image": first_present([article.top_image, og_image]),
        "authors": article.authors,
        "html": article.html,
        "article_html": article.article_html,
        "article_text": article.text,
        "description": og_description,
        "images": list(article.images)
    }
    print('d')
    return jsonify(**d)

if __name__ == "__main__":
    # app.run(debug = 'debug' in sys.argv)
    app.run(debug=True)
