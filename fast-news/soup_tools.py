import bs4

def iterate_tree(soup):
    yield ('enter', soup)
    for child in soup:
        if type(child) == bs4.NavigableString:
            yield ('text', unicode(child.string))
        elif type(child) == bs4.Tag:
            for x in iterate_tree(child):
                yield x
    yield ('exit', soup)

def clone_node(el, soup):
    if isinstance(el, bs4.NavigableString):
        return type(el)(el)

    copy = soup.new_tag(el.name)
    # work around bug where there is no builder set
    # https://bugs.launchpad.net/beautifulsoup/+bug/1307471
    copy.attrs = dict(el.attrs)
    # for attr in ('can_be_empty_element', 'hidden'):
    #     setattr(copy, attr, getattr(el, attr))
    #for child in el.contents:
    #    copy.append(clone(child))
    return copy
