#!/bin/bash
# Tim H 2021
# Jackbox Games archiver
#   Downloads all the user-generated game images associated with a handful 
#   of Jackbox games provided a list of game instance URLs
#   They occasionally delete old games, so it's nice to have an archive of 
#   funny images and stuff you made with your friends
#
# These webpages are React JS - single page applications based also on GraphQL
#   so they're tougher to crawl. Can't mirror
# Luckily, the URLs for the images are highly predictable based on the game 
#   name and game instance ID.
#
#   Currently supported Jackbox game links:
#       Tee K.O.
#       Quiplash 2 & 3
#       Civic Doodle
#       Champ'd Up
#       Blather Round
#       Talking Points
#       Trivia Murder Party 2
#       Mad Verse City
#       Joke Boat

# bomb out if any errors
set -e

##############################################################################
# Defining variables for your specific environment
##############################################################################
# TODO: $HOME might break in cron if referenced before env defined

# full path to where the files will be downloaded to.
ARCHIVE_DIR="/nfs_mount_point/web_archiving/jackbox_archive/"  

# absolute path, list of URLs to Jackbox game instances
JACKBOX_URLS_FILE_PATH="$ARCHIVE_DIR/jackbox_links.txt"             

# number of seconds (can be decimal) to sleep between wget requests. Setting 
#   to 0 will cause some legit downloads to fail.
SLEEP_TIME_SEC="1"

# You shouldn't need to modify anything below this line

##############################################################################
#		ONE TIME SETUP - Run before the first run.
##############################################################################
# sudo yum install -y wget    # Install dependencies


##############################################################################
#		FUNCTION DEFINITIONS
##############################################################################

function manual_env_load {
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

function friendlier_date {
    # Looks like this: 2021-02-26 03:55:09 PM EST
	date +"%Y-%m-%d %I:%M:%S %p %Z"
}

function log {
	# formatted log output including timestamp
	# echo -e "[$THIS_SCRIPT_NAME] $(date)\t $@"
    echo -e "[$THIS_SCRIPT_NAME] $(friendlier_date)\t $*"
}

# need a "configure-logging" function to call once
function configure_logging {
    THIS_SCRIPT_NAME=$(basename "$0")   # OS X version doesn't support --suffix

	# configure $HOME as /root if it is not defined
	if [ "$HOME" == "" ]; then
		HOME="/root"
		# or maybe source the profile files
	fi
	
    # filename of file that this script will log to. Keeps history between runs.
	LOGFILE="$ARCHIVE_DIR/history-$THIS_SCRIPT_NAME.log"
    
	# Set up logging to external file
	exec >> "$LOGFILE"
	exec 2>&1
}


function download_file {
    URL_TO_DOWNLOAD="$1"
    DOWNLOAD_FOLDER_PATH="$2"
    FILENAME=$(basename "$URL_TO_DOWNLOAD")

    if [[ -f "$DOWNLOAD_FOLDER_PATH/$FILENAME" ]]; then
        log "file exists, skipping download: $DOWNLOAD_FOLDER_PATH/$FILENAME"
    else
        log "download_file: about to wget $URL_TO_DOWNLOAD into $DOWNLOAD_FOLDER_PATH"
        set +e
        wget --directory-prefix="$DOWNLOAD_FOLDER_PATH" \
            --quiet --no-clobber "$URL_TO_DOWNLOAD"
        set -e
        
        # Fun fact: AWS seems to throttle you, so I have to put sleeps in here
        #  otherwise the download will fail even though it is a valid URL.
        sleep "$SLEEP_TIME_SEC" 
    fi
}


##############################################################################
#		MAIN PROGRAM
##############################################################################

configure_logging

# need to retest the next line, can't remember if it was required or not
# useful for defining PATH variable and others when running as cron
#manual_env_load		

log "========= STARTING ============="

# make sure the directory to dump the downloads exists (mounted)
if [[ ! -d "$ARCHIVE_DIR" ]]; then
    log "Archive directory: $ARCHIVE_DIR does not exist. Exiting"
    exit 2
fi

# make sure that the Jackbox URL list file exists, bail if not.
if [[ ! -f "$JACKBOX_URLS_FILE_PATH" ]]; then
    log "Jackbox list file: $JACKBOX_URLS_FILE_PATH does not exist. Exiting"
    pwd
    ls -lah
    exit 4
else
    # remove duplicates to save time, overwrite current file
    sort --unique -o "$JACKBOX_URLS_FILE_PATH" "$JACKBOX_URLS_FILE_PATH"
fi

# iterate through each line in the list of Jackbox URLs text file
while IFS="" read -r ITER_JACKBOX_URL || [ -n "$ITER_JACKBOX_URL" ]
do
    # extract some information from the URL
    GAME_NAME=$(echo "$ITER_JACKBOX_URL" | cut -d/ -f5)
    GAME_INSTANCE_ID=$(echo "$ITER_JACKBOX_URL" | cut -d/ -f6)
    # game instances are a 32 character hex string 
    # = 128 bit key (~3.4 X 10^38 combinations), so no hope for 
    #   brute forcing them

    # create the game and instance directory if they don't already exist
    if [[ ! -d "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID" ]]; then
        mkdir -p "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID"
    fi

    # check to see if the game instance has been previously downloaded
    if [[ -f  "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/complete" ]]; then
        log "complete file exists, checking how many times done"
        # check if script has tried at least 3 times to download all the
        # files. If so, then don't bother
        if [[ $(wc -l "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/complete" | awk '{ print $1 }') -ge 3 ]]; then
            log "already downloaded several times: $GAME_NAME/$GAME_INSTANCE_ID, skipping"
            continue
        else
            # it has been downloaded before, but between 1 and 2 times, 
            # so try again to make sure it downloaded everything
            log "already downloaded a few times, but fewer than the max... "
        fi
    fi

    # default unless otherwise specified, has to be inside the outer loop
    #   , don't move this.
    MAX_IMAGES=20  

    # figure out which game it is, each one has a slightly different URL 
    #   structure for pulling from S3
    case $GAME_NAME in
        TeeKOGame)
            log "Selected: Tee K.O. for $ITER_JACKBOX_URL"
            IMAGE_PATH_PREFIX="https://s3.amazonaws.com/jbg-blobcast-artifacts/$GAME_NAME/$GAME_INSTANCE_ID/shirtimage-"
            IMAGE_PATH_SUFFIX=".png"
            MAX_IMAGES=15
            ;;
        
        quiplash3Game | Quiplash2Game | WorldChampionsGame | TriviaDeath2Game)
            log "Selected: Quiplash 2, 3, Champ'd Up, or Trivia Murder Party 2 for $ITER_JACKBOX_URL"
            IMAGE_PATH_PREFIX="https://s3.amazonaws.com/jbg-blobcast-artifacts/$GAME_NAME/$GAME_INSTANCE_ID/anim_"
            IMAGE_PATH_SUFFIX=".gif"
            # this one supports the /index.html to the original URL
            ;;

        BlankyBlankGame)
            log "Selected: Blather Round for $ITER_JACKBOX_URL"
            IMAGE_PATH_PREFIX="https://s3.amazonaws.com/jbg-blobcast-artifacts/$GAME_NAME/$GAME_INSTANCE_ID/image_"
            IMAGE_PATH_SUFFIX=".png"
            # this one does NOT support the /index.html to the original URL
            ;;

        JackboxTalksGame | OverdrawnGame)
            log "Selected: Talking Points or Civic Doodle for $ITER_JACKBOX_URL"
            IMAGE_PATH_PREFIX="https://s3.amazonaws.com/jbg-blobcast-artifacts/$GAME_NAME/$GAME_INSTANCE_ID/anim_"
            
            # slightly different, the _1 _2 _3 etc are the awards given to
            #   each one. Would need an inner loop
            IMAGE_PATH_SUFFIX="_0.gif"  
            MAX_IMAGES=8
            # this one supports the /index.html to the original URL
            ;;

        RapBattleGame)
            log "Selected: Mad Verse City for $ITER_JACKBOX_URL"
            IMAGE_PATH_PREFIX="https://s3.amazonaws.com/jbg-blobcast-artifacts/$GAME_NAME/$GAME_INSTANCE_ID/anim_"
            IMAGE_PATH_SUFFIX=".gif"  
            # this one supports the /index.html to the original URL
            # Max players is 8 total
            # Number of rounds: always 3 [0,2]
            # anim_X_Y_Z.gif
            # X is round number, always varies from [0,2]
            # Y is battle number [0,(Number of players / 2) -1 ], 
            #       max players is 8 players, so Y_max is 3
            # Z only varies from [0,1]
            OUTER_LOOP_MAX=2
            MIDDLE_LOOP_MAX=3
            INNER_LOOP_MAX=1

            for ITER_OUTER_LOOP in $(seq 0 $OUTER_LOOP_MAX); do 
                for ITER_MIDDLE_LOOP in $(seq 0 $MIDDLE_LOOP_MAX); do 
                    for ITER_INNER_LOOP in $(seq 0 $INNER_LOOP_MAX); do 
                        FULL_URL_TO_DOWNLOAD="${IMAGE_PATH_PREFIX}${ITER_OUTER_LOOP}_${ITER_MIDDLE_LOOP}_${ITER_INNER_LOOP}${IMAGE_PATH_SUFFIX}"
                        download_file "$FULL_URL_TO_DOWNLOAD" "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID"
                    done
                done
            done

            # mark this game instance as complete
            date +"%Y-%m-%d %I:%M:%S %p %Z" >> "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/complete"
            continue
            ;;

        JokeboatGame)
            log "Selected: Joke Boat for $ITER_JACKBOX_URL"
            IMAGE_PATH_PREFIX="https://s3.amazonaws.com/jbg-blobcast-artifacts/$GAME_NAME/$GAME_INSTANCE_ID/anim_"
            IMAGE_PATH_SUFFIX=".gif"
            # anim_N_M.gif
            # N = number of players: ranges 0..N max of 8
            # M = number of rounds = always [0,4]: there are 5 rounds total always (including final round)
            OUTER_LOOP_MAX=7    # Number of (max) Players is always 8 [0,7]
            INNER_LOOP_MAX=4    # Number of rounds in game [0,4]

            for ITER_OUTER_LOOP in $(seq 0 $OUTER_LOOP_MAX); do 
                for ITER_INNER_LOOP in $(seq 0 $INNER_LOOP_MAX); do 
                    FULL_URL_TO_DOWNLOAD="${IMAGE_PATH_PREFIX}${ITER_OUTER_LOOP}_${ITER_INNER_LOOP}${IMAGE_PATH_SUFFIX}"
                    download_file "$FULL_URL_TO_DOWNLOAD" "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID"
                done
            done

            # mark this game instance as complete
            date +"%Y-%m-%d %I:%M:%S %p %Z" >> "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/complete"
            continue
            ;;

        *)
            log "ERROR - unknown game name: $GAME_NAME, skipping $ITER_JACKBOX_URL"
            continue
            ;;
    esac

    # Don't bother trying to do a site mirror with wget since this is a single
    #   page application that highly relies on React JS to render the page.
    #   this would have created a site-mirror directory and download the 
    #   files for the HTML
    # if [[ ! -d "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/site-mirror" ]]; then
    #    mkdir -p "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/site-mirror"
    #    cd  "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/site-mirror"
    #    wget  --quiet --mirror --convert-links --adjust-extension --page-requisites --no-parent "$ITER_JACKBOX_URL/index.html"
    # fi

    # iterate from 0 to MAX_IMAGES and attempt to download each for this 
    #   instance of the game
    for iter_img_number in $(seq 0 $MAX_IMAGES); do 
        #log "$IMAGE_PATH_PREFIX$iter_img_number$IMAGE_PATH_SUFFIX"
        
        # only compatible with bash 4.0 and later, no on OS X, doesn't seem to work with zsh either
        #wget example.com/imageId={1..100}.jpg  
        FULL_URL_TO_DOWNLOAD="${IMAGE_PATH_PREFIX}${iter_img_number}${IMAGE_PATH_SUFFIX}"
        download_file "$FULL_URL_TO_DOWNLOAD" "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID"
    done

    # mark this game instance as complete
    date +"%Y-%m-%d %I:%M:%S %p %Z" >> "$ARCHIVE_DIR/$GAME_NAME/$GAME_INSTANCE_ID/complete"
done < "$JACKBOX_URLS_FILE_PATH"

log "new images found within past 24 hours:"
find "$ARCHIVE_DIR" -type f \( -iname \*.jpg -o -iname \*.png \) -mtime -1

log "==== SCRIPT ENDED SUCCESSFULLY ====="
