#!/bin/bash
# Tim H 2022
# Bootstrap for installing and configuring WARC proxy in Ubuntu 20.04 server

# exit if any errors
set -e

is_mounted() {
    mount | awk -v DIR="$1" '{if ($3 == DIR) { exit 0}} ENDFILE{exit -1}'
}

# This will only install it for the current user
# shellcheck disable=1091
source ./warc-settings-ubuntu.sh

# set up any NFS mounts here for remote storage of WARC files
mkdir -p "$MOUNT_POINT"

# set permissions
sudo chown "$USER" "$MOUNT_POINT"
sudo chmod 744     "$MOUNT_POINT"

# add the NFS mount
if grep -Fxq "$MOUNT_POINT" /etc/fstab; then
    echo "adding mount point to /etc/fstab"
    echo "10.0.1.35:/volume1/nfs_archive_mirror_downloads		 $MOUNT_POINT  nfs4     auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
else
    echo "mount point already added to /etc/fstab"
fi

# mount it if not mounted already
if is_mounted "$MOUNT_POINT"; then
    echo "$MOUNT_POINT already mounted"
else
    echo "$MOUNT_POINT wasn't mounted, mounting now"
    sudo mount "$MOUNT_POINT"
    echo "finished mounting $MOUNT_POINT"
fi

# check permissions on directories
cd "$MOUNT_POINT"       || exit 3
cd "$WARC_STORAGE_PATH" || exit 2

# check permissions on remote files
ls -lah "$MOUNT_POINT"

# install dependences, especially for transcoding video files:
sudo apt-get update
sudo apt-get -qq -y install python3-pip

# reload the $PATH variable since ~/.profile has an if statement that 
# will include the relevant directory
# shellcheck disable=1091
source "$HOME/.profile"

# force PIP update, surprisingly neccessary?
python3 -m pip install --quiet -U pip
sudo python3 -m pip install --quiet -U pip

# install WARC proxy package from pip
pip3 install --quiet warcprox

# verify installed and path is working
cd "$WARC_STORAGE_PATH" && warcprox --version
# test running warcprox
# need to change directory before running this command
# cd "$WARC_STORAGE_PATH" && warcprox --dir ./recordings/ --address 10.0.1.43 --port 8000 --gzip --rollover-idle-time 86400 --size 250000000 &
# now press enter to get your prompt back
# use the "fg" command and then Ctrl+C to kill the warcprox safely

# assuming it works, now go and setup the service with the start and stop scripts

# manual test from remote system:
# curl --proxy "http://10.0.1.43:8000" "http://captive.apple.com"


# https://www.shellhacks.com/systemd-service-file-example/

# Gotcha: don't put executable files like the start/stop scripts on an NFS
# mount that is marked as noexec

# shellcheck disable=1091
# source ./warc-settings-ubuntu.sh

# set up repo
mkdir -p "$CURRENT_USER_HOME/source_code"
cd "$CURRENT_USER_HOME/source_code" || exit 99
set +e
git clone https://github.com/THE-MOLECULAR-MAN/web-archiving.git
set -e
cd "$LOCAL_REPO_WARC_PATH" || exit 25

# create the service definition file
echo "[Unit]
 Description=WARC Proxy
 After=piavpn.service

[Service]
 ExecStart=$LOCAL_REPO_WARC_PATH/warc-proxy-start-ubuntu.sh
 ExecStop=$LOCAL_REPO_WARC_PATH/warc-proxy-stop-ubuntu.sh
 PIDFile=$WARC_PID_FILE_PATH
" | sudo tee "$SERVICE_FILE_PATH"

# change the permissions on the new file
sudo chmod 664 "$SERVICE_FILE_PATH"

# mark the scripts as executable so the start/stop work
cd "$LOCAL_REPO_WARC_PATH" || exit 3
# not doing it in one step b/c of ShellCheck Lint recommendations
sudo chmod 755 ./*.sh
sudo chmod -R +w "$LOCAL_REPO_WARC_PATH"

# reload the list of services to catch the new one
sudo systemctl daemon-reload

# list all services, should include this one:
# sudo systemctl list-units -t service --all
# no errors from above

set +e
sudo systemctl status "$SERVICE_NAME_FULL"
# exits with error code 3
set -e

sudo systemctl start "$SERVICE_NAME_FULL"

sudo systemctl enable "$SERVICE_NAME_FULL"

# tail -f "$WARC_SERVICE_LOG_PATH"
