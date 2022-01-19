#!/bin/bash
# Tim H 2021
# Extracts game URLs from downloaded HTML file
# useful for handing off to the archive-jackbox.sh script in a text file
# Recommended usage:
#   1) open jackbox.tv on your phone's browser (or wherever you played)
#   2) click the hamburger icon in the top left and select Past Games
#   3) save the page as HTML file and process it using this script

# installs the pre-requisite on OS X using Homebrew
brew install lynx

# extract all the game instance ("artifact") URLs, de-duplicate them, output to screen
lynx -dump -listonly "$1" | grep artifact |  tr -s ' ' | cut -d ' ' -f3 | sort --unique
