#!/usr/bin/env osascript

--on run timeStamp
--   tell application "Keyboard Maestro Engine"
--       setvariable "secondsParm" to timeStamp
--       do script "_f_video_seek" 
--   end tell
--end run

--eval(
--    (function () {
--         console.log("abc");
--
--         console.log("Running video with parameter:", document.kmvar.seconds);
--         var secs = document.kmvar.seconds;
--         document.querySelector('video').currentTime = secs;
--         return(document.querySelector('video').currentTime);
--     }())
--)
--

on run timeStamp

   set jsMainCode to  "document.querySelector('video').currentTime = secs;\ndocument.querySelector('video').currentTime;\n"


   set jsCommand to "var secs = " & timeStamp & ¬
      ";\nconsole.log( 'set current time',secs );\n" & jsMainCode

   tell application "Google Chrome"
       execute front window's active tab javascript jsCommand
   end tell
end run



