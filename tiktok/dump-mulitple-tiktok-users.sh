#!/bin/bash
# Tim H 2023

# Downloads many videos for each TikTok username listed in a text file.
#
# TODO:
#   * change the filename to be a parameter
#
# Known issues:
#   * doesn't do any sort of validation on the TikTok usernames, doesn't
#       support commenting out anything yet.

# define the filename that lists all the usernames, one per line
# no URL or @ needed
TIKTOK_USERNAMES_LIST_FILE="tiktok_username_list.txt"

# loop through each user listed in the text file
while IFS="" read -r ITER_USERNAME || [ -n "$ITER_USERNAME" ]
do
    # dump that single user
    /bin/bash ./dump-single-tiktok-user.sh "$ITER_USERNAME"
done < "$TIKTOK_USERNAMES_LIST_FILE"

echo "finished dump-multiple-tiktok-users.sh successfully"
