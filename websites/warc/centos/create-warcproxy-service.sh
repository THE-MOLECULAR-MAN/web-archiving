#!/bin/bash
# Tim H 2022

SERVICE_FILE_PATH="/etc/systemd/system/warcproxyd.service"

echo "[Unit]
 Description=WARC Proxy
 #Requires=
 #Before=
 #After=

[Service]
 ExecStart=/root/warc-proxy-start.sh
 #ExecStop=/root/warc-proxy-stop.sh
 #ExecReload=/root/warc-proxy-stop.sh && /root/warc-proxy-start.sh

#[Install]
# WantedBy=default.target
" | sudo tee "$SERVICE_FILE_PATH"

sudo chmod 664 "$SERVICE_FILE_PATH"

sudo systemctl daemon-reload

systemctl list-units -t service --all

sudo systemctl status warcproxyd.service

sudo systemctl start warcproxyd.service

sudo systemctl enable warcproxyd.service

tail -f /root/history-warc-proxy-service.log
