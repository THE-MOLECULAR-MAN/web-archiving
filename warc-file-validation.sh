#!/bin/bash
# Tim H 2023

# opening the WARC files
# install this app (as of 2023)
# https://github.com/webrecorder/replayweb.page/releases/


# Validating WARC files
# https://github.com/webrecorder/warcio#check
pip install warcio
cd "~/Downloads/recordings" || exit 5234
# the -v flag is TOO verbose
warcio check WARCPROX-20230329035501130-00000-7boasi18.warc || echo "check failed"
warcio recompress WARCPROX-20230329035501130-00000-7boasi18.warc WARCPROX-20230329035501130-00000-7boasi18.warc.gz


# another option for validation
# https://github.com/chfoo/warcat
# this one returns many errors found in WARC file
python3 -m pip install warcat
python3 -m warcat verify "WARCPROX-20230329035501130-00000-7boasi18.warc" --progress
