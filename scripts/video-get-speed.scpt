#!/usr/bin/env osascript


on run 
   set jsCommand to "console.log( 'get current speed' );document.querySelector('video').playbackRate;"

   tell application "Google Chrome"
       execute front window's active tab javascript jsCommand
   end tell
end run

