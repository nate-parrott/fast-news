import re
# currently unused

def fuzzy_match_score(s1, s2):
    def _split(s):
        tokens = ["$START"] + re.split(r"\s+", s.strip().lower()) + ["$END"]
        return set(zip(tokens[:-1], tokens[1:]))
    set1 = _split(s1)
    set2 = _split(s2)
    union = set(list(set1) + list(set2))
    intersection = [x for x in set1 if x in set2]
    # print union
    # print intersection
    print len(intersection), len(union)
    return len(intersection) * 1.0 / len(union)        

def fuzzy_match(s1, s2):
    return fuzzy_match_score(s1, s2) >= 0.6

if __name__ == '__main__':
    #assert fuzzy_match("hello world", "HELLO WORLD")
    #assert not fuzzy_match("hello world", "goodbye world")
    #assert fuzzy_match("one two three four five six seven eight", "one two three four five six seven eightttt")
    assert fuzzy_match("Understanding git for real by exploring the .git directory", u"Understanding git for real by exploring the\u00a0.git directory")
    