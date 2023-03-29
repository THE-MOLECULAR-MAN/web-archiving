#!/bin/bash
# Tim H 2022

# WARC settings file
set -e


HOME=$(getent passwd $(whoami) | cut -f6 -d:)
export HOME


if [[ -f /etc/profile ]]; then
    set +e      # this is surprisingly important since the profile often
    # returns errors
    # shellcheck disable=1091
    source /etc/profile
    set -e
fi


cd || exit 1

CURRENT_USER_HOME=$(pwd)
export CURRENT_USER_HOME

export LOCAL_REPO_WARC_PATH="$CURRENT_USER_HOME/source_code/web-archiving/websites/warc/ubuntu"
export MOUNT_POINT="$CURRENT_USER_HOME/nfs_warc"
export SERVICE_NAME="warcproxyd"
export SERVICE_NAME_FULL="$SERVICE_NAME.service"
export WARC_STORAGE_PATH="$MOUNT_POINT/web_archiving/websites_via_wayback_warc"
export SERVICE_FILE_PATH="/etc/systemd/system/$SERVICE_NAME.service"
export WARC_SERVICE_LOG_PATH="/var/log/$SERVICE_NAME.log"

export WARC_PROXY_PORT="8000"                              # TCP port (> 1024) for proxy to listen on LAN adapter
export LOCAL_SUBNET_PREFIX="10.0.1."                       # prefix to grep for LAN IP (not VPN IP). Ex: 10.0.1. or 192.168.1.
export UNDESIRED_PUBLIC_HOSTNAME="whatever.redacted.me"      # dynamic DNS entry that maps to your home network to make sure you're on a VPN
export WARC_PID_FILE_PATH="/run/$SERVICE_NAME.pid"

# quick retest:
# sudo systemctl stop warcproxyd.service
# sudo truncate -s 0 /var/log/warcproxyd.log
# sudo systemctl start warcproxyd.service 
# sudo systemctl status warcproxyd.service
# cat /var/log/warcproxyd.log

# pgrep warc

# mkdir /etc/warcproxyd/

# way to source files from user's home directory without
cd || exit 2 

# relying on variables (since the variables may not be defined)
if [[ -f ./.profile ]]; then
    # shellcheck disable=1091
    source ./.profile
fi

if [[ -f ./.bashrc ]]; then 
    # shellcheck disable=1091
    source ./.bashrc
fi

echo "warc-settings-ubuntu.sh finished successfully"
