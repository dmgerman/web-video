#!/usr/bin/env osascript

set jsCommand to "console.log( 'get url,title' );document.URL + '&t=' + document.querySelector('video').currentTime + 's' ;"
 
tell application "Google Chrome"
   execute front window's active tab javascript jsCommand
end tell
