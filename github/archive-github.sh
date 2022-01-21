#!/bin/bash
# Tim H 2021
# GitHub archiver - download all (non-forked, public) repos from listed GitHub
#   users. You provide a list of GitHub usernames (one per line) in a text
#   file. It will automatically create relevant directories for users and 
#   repos if it hasn't seen them before. It will do "git pull" on previously
#   cached repos, git clone on new ones
#   Designed for CentOS 7
# 
# Only takes about 15 seconds to run if there are no updates
#
# Designed to be a cron to run daily
# example crontab for daily at 1 AM
# 1 0 * * * $HOME/bin/archive-github.sh
#
# References:
#   https://www.baeldung.com/linux/jq-command-json
#   
# TODO: add API key to get access to private repos
# TODO: split out active repos from archived ones, store archived ones as 
#       ZIP file instead

# bomb out if any errors
set -e

##############################################################################
# Defining variables for your specific environment
##############################################################################
# text file where the list of GitHub usernames, one username per line
GITHUB_USER_LIST_FILE_PATH="./github_users_list_for_archiving.txt"  

# full path to where the files will be downloaded to.
ARCHIVE_DIR="/nfs_mountpoint/web_archiving/github"               

# You shouldn't need to modify anything below this line

##############################################################################
#		ONE TIME SETUP - Run before the first run.
##############################################################################
# sudo yum install -y jq    # Install dependencies
# mkdir -p "$ARCHIVE_DIR"   # Create the downloading directory

##############################################################################
#		FUNCTION DEFINITIONS
##############################################################################
THIS_SCRIPT_NAME=$(basename --suffix=".sh" "$0")

# filename of file that this script will log to. Keeps history between runs.
LOGFILE="./history-$THIS_SCRIPT_NAME.log"         

friendlier_date () {
    #Looks like this: 2021-02-26 03:55:09 PM EST
	date +"%Y-%m-%d %I:%M:%S %p %Z"
}

log () {
	# formatted log output including timestamp
	#echo -e "[$THIS_SCRIPT_NAME] $(date)\t $@"
    echo -e "[$THIS_SCRIPT_NAME] $(friendlier_date)\t $*"
}

##############################################################################
#		MAIN PROGRAM
##############################################################################

# Set up logging to external file
exec >> "$LOGFILE"
exec 2>&1

# start a log so I know it ran
log "========= START ============="

# make sure the directory to dump the downloads exists (mounted)
if [[ ! -d "$ARCHIVE_DIR" ]]; then
    log "Archive directory: $ARCHIVE_DIR does not exist. Exiting"
    exit 2
fi

# change directory to the download destination, bail if it doesn't exist
cd "$ARCHIVE_DIR" || exit 3

# make sure that the github user list file exists, bail if not.
if [[ ! -f "$GITHUB_USER_LIST_FILE_PATH" ]]; then
    log "GitHub user list file: $GITHUB_USER_LIST_FILE_PATH does not exist. Exiting"
    exit 4
fi

# iterate through each line in the GITHUB_USER_LIST_FILE_PATH text file
while IFS="" read -r p || [ -n "$p" ]
do
    log "starting downloading github user $p ..."
    
    # get list of URLs for repositories for a particular user; remove forks,
    #   don't care about them as much
    LIST_CLONE_URLS=$(curl -sSf "https://api.github.com/users/$p/repos" | jq -r '.[] | select(.fork == false) | .clone_url')
    
    # loop through each URL for a repository
    while IFS= read -r ITER_URL; do
        # log "pulling repo URL: $ITER_URL"
        
        # check to see if empty
        if [[ -z "$ITER_URL" ]]; then
            log "User $p does not have any repos that match the filter. Skipping."
            #c ontinue
            break
        fi

        # create the new directory for the user if it did not already exist
        if [[ ! -d "$ARCHIVE_DIR/$p" ]]; then
            log "User directory $p did not exist. Creating..."
            mkdir "$ARCHIVE_DIR/$p"
        fi

        # move into that user's directory
        cd "$ARCHIVE_DIR/$p" || exit 5

        # extract the name of the repository, don't include the ".git"
        #    at the end of it either
        ITER_REPO_NAME=$(basename --suffix=".git" "$ITER_URL")

        # test to see if directory for the repo dir exists
        if [[ ! -d "$ARCHIVE_DIR/$p/$ITER_REPO_NAME" ]]; then
            # if directory doesn't exist then create it by doing a
            # git clone once.
            log "No local copy of $p's repo named $ITER_REPO_NAME found, cloning for the first time ..."
            git clone --quiet "$ITER_URL"
        else
            # if directory does already exist, then cd into existing repo
            # directory and git pull for update
            cd "$ARCHIVE_DIR/$p/$ITER_REPO_NAME" || exit 6
            log "Updating existing repo (pull) $ITER_REPO_NAME ..."
            git pull --quiet
        fi        
    done <<< "$LIST_CLONE_URLS"
    
    log "finished downloading repos for github user $p ."
done < "$GITHUB_USER_LIST_FILE_PATH"

# calculate size of cache and # of files/directories
TOTAL_SIZE_OF_CACHE=$(du -sh "$ARCHIVE_DIR" | cut -f1 -d$'\t')
TOTAL_CACHE_FILE_COUNT=$(find "$ARCHIVE_DIR" | wc -l)

# display a summary of disk space sizes and stuff for logging history
log "==== SIZE: $TOTAL_SIZE_OF_CACHE ===="
log "==== TOTAL NUMBER OF FILES/DIRS: $TOTAL_CACHE_FILE_COUNT ===="
log "==== SCRIPT ENDED SUCCESSFULLY ====="
