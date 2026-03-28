#!/bin/sh
# Usage: chrome-profile.sh "Profile Menu Name"
# Activates Chrome, waits for it to be frontmost, then switches to the given profile.
PROFILE="$1"
osascript -e 'tell application "Google Chrome" to activate'
sleep 0.5
osascript -e "tell application \"System Events\" to tell process \"Google Chrome\" to click menu item \"$PROFILE\" of menu 1 of menu bar item \"Profiles\" of menu bar 1"
