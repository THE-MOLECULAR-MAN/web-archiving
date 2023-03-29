#!/bin/bash
# Tim H 2023

# restart test


set -e

echo "test.sh: restarting test."
sudo truncate -s 0 /var/log/warcproxyd.log

sudo systemctl --no-pager stop warcproxyd.service
sudo pkill -f "warc"
sudo rm -f /run/warcproxyd.pid

cd "$HOME/source_code/web-archiving/websites/warc/ubuntu" || exit 234
git pull

./install-warc-ubuntu.sh

echo "test.sh: starting the service..."
sudo systemctl --no-pager start  warcproxyd.service

echo "test.sh: checking the service status..."
sudo systemctl --no-pager status warcproxyd.service

echo "test.sh: pgrep of warc related processes:"
pgrep warc

echo "test.sh: enabling the service to autostart on future reboot"
sudo systemctl --no-pager enable warcproxyd.service

echo "-----------------------------------------------------------------------"
echo "-------------------------- LOG FILE CONTENTS START --------------------"
echo "-----------------------------------------------------------------------"

cat /var/log/warcproxyd.log

echo "test.sh finished successfully"
