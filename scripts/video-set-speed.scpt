#!/usr/bin/env osascript

-- eval(
--(function () {
--   var video = document.querySelector('video')
--   var speed=document.kmvar.speedParm;
--   console.log("Getting set speed", speed, video.playbackRate) ;
--   if (speed > 0.2 && speed <= 1.0) {
--       video.playbackRate=speed
--   } else {
--       console.log("Invalid speed");
--  }
--   console.log("Current speed:", video.playbackRate);
--}())
--)
--

on run videoSpeed

   set jsMainCode to  "document.querySelector('video').playbackRate = speed;\ndocument.querySelector('video').playbackRate;\n"

   set jsCommand to "var speed = " & videoSpeed & ¬
       ";\n" & jsMainCode

--    set jsCommand to "console.log( 'get current time' );document.querySelector('video').playbackRate;"


   tell application "Google Chrome"
       execute front window's active tab javascript jsCommand
   end tell
end run

