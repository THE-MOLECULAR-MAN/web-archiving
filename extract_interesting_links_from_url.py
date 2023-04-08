#!/usr/bin/python3
"""docstring"""
# Tim H 2023
#
# Visits a webpage and scrolls down until it stops giving new interesting links
# Outputs that list of interesting links to a text file. Useful for SPAs like
# Pinterest where a single snapshot of the DOM doesn't list all of the
# urls
#
# References:
#   https://www.geeksforgeeks.org/driving-headless-chrome-with-python/


from time import sleep
import sys
import getopt
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import numpy as np

WAIT_FOR_PAGE_TO_LOAD_TIME_IN_SEC = 3


def extract_unique_and_interesting_urls(var_driver, interesting_url_pattern_var, unique_links_output_file, max_scroll_down_count_var):
    """docstring"""

    # interesting_url_pattern='https://www.tiktok.com/@shaq/video/'

    # Initialize for first loop
    new_links_found = True

    # initialize an empty list of interesting URLs
    unique_interesting_urls_list = []

    # initialize loop counter to zero
    loop_counter = 0

    # do the scrolling in here, only add new URLs if they aren't
    # already in the list
    while loop_counter <= max_scroll_down_count_var and new_links_found:

        # assume no new links have been found if on second iteration or later
        if loop_counter >= 1:
            new_links_found = False

        # gather the list of all hyperlinks in the current DOM
        lnks=var_driver.find_elements(By.TAG_NAME, 'a')

        if len(lnks) > 0:
            # iterate through list of found hrefs
            for iter_href_elem in lnks:
                # extract just the href's URL as string, not object
                iter_url = iter_href_elem.get_attribute('href')

                # if the href isn't empty
                if iter_url is not None:

                    # If the URL is considered interesting:
                    if iter_url.startswith(interesting_url_pattern_var):

                        # if it is new and hasn't been seen before:
                        if iter_url not in unique_interesting_urls_list:
                            # add it to the list
                            unique_interesting_urls_list.append(iter_url)
                            new_links_found=True

        print('Scrolling down...')
        var_driver.execute_script("window.scrollTo(0,document.body.scrollHeight)")
        sleep(WAIT_FOR_PAGE_TO_LOAD_TIME_IN_SEC)
        loop_counter += 1

    print("Total number of interesting URLs (non-unique): ", len(unique_interesting_urls_list))
    print("Total number of interesting and unique URLs  : ", len(np.unique(unique_interesting_urls_list)))

    print("Writing unique and interesting URLs to output file...")
    with open(unique_links_output_file, "w", encoding='utf-8') as file_to_write:
        file_to_write.write("\n".join(np.unique(unique_interesting_urls_list)))


def main(argv):
    """docstring"""

    # initialize variables with defaults, will be parsed out later
    url_to_render = ''
    # html_output_file = 'default.html'
    # screenshot_output_file = 'default.png'
    max_scroll_count = 0


    usage = ('extract-interesting-links-from-url.py --url=<url> '
             '--max_scroll_count=<int> '
             '--interesting_url_pattern=<url> '
             '--output_file=<filename>')

    try:
        # extract the command line arguments
        opts, args = getopt.getopt(argv, "hi:o:",
                                   ["url=", "interesting_url_pattern=", "max_scroll_count=",
                                    "output_file="])
    except getopt.GetoptError:
        print(usage)
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print(usage)
            sys.exit()
        elif opt in ("--url"):
            # assign the extracted parameter
            url_to_render = arg
        elif opt in ("--max_scroll_count"):
            max_scroll_count = int(arg)
        elif opt in ("--interesting_url_pattern"):
            interesting_url_pattern = arg
        elif opt in ("--output_file"):
            output_file = arg

    # initialize an empty Options object
    options = Options()
    # make this run in Headless mode, so no GUI pops up
    # GUI slows it down and prevents it from working in command line
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1920,1200")

    # construct a new instance of headless Chrome
    print("Initializing browser...")
    driver = webdriver.Chrome(options=options)

    # have the headless Chrome fetch the specific URL
    print("Fetching URL: ", url_to_render)
    driver.get(url_to_render)
    print("Finished fetching URL, now sleeping...")
    # wait for page to finish loading
    sleep(WAIT_FOR_PAGE_TO_LOAD_TIME_IN_SEC)
    print("Finished sleeping.")

    # print("counting links in HTML/DOM")
    extract_unique_and_interesting_urls(driver, interesting_url_pattern, output_file, max_scroll_count)

    # save page's HTML as local file
    #page_source = driver.page_source
    #with open(html_output_file, "w", encoding='utf-8') as file_to_write:
    #    print("Writing HTML file: ", html_output_file)
    #    file_to_write.write(page_source)

    # save local screenshot, if specified (not default)
    #if screenshot_output_file != 'default.png':
    #    print("Saving screenshot: ", screenshot_output_file)
    #    driver.save_screenshot(screenshot_output_file)
    #    driver.get_screenshot_as_png()

    # properly clean up the Chrome instance
    print("Shutting down Chrome...")
    driver.quit()


if __name__ == "__main__":
    main(sys.argv[1:])
    print("Python script finished successfully.")
