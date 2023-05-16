#!/usr/bin/env osascript

-- WARNING: it does not work with disney.
--    There is a weird buffering issue. if the buffer does
--    not contain the desired time... it will simply
--    screw the video

-- this is a very cludjy way to send some javascript to the browser
-- they might be better ways, but for the time being, it works

-- how it works: two parms: time to seek and duration of play
--   get video entity
--   set currentTime to desired offset
--   start playing
--   set a callback for howlong to play that stops video

-- the video needs offset in seconds, but the callback requires
-- the timeout in miliseconds

on run parms
   set secs to item 1 of parms
   set howlong to item 2 of parms
   set howlong to howlong * 1000.0

   set jsEnd to "v.currentTime;\n"
   set jsCallback to "setTimeout(function() {\n" & ¬
   "  console.log('Callback is working after', howlong);\n" & ¬
   "  v.pause();" & ¬
   "}, howlong);"

   set jsPlay to "v.currentTime=secs;\nv.play();\n"

   set jsCommand to "var secs = " & secs & ";\n" & ¬
     "var howlong = " & howlong & ";\n" & ¬
     "var v=document.querySelector('video')\n" & ¬
     "console.log( 'set current time',secs, howlong );\n" & ¬
     jsPlay & ¬
     jsCallback & ¬
     jsEnd

   tell application "Google Chrome"
       execute front window's active tab javascript jsCommand
   end tell
end run



