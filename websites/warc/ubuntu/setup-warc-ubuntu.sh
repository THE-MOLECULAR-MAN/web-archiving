#!/bin/bash
# Tim H 2022
# Bootstrap for installing and configuring WARC proxy in Ubuntu 20.04 server

# This will only install it for the current user
# shellcheck disable=1091
source ./warc-settings-ubuntu.sh

# set up any NFS mounts here for remote storage of WARC files
mkdir "$MOUNT_POINT"

# add the NFS mount
echo "10.0.1.35:/volume1/nfs_archive_mirror_downloads		 $MOUNT_POINT  nfs4     auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
# verify the file was updated:
cat /etc/fstab

# mount it now
sudo mount "$MOUNT_POINT"

cd "$MOUNT_POINT"       || exit 3
cd "$WARC_STORAGE_PATH" || exit 2

# check permissions on remote files
ls -lah "$MOUNT_POINT"

# install dependences, especially for transcoding video files:
sudo apt-get update
sudo apt-get install python3-pip

# reload the $PATH variable since ~/.profile has an if statement that 
# will include the relevant directory
# shellcheck disable=1091
source "$HOME/.profile"

# force PIP update, surprisingly neccessary?
python3 -m pip install -U pip

# install WARC proxy package from pip
pip3 install warcprox

# verify installed and path is working
cd "$WARC_STORAGE_PATH" && warcprox --version
# test running warcprox
# need to change directory before running this command
cd "$WARC_STORAGE_PATH" && warcprox --dir ./recordings/ --address 10.0.1.43 --port 8000 --gzip --rollover-idle-time 86400 --size 250000000 &
# now press enter to get your prompt back
# use the "fg" command and then Ctrl+C to kill the warcprox safely

# assuming it works, now go and setup the service with the start and stop scripts
