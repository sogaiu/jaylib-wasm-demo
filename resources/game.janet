# a port of:
#
# https://github.com/raysan5/raylib-games/blob/master/classics/src/tetris.c

###########################################################################

(import jaylib :as j)
(import ./params :as p)
(import ./state :as s)
(import ./draw :as d)
(import ./update :as u)

(defn update-draw-frame!
  [state]
  # XXX
  (when (zero? (mod (dyn :frame) 1000))
    (let [d (os/date (os/time) true)]
      (printf "%02d:%02d:%02d - %p"
              (d :hours) (d :minutes) (d :seconds) (dyn :frame))))
  (setdyn :frame (inc (dyn :frame)))
  #
  (when-let [bgm (state :bgm)]
    (j/update-music-stream bgm))
  #
  (-> state
      u/update-game!
      d/draw-game))

(defn desktop
  []
  (j/set-config-flags :msaa-4x-hint)
  (j/set-target-fps 60))

# filled in via common-startup
(var update-draw-frame nil)

# filled in via common-startup
(var main-fiber nil)

(defn common-startup
  []
  (var state @{})
  #
  (s/init! state)
  #
  (j/init-window p/screen-width p/screen-height "Jaylib Demo")
  #
  (j/init-audio-device)
  (put state :bgm (j/load-music-stream "resources/theme.ogg"))
  (j/play-music-stream (state :bgm))
  (j/set-music-volume (state :bgm) (state :bgm-volume))
  # to facilitate calling from main.c
  (set update-draw-frame
       |(update-draw-frame! state))
  # XXX
  (setdyn :frame 0)
  # this fiber is used repeatedly by the c code, partly to maintain
  # dynamic variables (as those are per-fiber), but also because reusing
  # a fiber with a function is likely faster than parsing and compiling
  # code each time the game loop performs one iteration
  (set main-fiber
       (fiber/new
         (fn []
           # XXX: this content only gets used when main.c uses janet_continue
           (while (not (window-should-close))
             (update-draw-frame! state)
             (yield)))
         # important for inheriting existing dynamic variables
         :i)))

