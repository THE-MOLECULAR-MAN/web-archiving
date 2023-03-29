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

# configuring certs
sudo apt-get install -y ca-certificates
cd /home/thrawn/nfs_warc/web_archiving/websites_via_wayback_warc || exit 2347

# service must have been started at least once for this to work
# CA needs to exist:
openssl x509 -in  pia-vpn-proxy.int.butters.me-warcprox-ca.pem -text -certopt no_header,no_pubkey,no_subject,no_issuer,no_signame,no_version,no_serial,no_validity,no_extensions,no_sigdump,no_aux,no_extensions > pia-vpn-proxy.int.butters.me-warcprox-ca.crt
sudo cp pia-vpn-proxy.int.butters.me-warcprox-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

echo "[test.sh] enabling the service to autostart on future reboot"
sudo systemctl --no-pager enable warcproxyd.service

echo "[test.sh] Finished successfully, tailing log now"
echo "-----------------------------------------------------------------------"
echo "-------------------------- LOG FILE CONTENTS START --------------------"
echo "-----------------------------------------------------------------------"

tail -f /var/log/warcproxyd.log

# nmap -p8000 pia-vpn-proxy.int.butters.me
