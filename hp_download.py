#!/usr/bin/env python3
# --------------
# Load modules
# --------------
from bs4 import BeautifulSoup
from collections import defaultdict
from random import choice
from time import sleep
import urllib.request
import csv
import logging


# --------------------------------
# Scraping and parsing functions
# --------------------------------
def get_url(url):
    user_agents = [
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25',
      'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36',
      'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:32.0) Gecko/20100101 Firefox/32.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.1.17 (KHTML, like Gecko) Version/7.1 Safari/537.85.10',
      'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.104 Safari/537.36',
      'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36'
    ]

    agent = choice(user_agents)
    wait = choice(range(10, 17))

    response = urllib.request.Request(url, headers={'User-Agent': agent})
    handler = urllib.request.urlopen(response).read()

    sleep(wait)

    return(handler)


def parse_chapter(url):
    print("Parsing {0}".format(url))

    try:
        soup = BeautifulSoup(get_url(url))
    except:
        logging.warning("Error with {0}".format(url))
        print("Error. Moving on.")
        return(None)

    content_section = soup.select('.ContentCss')
    content_clean = [x.text.replace('\u3000', '') for x in content_section][0]

    content = {}
    content['content'] = content_clean.split('\n')
    content['url'] = url

    split_url = url.split('/')[-1].replace('.html', '').split('_')
    content['book'] = ' '.join(split_url[0:-1])
    content['chapter'] = split_url[-1]

    return(content)


def convert_to_long(chapter):
    long_results = defaultdict(dict)
    entry_num = -1

    for x in chapter['content']:
        entry_num += 1
        long_results[entry_num]['book'] = chapter['book']
        long_results[entry_num]['chapter'] = chapter['chapter']
        long_results[entry_num]['paragraph'] = entry_num + 1
        long_results[entry_num]['text'] = x

    return(long_results)


# --------------------------------
# Build a list of URLs to scrape
# --------------------------------
url_base = 'http://www.readfreeonline.net/OnlineBooks/'
specific_books = ['Harry_Potter_and_the_Sorcerers_Stone/Harry_Potter_and_the_Sorcerers_Stone_CHAPTER.html',
    'Harry_Potter_and_The_Chamber_Of_Secrets/Harry_Potter_and_The_Chamber_Of_Secrets_CHAPTER.html',
    'Harry_Potter_and_the_Prisoner_of_Azkaban/Harry_Potter_and_the_Prisoner_of_Azkaban_CHAPTER.html',
    'Harry_Potter_and_the_Goblet_of_Fire/Harry_Potter_and_the_Goblet_of_Fire_CHAPTER.html',
    'Harry_Potter_and_the_Order_of_the_Phoenix/Harry_Potter_and_the_Order_of_the_Phoenix_CHAPTER.html',
    'Harry_Potter_and_the_Half-Blood_Prince/Harry_Potter_and_the_Half-Blood_Prince_CHAPTER.html',
    'Harry_Potter_and_the_Deathly_Hallows/Harry_Potter_and_the_Deathly_Hallows_CHAPTER.html']

chapters = [17, 19, 22, 37, 38, 30, 37]

urls_to_parse = []

for i in range(0, len(specific_books)):
    for j in range(1, chapters[i]+1):
        final_url = url_base + specific_books[i].replace('CHAPTER', str(j))
        urls_to_parse.append(final_url)

print(urls_to_parse.index('http://www.readfreeonline.net/OnlineBooks/Harry_Potter_and_the_Prisoner_of_Azkaban/Harry_Potter_and_the_Prisoner_of_Azkaban_20.html'))

# ---------------------------------------
# Scrape all those URLs and save to CSV
# ---------------------------------------
# # Set up log
# logging.basicConfig(filename='errors.log', filemode='w', level=logging.DEBUG,
#                     format='%(levelname)s %(asctime)s: %(message)s')
# logging.captureWarnings(True)

# csv_started = False
# fieldnames = ['book', 'chapter', 'paragraph', 'text']

# for url in urls_to_parse[0:2]:
#     contents = convert_to_long(parse_chapter(url))

#     for key, value in contents.items():
#         w = csv.DictWriter(open('hp.csv', 'a'), fieldnames)
#         if csv_started is False:
#             w.writeheader()
#             csv_started = True
#         w.writerow(value)
