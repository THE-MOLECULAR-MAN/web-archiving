#!/bin/bash
# Tim H 2022
#
# This script is designed to install and do basic configuration of the
#   tool Podgrab from GitHub - designed to automatically download audio
#   files from podcast RSS feeds.
# This script is designed to be run AFTER centos7-cron-runner-setup.sh
#
# This script will install PodGrab onto the NFS mount so it's database
#   and all MP3 files are backed up outside of the virtual machine.
#
#   TODO: migrate these local variables into a sourcable ENV file controlled
#       by a single script

# using the same variables as centos7-cron-runner-setup.sh
NEW_LOCAL_USERNAME="cron-user"
NFS_MOUNT_NAME="nfs_archive_mirror_downloads"
NFS_MOUNT_PATH="/home/$NEW_LOCAL_USERNAME/$NFS_MOUNT_NAME"

##############################################################################
#   Podcast download set up
##############################################################################
# this is designed to be run as the new user (cron-user), NOT as root.

# install FFMPEG on CentOS 7 - used for reading MP3 metadata
sudo yum install -y ffmpeg ffmpeg-devel
ffmpeg -version

# setup dependencies for podgrab:
sudo yum install -y git ca-certificates gcc golang

# prep directories for podcast downloading tool
cd "$NFS_MOUNT_PATH" || exit 2
mkdir "$NFS_MOUNT_PATH/podcasts"
cd "$NFS_MOUNT_PATH/podcasts" || exit 3

# download source, compile into binaries for podcast downloading tool named podgrab
git clone --depth 1 https://github.com/akhilrex/podgrab
cd podgrab || exit 5
mkdir -p ./dist
cp -r client ./dist
cp -r webassets ./dist
cp .env ./dist
go build -o ./dist/podgrab ./main.go

# test the install
cd "$NFS_MOUNT_PATH/podcasts/podgrab/dist/" || exit 4
# there's no --help or --version for ./podgrab so no way to test it

# disable the firewall
# TODO: add exception instead
sudo service firewalld stop

# set up the config file for podgrab
# it will listen on ALL network interfaces by default on TCP 8080
# having it check for updates every 90 minutes
echo "CONFIG=.
DATA=./assets
CHECK_FREQUENCY = 90
PORT=8080
PASSWORD=" > "$NFS_MOUNT_PATH/podcasts/podgrab/dist/.env"

# Service/daemon definition
echo "[Unit]
Description=Podgrab

[Service]
ExecStart=$NFS_MOUNT_PATH/podcasts/podgrab/dist/podgrab
WorkingDirectory=$NFS_MOUNT_PATH/podcasts/podgrab/dist/
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/podgrab.service

# reload the definitions of all the daemons, pick up the new one.
sudo systemctl daemon-reload

# set it to autostart on reboot
sudo systemctl enable podgrab.service

# start it now
sudo systemctl start  podgrab.service

# check the status of it, make sure it is running
sudo systemctl status podgrab.service

# now you can visit http://THIS_LAN_IP:8080/ from your browser and configure the tool
# note the HTTP and not HTTPS
