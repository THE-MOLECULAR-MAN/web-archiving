#!/bin/bash
# Tim H 2021
# Stops the Warc Proxy service.

################################################################################
#		FUNCTION DEFINITIONS
################################################################################

friendlier_date () {
    #Looks like this: 2021-02-26 03:55:09 PM EST
	date +"%Y-%m-%d %I:%M:%S %p %Z"
}

log () {
	# formatted log output including timestamp
	#echo -e "[$THIS_SCRIPT_NAME] $(date)\t $@"
    echo -e "[$THIS_SCRIPT_NAME] $(friendlier_date)\t $*"
}

# need a "configure-logging" function to call once
configure_logging () {
	THIS_SCRIPT_NAME="warc-proxy-service"

	# configure $HOME as /root if it is not defined
	if [ "$HOME" == "" ]; then
		HOME="/root"
		# or maybe source the profile files
	fi
	
	LOGFILE="$HOME/history-$THIS_SCRIPT_NAME.log"                           # filename of file that this script will log to. Keeps history between runs.

	# Set up logging to external file
	exec >> "$LOGFILE"
	exec 2>&1
}


################################################################################
#		MAIN PROGRAM
################################################################################

configure_logging

log "========= STARTING WARC-PROXY-STOP ============="

log "========= What invoked this script: ============="
ps -o args="$PPID"

# get the screen session ID
SCREEN_SESSION_ID=$(screen -ls | grep warc | cut -d "." -f1 | xargs)

# stop the screen session and thus kill the warc proxy
#log "====== not going to try to kill the service ========"
#screen -ls

screen -X -S "$SCREEN_SESSION_ID" quit

log "====== FINISHED WARC-PROXY-STOP SUCCESSFULLY ========"
