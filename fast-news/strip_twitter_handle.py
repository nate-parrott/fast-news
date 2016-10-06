import re
def strip_twitter_handle_from_title(title):
    # when we scrape a twitter page, we get a title that looks like "Publication Name (@handle)"
    # let's get rid of the handle
    return re.sub(r"\s\(@[a-zA-Z0-9_]+\)$", "", title)

if __name__ == '__main__':
    assert strip_twitter_handle_from_title('Bloomberg News (@business)') == 'Bloomberg News'
    assert strip_twitter_handle_from_title('(@hey) there') == '(@hey) there'
    assert strip_twitter_handle_from_title('nate@gmail.com') == 'nate@gmail.com'
