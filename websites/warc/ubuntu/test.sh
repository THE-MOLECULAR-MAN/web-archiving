#!/bin/bash
# Tim H 2023

# restart test


set -e

echo "restarting test."
sudo rm -f /var/log/warcproxyd.log

cd "$HOME/source_code/web-archiving/websites/warc/ubuntu" || exit 234
git pull

./install-warc-ubuntu.sh

sudo systemctl start  warcproxyd.service
sudo systemctl enable warcproxyd.service

cat /var/log/warcproxyd.log

echo "test.sh finished successfully"
