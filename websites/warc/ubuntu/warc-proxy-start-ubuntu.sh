#!/bin/bash
# Tim H 2021
#   Service start for WARC proxy. Default setup:
#       Listens on TCP 8000
#       rotates the WARC file once per day
#       limits the WARC file to 250 MB before rotating
#   This should be installed to autostart on boot.
#   Checks to make sure it is only listening on the LAN IP (not the VPN one) and 
#       
#
#   References:
#       https://www.thegeekdiary.com/centos-rhel-7-how-to-make-custom-script-to-run-automatically-during-boot/

# bomb out in case of errors
set -e

################################################################################
# Defining variables for your specific environment
################################################################################
# shellcheck disable=1091
source ./warc-settings-ubuntu.sh
# You shouldn't need to modify anything below this line

################################################################################
#		ONE TIME SETUP - Run before the first run.
################################################################################
# sudo yum install -y screen    # Install dependencies


################################################################################
#		FUNCTION DEFINITIONS
################################################################################
manual_env_load () {
	# TODO: make it more user aware rather than just assuming root
	# Fixes issues with crontab
	# echo "Env before:"
	# env
	# shellcheck disable=SC1091
	source "/root/.bashrc"
	# shellcheck disable=SC1091
	source "/root/.bash_profile"
	# shellcheck disable=SC1091
	source "/etc/profile"
	# echo "Env after:"
	# env
}

friendlier_date () {
    # Looks like this: 2021-02-26 03:55:09 PM EST
	date +"%Y-%m-%d %I:%M:%S %p %Z"
}

log () {
	# formatted log output including timestamp
	# echo -e "[$THIS_SCRIPT_NAME] $(date)\t $@"
    echo -e "[$THIS_SCRIPT_NAME] $(friendlier_date)\t $*"
}

# need a "configure-logging" function to call once
configure_logging () {
	THIS_SCRIPT_NAME="warc-proxy-start-ubuntu.sh"
	
	LOGFILE="$WARC_SERVICE_LOG_PATH"                           # filename of file that this script will log to. Keeps history between runs.

	# Set up logging to external file
	exec >> "$LOGFILE"
	exec 2>&1
}


# checks to make sure I'm not using my home internet connection without VPN to hide my location.
# I don't want this script to cause problems with my or my wife's YouTube access.
check_public_ip () {
	if [[ "$UNDESIRED_PUBLIC_HOSTNAME" == "" ]]
    then
		log "Skipping public IP detection since UNDESIRED_PUBLIC_HOSTNAME was blank" 
	else
		log "sleeping for 30 seconds to let VPN connect before testing it..." 
		sleep 30
		PUBLIC_IP=$(curl -sSf ifconfig.co)
		UNDESIRED_PUBLIC_IP=$(dig +short "$UNDESIRED_PUBLIC_HOSTNAME" | head -n 1)
		if [[ "$UNDESIRED_PUBLIC_IP" == "$PUBLIC_IP" ]]
		then
			log "ERROR: Get on a VPN before running this script. They're going to track your public IP." 
			exit 70
		else
			log "Public IP is fine, proceeding."
		fi
	fi
}


################################################################################
#		MAIN PROGRAM
################################################################################

configure_logging
manual_env_load		# useful for defining PATH variable and others when running as cron

set -e

log "========= STARTING $THIS_SCRIPT_NAME ============="

# debugging stuff, no longer necessary:
log "========= What invoked this script: ============="
ps -o args="$PPID"
log "WARC_PROXY_PORT= $WARC_PROXY_PORT"
log "LOCAL_SUBNET_PREFIX = $LOCAL_SUBNET_PREFIX"
log "UNDESIRED_PUBLIC_HOSTNAME= $UNDESIRED_PUBLIC_HOSTNAME"
log "CURRENT USER = " $(whoami)

if [ -f "$WARC_PID_FILE_PATH" ]; then
  log "Service already running. Found .pid file named $WARC_PID_FILE_PATH. Instance of application already exists. Exiting."
  exit 69
fi

check_public_ip

set -e

# grabs the internal LAN IP to avoid listening on VPN IP(s)
LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | \
	grep -Eo '([0-9]*\.){3}[0-9]*' | grep  "$LOCAL_SUBNET_PREFIX")
log "Local LAN IP: $LOCAL_IP"

# launch it without using screen since it'll be a service
log "about to start the proxy process..."
cd "$WARC_STORAGE_PATH" && \
	warcprox --dir ./recordings/ -address "$LOCAL_IP" \
		--port "$WARC_PROXY_PORT" --gzip \
		--rollover-idle-time 86400 --size 250000000 &
NEW_PID=$($!)
log "sleeping to let it start up..."

if [ ! -f "$WARC_PID_FILE_PATH" ]; then
  log "Creating new .pid file $WARC_PID_FILE_PATH"
  echo "$NEW_PID" > "$WARC_PID_FILE_PATH"
else
  log "After service start, found existing .pid file named $WARC_PID_FILE_PATH. Instance of application already exists. Exiting."
  exit 68
fi

sleep 3

# TODO: add notes to log about screen session and stuff.

# shellcheck disable=SC2009
log "Processes containing warc:
$(ps aux | grep warc)"

log "TCP & UDP ports listening:
$(netstat -tulpn | grep LISTEN)

$(ss -tulpn)

$(lsof -i -P -n | grep LISTEN)"

log "====== FINISHED $THIS_SCRIPT_NAME SUCCESSFULLY ========"
