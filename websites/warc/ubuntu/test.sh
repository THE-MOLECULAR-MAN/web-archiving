#!/bin/bash
# Tim H 2023

# restart test


set -e

echo "[test.sh] Restarting test."
sudo truncate -s 0 /var/log/warcproxyd.log

sudo systemctl --no-pager stop warcproxyd.service
sudo pkill -f "warc"
sudo rm -f /run/warcproxyd.pid

cd "$HOME/source_code/web-archiving/websites/warc/ubuntu" || exit 234
git pull

./install-warc-ubuntu.sh

echo "[test.sh] Starting the service..."
sudo systemctl --no-pager start  warcproxyd.service

echo "[test.sh] Checking the service status..."
sudo systemctl --no-pager status warcproxyd.service

echo "[test.sh] pgrep of warc related processes:"
pgrep warc

echo "[test.sh] enabling the service to autostart on future reboot"
sudo systemctl --no-pager enable warcproxyd.service

echo "[test.sh] Finished successfully, tailing log now"
echo "-----------------------------------------------------------------------"
echo "-------------------------- LOG FILE CONTENTS START --------------------"
echo "-----------------------------------------------------------------------"

tail -f /var/log/warcproxyd.log
