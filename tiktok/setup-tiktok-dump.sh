#!/bin/bash
# Tim H 2023

# This script is a ONE TIME set up for using this tool.
# It installs dependencies used by other scripts in Ubuntu 20.04
#
# References:
#   https://github.com/yt-dlp/yt-dlp

# try to install for OSX
# brew install yt-dlp lynx

# load in case this is a cron, need the $PATH variable to include
# the $HOME/.local/bin
# shellcheck disable=1091
source "$HOME/.bash_profile"

# another dependency for the Python script
# must use pip version to get latest of yt-dlp, not Ubuntu's apt - too old
pip3 install selenium brotli yt-dlp

# need to be 2023.03.04 or later
yt-dlp --version

# Ubuntu apt dependencies
sudo apt-get update
sudo apt-get remove brotli yt-dlp
sudo apt-get install lynx unzip xvfb libxi6 libgconf-2-4

# Ubuntu - chromedriver
# https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/
cd "$HOME" || exit 1
sudo curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add 
sudo bash -c "echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list.d/google-chrome.list" 
sudo apt-get -y update
sudo apt-get -y install google-chrome-stable 
google-chrome --version

# https://chromedriver.chromium.org/downloads
wget https://chromedriver.storage.googleapis.com/111.0.5563.64/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
sudo mv chromedriver /usr/bin/chromedriver
sudo chown root:root /usr/bin/chromedriver 
sudo chmod +x /usr/bin/chromedriver 
chromedriver --version
