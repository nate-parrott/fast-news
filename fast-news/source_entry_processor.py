import json
from util import url_fetch
from canonical_url import canonical_url
import re

def create_source_entry_processor(url):
    url = canonical_url(url)
    print "SEARCHING FOR SOURCE ENTRY PROCESSOR FOR:", url
    
    if url.startswith('http://www.reddit.com') and url.endswith('.rss'):
        print 'using reddit entry processor'
        json_url = url[:-len('.rss')] + '.json'
        api_resp = json.loads(url_fetch(json_url))
        url_map = {}
        for item_ in api_resp['data']['children']:
            item = item_['data']
            submission_url = 'https://www.reddit.com' + item['permalink']
            actual_url = item['url']
            url_map[submission_url] = actual_url
        print 'url map: {0}'.format(url_map)
        def process_reddit(entry, feed_entry):
            print 'entry url: {0}'.format(entry['url'])
            submission_url = entry.get('url', entry.get('link'))
            if submission_url in url_map:
                print 'MATCHING {0} -> {1}'.format(submission_url, url_map[submission_url])
                entry['url'] = url_map[submission_url]
                entry['submission_url'] = submission_url
        return process_reddit
    
    if url.startswith('http://longform.org/'):
        def longform_override(result_entry, feed_entry):
            if 'content' in feed_entry and len(feed_entry['content']) > 0:
                content = feed_entry['content'][0]['value']
                matches = re.findall(r"\"(.+)\"", content)
                if len(matches):
                    result_entry['url'] = matches[-1]
        return longform_override
    
    if url == 'http://www.designernews.co/?format=atom':
        def dn_override(result_entry, feed_entry):
            if 'summary' in feed_entry: result_entry['url'] = feed_entry['url']
        return dn_override
    
    def process_vanilla(result_entry, feed_entry):
        pass
    
    return process_vanilla
    
