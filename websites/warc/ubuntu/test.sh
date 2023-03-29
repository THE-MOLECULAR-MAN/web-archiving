#!/bin/bash
# Tim H 2023

# restart test


set -e

echo "restarting test."
sudo truncate -s 0 /var/log/warcproxyd.log

sudo systemctl --no-pager stop warcproxyd.service
sudo pkill -f "warc"

cd "$HOME/source_code/web-archiving/websites/warc/ubuntu" || exit 234
git pull

./install-warc-ubuntu.sh

echo "starting the service..."
sudo systemctl --no-pager start  warcproxyd.service

echo "checking the service status..."
sudo systemctl --no-pager status warcproxyd.service

echo "looking for running processes"
pgrep warc

echo "enabling the service to autostart on future reboot"
sudo systemctl --no-pager enable warcproxyd.service

cat /var/log/warcproxyd.log

echo "test.sh finished successfully"
