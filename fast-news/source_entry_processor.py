import json
from util import url_fetch

def create_source_entry_processor(url):
    print "SEARCHING FOR SOURCE ENTRY PROCESSOR FOR:", url
    
    def process_vanilla(entry):
        pass
    
    if url.startswith('https://www.reddit.com') and url.endswith('.rss'):
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
        def process_reddit(entry):
            print 'entry url: {0}'.format(entry['url'])
            submission_url = entry['url']
            if submission_url in url_map:
                print 'MATCHING {0} -> {1}'.format(submission_url, url_map[submission_url])
                entry['url'] = url_map[submission_url]
                entry['submission_url'] = submission_url
        return process_reddit
        
    
    def process_vanilla(entry):
        pass
    return process_vanilla
    
