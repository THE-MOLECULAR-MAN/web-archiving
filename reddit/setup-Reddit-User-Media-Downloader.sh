#!/bin/bash
# Tim H 2021
# Installs Reddit-User-Media-Downloader on the local system for archiving
# an individual user's Reddit posts/comments. It seems to only download
# images and videos, not text posts?
#
# Designed for OS X
#
#   References
#       https://github.com/MonkeyMaster64/Reddit-User-Media-Downloader-Public

################################################################################
#		MAIN PROGRAM
################################################################################

# bomb out in case of errors
set -e

# move into directory where installer will be downloaded
cd "$HOME/g_drive/bin/" || exit 2

python3 -m pip install --upgrade pip

git clone --recursive https://github.com/MonkeyMaster64/Reddit-User-Media-Downloader-Public.git
python3 -m venv ~/envs/Reddit-User-Media-Downloader-Public
source "~/envs/Reddit-User-Media-Downloader-Public/bin/activate"
cd ./Reddit-User-Media-Downloader-Public/

# Following their instructions for Linux install causes issues, so I've
# modified those instructions to fix dependency issues
# Prob easier to just use the Docker container but not everyone knows how
# to do that.

# pip3 install -r requirements.txt
pip3 install imagededup
pip3 install youtube_dl
pip3 install cython
pip3 install requests

# the problematic one
#pip3 install opencv-python==4.5.2
pip3 install opencv-python

# example usage - download last 2 posts by reddit admin sodypop
python3 reddit-media-downloader.py --user sodypop --limit 2
