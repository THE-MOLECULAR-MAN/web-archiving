#!/bin/bash
# Tim H 2021
# Installs and sets up for reddit-html-archiver archiving Reddit
# This tool can only download whole subreddits between given dates
# This tool cannot download by user
#
# Designed for OS X
#
#   Notes:
#       On OS X: python --version is Python 2.7.17
#                   python3 --version is Python 3.8.8
#                   pip --version   (python 3.9
#                   pip3 --version  python 3.8
#   References
#       * https://github.com/libertysoft3/reddit-html-archiver
#

################################################################################
#		MAIN PROGRAM
################################################################################

# bomb out in case of errors
set -e

# install the Python module for interacting with the Reddit API
pip install psaw -U

# change directory into place where new tool will be downloaded
cd "$HOME/g_drive/bin/" || exit 2

# download and install a dependency
# snudown is just a library, cannot be run directly
git clone https://github.com/chid/snudown
cd snudown || exit 2
python3 setup.py install

# download the real tool, reddit-html-archiver
cd .. || exit 3
git clone https://github.com/libertysoft3/reddit-html-archiver
cd reddit-html-archiver || exit 4
chmod u+x ./*.py

# Test to make sure it can run, just dump the help command
python3 ./fetch_links.py -h
