#!/bin/bash
# Tim H 2023

# This script is a ONE TIME set up for using this tool.
# It installs dependencies used by other scripts.
#
# References:
#   https://github.com/yt-dlp/yt-dlp

# try to install for OSX, if not, assume Ubuntu/Debian
brew install yt-dlp lynx || sudo apt-get install yt-dlp lynx

# another dependency for the Python script
pip3 install selenium
