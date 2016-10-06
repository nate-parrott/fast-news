
blacklist = set([
    "story continued below",
    "continued below",
    "by",
    "AP Photo"
])

def should_remove(text):
    text = text.strip().lower()
    return len(text) == 0 or text in blacklist
