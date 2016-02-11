from urlparse import urljoin
from dominant_colors import ui_colors
from bs4 import BeautifulSoup

def extract_brand(markup, url):
    soup = BeautifulSoup(markup, 'lxml')
    favicon = urljoin(url, '/favicon.ico')
    
    def find_link_with_rel(rel):
        link = soup.find('link', attrs={'rel': rel})
        if link and link['href']:
            return urljoin(url, link['href'])
    
    icon = find_link_with_rel('icon')
    shortcut_icon = find_link_with_rel('shortcut icon')
    
    brand = {}
    
    for icon_link in [icon, shortcut_icon, favicon]:
        # print icon_link
        colors = ui_colors(icon_link)
        if colors:
            brand['colors'] = colors
            brand['favicon'] = icon_link
    
    return brand
