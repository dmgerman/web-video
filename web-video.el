;;

;; How to use:
;;    frontmost active window should contain a player in an "active" state (once the
;     video timeouts these functions will not work)
;;
;;  provides the following interactive functions:
;;
;;   web-video-insert-url-title   -- insert the url and title of the current window
;;   web-video-insert-time-pos    -- insert the current time being played
;;   web-video-seek               -- seek the video to the timestamp below the cursor (does not work with Disney+)
;;   web-video-play-subtitle      -- play a subtitle, stopping video at end of subtitle entry
;;   web-subtitles-sync-to-video  -- tries to find in the current buffer the closest subtitle before current time
;;
;; Limitations:
;;   - they require several scripts to interact with the browser (see under scripts)
;;     currently these scripts using AppleScript thus they only work under osx.
;;     patches wanted for linux and/or windows
;;   - works only with the first video in a page.
;;     seems to work youtube, netflix, amazon prime, and Disney+ (see warning below)
;;
;; 
;; Warning. seeking functions do not work with disney plus. There is a buffering
;;   issue if the location is not within the currently loaded buffer
;;

;; Installation:
;;     install the scripts under scripts somewhere and set variables below accordingly using setq

;; subtitle format
;;
;; subtitles look like this
;;
;;1
;;00:00:00,650 --> 00:00:03,070
;;is 2弾

;;2
;;00:00:03,070 --> 00:00:05,400
;;覚醒ですか

;;    note that the fractions are in European format (, instead of .)



(require 'cl)

(defvar web-video-subtitle-padding-front 0.3
  "when playing a subtitle, subtract these seconds before the actual start time")
(defvar web-video-subtitle-padding-back 0.3
  "when playing a subtitle, add these seconds to end of subtitle time")

(defvar web-video-subtitle-offset 0.0
  "when the subtitle is not perfectly synchronized this time by this number of seconds")

(defvar web-video-url-and-title-command "/some-path/somewhere/video-url-title.sh"
  "path to script to get url and title of currently played video"
  )


(defvar web-video-seek-and-play-command "/some-path/somewhere/video-seek-and-play.sh"
  "path to script to seek and play video: takes two parms: offset to play (in seconds) and how long to play for (seconds)"
  )

(defvar web-video-seek-command "/some-path/somewhere/video-seek.sh"
  "path to script to seek video, takes one parameter, in seconds"
  )
(defvar web-video-position-command "/some-path/somewhere/video-position.sh"
  "seek to a given position. Parameter is in seconds"
  )

(defvar web-video-url-title-format "[[%s][%s]]"
  "format to insert url title and format, defaults to org-mode"
  )


(defvar web-video-url-position "/some-path/somewhere/video-url-position.scpt"
  "return the current url with position"
  )

(defun web-verify-script (pathExec)
  (unless (executable-find pathExec)
    (error (format "executable %s does not exist" pathExec))
    )
  pathExec
  )

(defun web-extract-timestamp-under-point ()
  "extract the time under the point, in the format of subtitles: hh:mm:ss,frac
  Any part is optinnal, except for seconds
"
    (let* (
          (mid (point))
          (end (re-search-forward "[^0-9:,]" (+ 20 mid) ) )
          (beg (and end
                    (goto-char mid)
                    (re-search-backward "[^0-9:,]" (+ -15 mid) )))
          (st (and beg
               (buffer-substring-no-properties (+ beg 1) (+ end -1))))
          )
      (when (< (length st)  2);
        (error (format "invalid timestamp under point [%s] [%d]" st (length st))
               ))
      (message "Timestamp [%s]" st)
      st)
    )

;;convert a timestamp into seconds, since the browser uses seconds
(defun web-timestamp-to-seconds (time-string)
  "Converts a time string in the subtitle format to seconds"
  (when (not (string-match-p "^[0-9:]+\\(,[0-9]+\\)?$" time-string))
    (error (format "invalid timestamp [%s]" time-string)))
  (let* ((parts (split-string time-string "[,]"))
         (time-part (nth 0 parts))
         (frac-part (nth 1 parts))
         (frac-secs (if frac-part
                        (string-to-number (concat "0." frac-part))
                      0
                      ))
         (time-parts (mapcar 'string-to-number (split-string time-part ":")))
         (num-parts (length time-parts))
         (seconds     (cond
                       ((= num-parts 1) ; if there's only one part, assume it's seconds
                        (nth 0 time-parts))
                       ((= num-parts 2) ; if there are two parts, assume it's minutes and seconds
                        (+ (* (nth 0 time-parts) 60) (nth 1 time-parts)))
                       ((= num-parts 3) ; if there are three parts, assume it's hours, minutes, and seconds
                        (+ (* (nth 0 time-parts) 3600) (* (nth 1 time-parts) 60) (nth 2 time-parts)))
                       (t (error (format "Illegal time [%s]" time-string)
                                 )))
                      )
         (result (+ seconds frac-secs))
         )
    (message "parts [%s] [%s] [%s]" time-part frac-part result)
    result
    ));

;;extract the subtitle entry times. Returns a pair of seconds

(defun web-get-subtitle-entry-time ()
  "return a pair with the beg and end time (in seconds) of the current subtitle"
  (save-excursion
    ; assumes we are in the first time of the range
    (let* (
           (start (web-extract-timestamp-under-point))
           )
      ;; move to the end of the time
      (goto-char (+ 1 (point) (length start)))
      (unless (looking-at-p " --> ")
        (error (format "this is not a subtitle entry [%s] [%s]"
                 start
                 (buffer-substring-no-properties (point) (+ (point) 10))
                )
               )
        )
      ;; skip arrow
      (goto-char (+ (point) 5))
      ;; extract second timestamp
      (let (
             (end (web-extract-timestamp-under-point))
            )
         (cons (web-timestamp-to-seconds start) (web-timestamp-to-seconds end))
         )
       )
      )
    )


(defun web-video-insert-url-position ()
  (interactive)
  (let (
        (url
         (shell-command-to-string
          (web-verify-script web-video-url-position)
          ))
        )
    (insert url)
 ))


(defun web-video-url-title ()
  "return a pair with the title and url of the currently played video"
  (let* (
         (retval (shell-command-to-string
                  (web-verify-script web-video-url-and-title-command)
                  ))
         (sep    (and retval
                      (search ";;" retval)))
         (url    (and sep
                      (substring retval 0 sep)
                      ))
         (title (and sep
                     (substring retval (+ sep 2) -3)
                     ))
         )
    (when (and url ;; find semi)
               )
      (message "found [%s] [%s]" url title)
      (cons url title)
      )
    )
  )


(defun web-video-insert-url-title ()
  "insert the url and title of the video at point"
  (interactive)
  (let* (
         (url-title (web-video-url-title))
         )
    (when url-title
      (insert (format web-video-url-title-format (car url-title) (cdr url-title)))
      )
    )
  )

;; current time of video
;;Return the time (in timestamp format) in which the current video is playing

(defun web-video-time-pos ()
  "return the offset of current video being played"
  (save-excursion
    (let* (
           (timeSt
            (replace-regexp-in-string
             "\n$" "" 
             (shell-command-to-string
              (web-verify-script web-video-position-command)
              )))
           (time   (and
                    timeSt
                    (- (string-to-number timeSt) web-video-subtitle-offset)))
          )
      (message "position of video [%s] [%s]" timeSt time)
      (unless (> time 0)
        (error (format "invalid time from video. perhaps not front-most window? [%s] [%s]" timeSt time))
        )
      (format "%02d:%02d:%02d" (/ time 3600) (/ (mod time 3600) 60) (mod time 60))
      )
    )
  )

(defun web-video-insert-time-pos ()
  "insert offset of currently played video at point"
  (interactive)
  (insert (web-video-time-pos))
  )


;; Play at a position given by timestamp at point
;; TODO: improve it to interactively provide time, if not on timestamp

(defun web-video-seek ()
  "seek currently played video the current timestamp"
  (interactive )
  (save-excursion
    (let* (
           (st (web-extract-timestamp-under-point))
           (secs (+ (web-timestamp-to-seconds st) web-video-subtitle-offset
                    ))
          )
      (shell-command-to-string (format "'%s' '%s'"
                                       (web-verify-script web-video-seek-command)
                                       secs))
      )
    )
  )


;; Play a given subtitle

;; Starts playing at beginning time of subtitle
;;- Stops at end of subtitle
;; Pads the subtitle front and back

(defun web-video-play-subtitle ()
  (interactive)
  (let* (
         (times (web-get-subtitle-entry-time))
         (starttime (+ (car times) web-video-subtitle-offset))
         (from  (- starttime web-video-subtitle-padding-front))
         (secs  (+ (cdr times) (- starttime) web-video-subtitle-padding-back))
         )
    (shell-command-to-string
     (format "'%s' '%s' '%s'"
             (web-verify-script web-video-seek-and-play-command) from secs))
    )
  )

;;  Find time stamp within the current buffer.
;; The line must start with a prefix of the currently played video

;; TODO: this is not ideal, but it was easy to implement

(defun web-subtitles-sync-to-video ()
  "set point relatively close to subtitle of current time of video"
  (interactive)
  (defun find-position ()
    (save-excursion
          (let* (
                (timeSt (web-video-time-pos))
                (offset (concat "^" timeSt))  ;
                (pos    nil)
                )
            ;; match at least to the first colon
            (while (and (not pos)
                        (> (length offset) 3))
              ;; try to match string
              (goto-char (point-min))
              (setq pos (re-search-forward offset nil t))
              (if (not pos)
                  ;; shorten the string by one char
                  (setq offset (substring offset 0 -1))
                )
               (message "Pos [%s] offset [%s]" pos offset)
              )
            (when (not pos)
              (error "time [%s] not found" timeSt))
            ;; adjust for end of match
            (- pos (length offset) -1)
            )
          )
    )
   (let (
         (pos (find-position))
        )
     (when pos
       (goto-char pos)
       (recenter)
       )
     )
   )

(provide 'web-video)
