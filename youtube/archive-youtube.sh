#!/bin/bash
# Tim H 2021
#
# This script is designed for Fedora 33, but could be used on CentOS or Ubuntu
# with slight modifications
# download all new YouTube videos on channels/accounts listed in text file
# skips videos that have already been downloaded.
# Logs everything in a log file
#
# Designed to be a cron to run daily
#   example crontab for daily at midnight
#       0 0 * * * $HOME/bin/archive-youtube.sh
#
# References:
#   https://www.reddit.com/r/DataHoarder/comments/c6fh4x/after_hoarding_over_50k_youtube_videos_here_is/
#   https://ytdl-org.github.io/youtube-dl/index.html
#   https://en.wikipedia.org/wiki/Youtube-dl
#   
################################################################################
# Defining variables for your specific environment
################################################################################
URLS_LIST_FILE_PATH="./youtube_urls_for_archiving.txt"          # text file where the list of URLs to YouTube and Vimeo channels/playlists/videos are. One per line
ARCHIVE_DIR="$HOME/nfs_torrents/web_archiving/YouTube"          # full path to where the files will be downloaded to.
CACHE_LIST_FILE="./videos_downloaded_index.txt"                 # filename of file that lists all the unique identifiers of videos previously downloaded (index)

# You shouldn't need to modify anything below this line


################################################################################
#		ONE TIME SETUP - Run before the first run.
################################################################################
# yum install -y ffmpeg          # CentOS version (untested)
# mkdir -p "$ARCHIVE_DIR"        # Create the downloading directory

################################################################################
#		FUNCTION DEFINITIONS
################################################################################
THIS_SCRIPT_NAME=$(basename --suffix=".sh" "$0")

# filename of file that this script will log to. Keeps history between runs.
LOGFILE="./history-$THIS_SCRIPT_NAME.log"

log () {
	# formatted log output including timestamp
	echo -e "[$THIS_SCRIPT_NAME] $(date)\t $*"
}

################################################################################
#		MAIN PROGRAM
################################################################################

# Set up logging to external file
exec >> "$LOGFILE"
exec 2>&1

# start a log so I know it ran
log "========= START ============="

# make a backup of the file that lists all the URLs I've cached before, just in case it gets corrupted mid-run.
cp --force "$CACHE_LIST_FILE" "$CACHE_LIST_FILE.backup"

# make sure the directory to dump the downloads exists (might be mounted)
if [[ ! -d "$ARCHIVE_DIR" ]]; then
    log "$ARCHIVE_DIR directory (download location) does not exist. Exiting."
    exit 1
fi

# change directory to the download destination, bail if it doesn't exist
cd "$ARCHIVE_DIR" || exit 2

# make sure that the URLs list file exists, bail if not.
if [[ ! -f "$URLS_LIST_FILE_PATH" ]]; then
    log "$URLS_LIST_FILE_PATH file (list of videos/channels) does not exist. Exiting."
    exit 3
fi

# iterate through each line in the URLS_LIST_FILE_PATH text file
while IFS="" read -r p || [ -n "$p" ]
do
    log "Starting downloading/updating all videos from $p ..."
    # download that channel/user/playlist. Quiet mode to minimize output in log
    youtube-dl --download-archive "$CACHE_LIST_FILE" -i --add-metadata --all-subs \
        --embed-subs --embed-thumbnail --no-progress --no-call-home \
        --match-filter "playlist_title != 'Liked videos' & playlist_title != 'Favorites'" -f "(bestvideo[vcodec^=av01][height>=1080][fps>30]/bestvideo[vcodec=vp9.2][height>=1080][fps>30]/bestvideo[vcodec=vp9][height>=1080][fps>30]/bestvideo[vcodec^=av01][height>=1080]/bestvideo[vcodec=vp9.2][height>=1080]/bestvideo[vcodec=vp9][height>=1080]/bestvideo[height>=1080]/bestvideo[vcodec^=av01][height>=720][fps>30]/bestvideo[vcodec=vp9.2][height>=720][fps>30]/bestvideo[vcodec=vp9][height>=720][fps>30]/bestvideo[vcodec^=av01][height>=720]/bestvideo[vcodec=vp9.2][height>=720]/bestvideo[vcodec=vp9][height>=720]/bestvideo[height>=720]/bestvideo)+(bestaudio[acodec=opus]/bestaudio)/best" \
        --merge-output-format mkv -o '%(uploader)s/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s' \
        "$p"
    log "Finished downloading all videos from $p"
done < "$URLS_LIST_FILE_PATH"

# make another backup of the previous downloads file before changing it
cp --force "$CACHE_LIST_FILE" "$CACHE_LIST_FILE.backup2"

# sort the previous downloads index to shorten future checks
# the old comp sci student in me saw an unoptimized search alg. 
# Probably only useful if you archive a LOT of videos.
sort --unique --output="$CACHE_LIST_FILE" "$CACHE_LIST_FILE"

# summary of all cached videos (size and count)
NUMBER_OF_VIDEOS_CACHED=$(wc -l "$CACHE_LIST_FILE")
TOTAL_SIZE_OF_CACHE=$(du -sh "$ARCHIVE_DIR" | cut -f1 -d$'\t')
log "= VIDEOS CACHED: $NUMBER_OF_VIDEOS_CACHED   SIZE: $TOTAL_SIZE_OF_CACHE ="
log "== SCRIPT ENDED SUCCESSFULLY =="
