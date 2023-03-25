#!/usr/bin/python3
# Tim H 2023
#
# Takes a webpage URL and downloads the full HTML of the page. Uses a 
# JavaScript engine to render the full page, unlike Lynx.
#
# References:
#   https://www.geeksforgeeks.org/driving-headless-chrome-with-python/

from   time                              import sleep
import sys
import getopt
from   selenium                          import webdriver
from   selenium.webdriver.chrome.options import Options

def main(argv):
    
    # initialize variables with defaults, will be parsed out later
    url_to_render = ''
    html_output_file='default.html'
    screenshot_output_file='default.png'
    
    usage='output-page-html-with-js-rendered.py --url=<url> --html=file.html --screenshot=file.png'
    
    try:
        # extract the command line arguments
        opts, args = getopt.getopt(argv,"hi:o:",["url=","screenshot=","html="])
    except getopt.GetoptError:
        print (usage)
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print (usage)
            sys.exit()
        elif opt in ("--url"):
            # assign the extracted parameter
            url_to_render = arg
        elif opt in ("--screenshot"):
            screenshot_output_file = arg
        elif opt in ("--html"):
            html_output_file = arg

    # print (url_to_render,html_output_file,screenshot_output_file)

    # initialize an empty Options object
    options = Options()
    # make this run in Headless mode, so no GUI pops up
    # GUI slows it down and prevents it from working in command line
    options.add_argument("--headless=new")

    # construct a new instance of headless Chrome
    driver = webdriver.Chrome(options=options)
    driver.set_window_size(3840, 2160)

    # apply the window size change - required.
    # driver.maximize_window()

    # wait 5 seconds for Chrome to initialize
    # not sure if this is responsible for limiting # of videos:
    # sleep(5)

    # have the headless Chrome fetch the specific URL
    driver.get(url_to_render)

    # run all the JavaScript stuff so it finishes rendering the page
    html = driver.execute_script("return document.getElementsByTagName('html')[0].outerHTML")

    # save page's HTML as local file
    pageSource  = driver.page_source
    fileToWrite = open(html_output_file, "w", encoding='utf-8')
    fileToWrite.write(pageSource)
    fileToWrite.close()

    # save local screenshot, if specified (not default)
    if screenshot_output_file != 'default.png':
        driver.save_screenshot(screenshot_output_file)
        driver.get_screenshot_as_png()

    # output the rendered HTML to the screen, will be caught by other
    # Bash function
    # print (html)

    # properly clean up the Chrome instance
    driver.quit()

if __name__ == "__main__":
    main(sys.argv[1:])
