import re

def tokens(text):    
    tokens = set()
    if text:
        text = re.sub(r"[\.\,\'\"\:\!\?]", " ", text)
        tokens = set(re.split(r"\s+", text))
    return tokens

def expand_tokens(tokens, max_tokens):
    tokens = set(tokens)
    if len(tokens) == 0: return tokens
    max_token_len = max(map(len, tokens))
    for cut in xrange(1, max_token_len):
        new_tokens = set()
        for token in tokens:
            if len(token) > cut:
                new_tokens.add(token[:-cut])
        if len(new_tokens) == 0:
            return tokens
        for t in new_tokens:
            if len(tokens) >= max_tokens:
                return tokens
            else:
                tokens.add(t)  
    return tokens

def add_to_index(url, text):
    index_text = u" ".join(expand_tokens(tokenize(text), 600))
    # TODO

def search_sources(query):
    pass

if __name__ == '__main__':
    print expand_tokens(tokens('im nate'), 500)
