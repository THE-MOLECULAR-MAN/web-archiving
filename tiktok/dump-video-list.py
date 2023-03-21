#!/opt/homebrew/bin/python3.10
# Tim H 2023
#
# Takes a TikTok profile URL and downloads the full HTML of the page, including
# multiple video links. Uses a JavaScript engine to render the full page,
# unlike Lynx.
#
# example usage. Takes a PROFILE URL, not an individual video page.
#   ./dump-video-list.py https://www.tiktok.com/@shaq
#
# References:
#   https://www.geeksforgeeks.org/driving-headless-chrome-with-python/

from   time                              import sleep
import sys
import getopt
from   selenium                          import webdriver
from   selenium.webdriver.chrome.options import Options


def main(argv):
    # initialize empty variable, will be parsed out later
    tiktok_profile_url = ''
    try:
        # extract the command line argument
        opts, args = getopt.getopt(argv,"hi:o:",["url="])
    except getopt.GetoptError:
        print ('dump-video-list.py --url <url>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('dump-video-list.py --url=<url>')
            sys.exit()
        elif opt in ("-u", "--url"):
            # assign the extracted parameter
            tiktok_profile_url = arg

    # initialize an empty Options object
    options = Options()
    # make this run in Headless mode, so no GUI pops up
    # GUI slows it down and prevents it from working in command line
    options.add_argument("--headless=new")

    # construct a new instance of headless Chrome
    driver = webdriver.Chrome(options=options)

    # wait 5 seconds for Chrome to initialize
    sleep(5)

    # have the headless Chrome fetch the specific URL (TikTok profile page)
    driver.get(tiktok_profile_url)

    # run all the JavaScript stuff so it finishes rendering the page
    html = driver.execute_script("return document.getElementsByTagName('html')[0].outerHTML")

    # output the rendered HTML to the screen, will be caught by other
    # Bash function
    print (html)

    # properly clean up the Chrome instance
    driver.quit()

if __name__ == "__main__":
    main(sys.argv[1:])
