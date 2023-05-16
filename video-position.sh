#!/usr/bin/env osascript

--on run timeStamp
--   tell application "Keyboard Maestro Engine"
--       do script "_f_video_get_current_time"
--       getvariable "videoRet"
--   end tell
--end run          

set jsCommand to "console.log( 'get current time' );document.querySelector('video').currentTime;"

tell application "Google Chrome"
   execute front window's active tab javascript jsCommand
end tell
