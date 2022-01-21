#!/bin/bash
# Tim H 2021
# Installs and sets up a tool on the local system for archiving Reddit
# Designed for OS X & Linux
#
#   Notes:
#       On OS X: python --version is Python 2.7.17
#                   python3 --version is Python 3.8.8
#                   pip --version   (python 3.9
#                   pip3 --version  python 3.8
#   References
#       * https://shadowmoose.github.io/RedditDownloader/Getting_Started/Sources/
#       * https://github.com/shadowmoose/RedditDownloader
#       * List of friends on Reddit: https://ssl.reddit.com/prefs/friends

################################################################################
#		MAIN PROGRAM
################################################################################

# bomb out in case of errors
set -e

# move into directory where installer will be downloaded
cd "$HOME/g_drive/bin/" || exit 2

# Download it, name it something version agnostic to make it more future proof
# You should visit https://github.com/shadowmoose/RedditDownloader and verify you've got the latest version
wget -O RedditDownloader.tar.gz -q "https://github.com/shadowmoose/RedditDownloader/archive/3.1.5.tar.gz"

# extract it
tar -xzf RedditDownloader.tar.gz

# change directory into the newly extracted one, surprisingly this * trick works
cd RedditDownloader-* || exit 1

# install it using pip3
pip3 install -r requirements.txt

# start a screen session, do not put " " around the python or run command, it won't work.
screen -m python3 Run.py

# it will automatically open this page: http://localhost:7505/index.html#Settings
