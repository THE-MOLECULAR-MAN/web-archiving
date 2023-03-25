#!/bin/bash
# Tim H 2021
#
# Reorganize Facebook messages into an easier to browse and search structure
# Download the big ZIP file from them and point it at the extracted directory

SOURCE_DIR="$HOME/Downloads/Facebook-backup-ZIP-extracted/"
TARGET_MOVE_DIR="$HOME/Downloads/fixed-fb-messages"

mkdir "$TARGET_MOVE_DIR"

cd "$SOURCE_DIR" || exit 2

# Observation: there are no spaces in any file/directory names in FB downloads as of May 2021
# so I can cheat and use the for _ in $(find...) structure that would normally break if there are spaces
# TODO: should eventually do this: https://github.com/koalaman/shellcheck/wiki/SC2044
# shellcheck disable=SC2044
for ITER_HTML_FILE in $(find "$SOURCE_DIR" -type f -iname 'message_1.html'); do
    echo "$ITER_HTML_FILE"
    CLEAN_DIR_NAME=$(basename "$(dirname "$ITER_HTML_FILE")")
    cp "$ITER_HTML_FILE" "$TARGET_MOVE_DIR/$CLEAN_DIR_NAME.html"
done
