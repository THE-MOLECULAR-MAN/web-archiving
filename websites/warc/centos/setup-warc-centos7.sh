#!/bin/bash
# Tim H 2021
# Bootstrap for installing and configuring WARC proxy in CentOS 7

# setting up Webrecorder player GUI app for OS X, for viewing the WARC files
#brew install webrecorder-player

# install dependences, especially for transcoding video files:
yum install -y libffi libffi-devel python3-pip

# force PIP update, surprisingly neccessary?
python3 -m pip install -U pip

# install WARC proxy package from pip
pip3 install warcprox

# Optional: make a mount point on an NFS share so that the WARC files are not stored inside the VM
#   and can be easily accessed for your laptop:
# mount point one time setup to modify the /etc/fstab file. You'll still have to manually mount that point
# make sure the /opt/warcproxy/warcs directory is EMPTY when you do this:
# echo "10.0.1.35:/volume1/nfs_archive_mirror_downloads/web_archiving/websites_via_wayback_warc /opt/warcproxy/warcs      nfs auto,nofail,noexec,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab
# mount it manually the first time. It should mount successfully on reboots.
# mount /opt/warcproxy/warcs

# basic test, launches on port 8000 by default if not specified
# cd /opt/warcproxy/ || exit 1
# warcprox --address 0.0.0.0
# !!!!! Press Ctrl+C to cleanly end the session and flush everything out to the WARC file. !!!!!
# The WARC file will be corrupted if you don't do this

# set up the warc proxy to start on boot

# define a new service for WARC
# suuuppper hacky with the sleep, I know! It doesn't seem to want to wait for the openvpn client to finish launching


echo "@reboot /root/warc-proxy-start.sh" | crontab -

# sudo bash -c "cat > /etc/systemd/system/warcd.service" <<EOF
# [Unit]
# Description=WARC Proxy for web archiving
# After=openvpn@server.service

# [Service]
# Type=simple
# ExecStart=/root/warc-proxy-start.sh
# ExecStop=/root/warc-proxy-stop.sh

# TimeoutStartSec=0

# [Install]
# WantedBy=default.target

# EOF

# cat /etc/systemd/system/warcd.service

# # reload list of services
# systemctl daemon-reload

# # check status of the OpenVPN client (for killswitch)
# systemctl status openvpn@server.service


# systemctl status warcd.service

# # set the new service to autostart on boot
# systemctl enable warcd.service

# restart to test it
reboot now


#systemctl status warcd.service
# Use another script to launch it safely

#./warc-proxy-start.sh

# If you're going to use InsightAppSec or AppSpider pro through this WARC proxy:
# Steps to take on InsightAppSec scan engine or AppSpider Pro instance:
# Enable JavaScript in Internet Options for Internet Zone
# Create webscantest config and disable reporting
#   turn down simultaneous connections to 1
#   enable proxy for warc's IP on port 8000 for both HTTP and HTTPS
