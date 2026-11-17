# Pi Screen
This project has 2 parts.
1) double_buffering_auto_update.py - watches a folder "screen-display-files" and displays on an led matrix the latest image added to the file
2) runchrome/runLEDWatcher.js - watches a web url, takes screenshots of it and saves it to a folder "screen-display-files"

# Prerequisites
- A raspberry pi connected to a wifi network.
- git installed


# Setup
1) git clone repo
2) make setupLED.sh and start.sh executable ( chmod +x setupLED.sh startLED.sh )
2) run setupLED.sh

# Start
1) run startLED.sh