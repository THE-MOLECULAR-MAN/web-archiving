#!/bin/bash
# Tim H 2021
# Stops the Warc Proxy service.
# shellcheck disable=1091
source ./warc-settings-ubuntu.sh

################################################################################
#		FUNCTION DEFINITIONS
################################################################################

friendlier_date () {
    #Looks like this: 2021-02-26 03:55:09 PM EST
	date +"%Y-%m-%d %I:%M:%S %p %Z"
}

log () {
	# formatted log output including timestamp
    echo -e "[$THIS_SCRIPT_NAME] $(friendlier_date)\t $*"
}

# need a "configure-logging" function to call once
configure_logging () {
	THIS_SCRIPT_NAME="warc-proxy-stop-ubuntu.sh"
	
	LOGFILE="$WARC_SERVICE_LOG_PATH"                           # filename of file that this script will log to. Keeps history between runs.

	# Set up logging to external file
	exec >> "$LOGFILE"
	exec 2>&1
}


################################################################################
#		MAIN PROGRAM
################################################################################

configure_logging

log "========= STARTING WARC-PROXY-STOP ============="

#log "========= What invoked this script: ============="
#ps -o args="$PPID"

if [ -f "$WARC_PID_FILE_PATH" ]; then
  log "Found PID file, killing process in PID file"
  pkill --pidfile "$WARC_PID_FILE_PATH"
  log "PID ended"
else
  log "Could not find PID file: $WARC_PID_FILE_PATH. Cannot stop service if not running"
  exit 4
fi

#pkill -f warcprox

log "====== FINISHED WARC-PROXY-STOP SUCCESSFULLY ========"
