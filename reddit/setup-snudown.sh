#!/bin/bash
# Tim H 2021
# Installs and sets up tools for archiving Reddit
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

#  !NON-EXECUTABLE!
echo "this script should not be run directly. It is either notes or in progress. Exiting"
exit 1

################################################################################
#		MAIN PROGRAM
################################################################################
pip install psaw -U

cd "/Volumes/GoogleDrive/My Drive/source_code" || exit 2

git clone https://github.com/chid/snudown
cd snudown || exit 2
sudo python3 setup.py install
cd .. || exit 3
git clone https://github.com/libertysoft3/reddit-html-archiver
cd reddit-html-archiver || exit 4
chmod u+x ./*.py

# Test
python3 ./fetch_links.py -h
