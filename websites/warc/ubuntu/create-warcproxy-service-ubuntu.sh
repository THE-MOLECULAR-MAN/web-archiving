#!/bin/bash
# Tim H 2022

# https://www.shellhacks.com/systemd-service-file-example/

# Gotcha: don't put executable files like the start/stop scripts on an NFS
# mount that is marked as noexec

# shellcheck disable=1091
source ./warc-settings-ubuntu.sh

# create the service definition file
echo "[Unit]
 Description=WARC Proxy
 After=piavpn.service

[Service]
 ExecStart=$WARC_STORAGE_PATH/warc-proxy-start-ubuntu.sh
 ExecStop=$WARC_STORAGE_PATH/warc-proxy-stop-ubuntu.sh
 PIDFile=$WARC_PID_FILE_PATH
" | sudo tee "$SERVICE_FILE_PATH"

# change the permissions on the new file
sudo chmod 664 "$SERVICE_FILE_PATH"

# mark the scripts as executable so the start/stop work
sudo chmod +x "$WARC_STORAGE_PATH/*.sh"

# reload the list of services to catch the new one
sudo systemctl daemon-reload

# list all services, should include this one:
sudo systemctl list-units -t service --all

sudo systemctl status "$SERVICE_NAME_FULL"

sudo systemctl start "$SERVICE_NAME_FULL"

sudo systemctl enable "$SERVICE_NAME_FULL"

tail -f "$WARC_SERVICE_LOG_PATH"
