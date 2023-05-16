#!/usr/bin/env osascript

set jsCommand to "console.log( 'get url,title' );document.URL + ';;' + document.title + ';;' + window.getSelection().toString();"

tell application "Google Chrome"
   execute front window's active tab javascript jsCommand
end tell
