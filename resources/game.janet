# a port of:
#
# https://github.com/raysan5/raylib-games/blob/master/classics/src/tetris.c

(import jaylib :as j)

###########################################################################

(def an-rng
  (math/rng)
  # XXX: wasn't playing well with wasm
  #'(math/rng (os/cryptorand 8))
  )

###########################################################################

(def square-size 20)

(def grid-x-size 12)

(def grid-y-size 20)

(def piece-dim 4)

(def lateral-speed 10)

(def turning-speed 12)

(def fast-fall-await-counter 30)

(def fading-time 33)

(def gravity-speed 30)

###########################################################################

(var state @{})

(var screen-width 800)

(var screen-height 450)

# 2-d array with dimensions grid-x-size x grid-y-size
#
# possibly values include:
#
# :empty  - space unoccupied
# :full   - occupied (by what was part of past piece)
# :moving - occupied by part of in-motion piece
# :block  - pre-filled space - left, right, or bottom edge
# :fading - about to be deleted / cleared
(var grid @[])

# 2-d array with dimensions piece-dim x piece-dim
#
# possible values include:
#
# :empty  - spot is empty
# :moving - spot is part of piece
(var piece @[])

# same structure and content as piece
(var future-piece @[])

# x-coordinate of top-left of "piece grid"
#
# "piece grid" is a piece-dim x piece-dim square of spots within the
# game grid.  the spots within the "piece grid" that represent the
# piece have the value :moving, while the other spots within the
# "piece grid" that are not occupied by the piece have the value
# :empty.
(var piece-pos-x 0)

# y-coordinate of top-left of "piece grid"
(var piece-pos-y 0)

###########################################################################

(var bgm nil)

(var bgm-volume 0.5)

###########################################################################

(defn get-random-piece
  []
  # empty out future-piece
  (loop [i :range [0 piece-dim]
         j :range [0 piece-dim]]
    (put-in future-piece [i j] :empty))
  #
  (def pieces
    [[[1 1] [2 1] [1 2] [2 2]]   # O
     [[1 0] [1 1] [1 2] [2 2]]   # L
     [[1 2] [2 0] [2 1] [2 2]]   # J
     [[0 1] [1 1] [2 1] [3 1]]   # I
     [[1 0] [1 1] [1 2] [2 1]]   # T
     [[1 1] [2 1] [2 2] [3 2]]   # Z
     [[1 2] [2 2] [2 1] [3 1]]]) # S
  # choose a random piece
  # XXX: docs say math/rng-int will return up through max, but only max - 1?
  (loop [a-unit :in (get pieces
                         (math/rng-int an-rng
                                       (+ (dec (length pieces)) 1)))]
    (put-in future-piece a-unit :moving)))

(defn create-piece
  [state]
  (set piece-pos-x
       (math/floor (/ (- grid-x-size 4)
                      2)))
  (set piece-pos-y 0)
  # create extra piece this one time
  (when (state :begin-play)
    (get-random-piece)
    (put state :begin-play false))
  # copy newly obtained future-piece to piece
  (loop [i :range [0 piece-dim]
         j :range [0 piece-dim]]
    (put-in piece [i j]
            (get-in future-piece [i j])))
  # get another future piece
  (get-random-piece)
  # put the piece in the grid
  (loop [i :range [piece-pos-x (+ piece-pos-x 4)]
         j :range [0 piece-dim]
         :when (= :moving
                  (get-in piece [(- i piece-pos-x) j]))]
    (put-in grid [i j] :moving))
  #
  state)

(defn resolve-falling-move
  [state]
  (if (state :detection)
    # stop the piece
    (loop [j :down-to [(- grid-y-size 2) 0]
           i :range [1 (dec grid-x-size)]
           :when (= :moving
                    (get-in grid [i j]))]
      (put-in grid [i j] :full)
      (put state :detection false)
      (put state :piece-active false))
    # move the piece down
    (do
      (loop [j :down-to [(- grid-y-size 2) 0]
             i :range [1 (dec grid-x-size)]
             :when (= :moving
                      (get-in grid [i j]))]
        (-> grid
            (put-in [i (inc j)] :moving)
            (put-in [i j] :empty)))
      (++ piece-pos-y)))
  state)

(defn left-blocked?
  []
  (var collision false)
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :range [1 (dec grid-x-size)]
         :when (and (= :moving
                       (get-in grid [i j]))
                    (or (zero? (dec i))
                        (= :full
                           (get-in grid [(dec i) j]))))]
    (set collision true)
    (break))
  collision)

(defn move-left
  []
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :range [1 (dec grid-x-size)]
         :when (= :moving
                  (get-in grid [i j]))]
    (-> grid
        (put-in [(dec i) j] :moving)
        (put-in  [i j] :empty)))
  (-- piece-pos-x))

(defn right-blocked?
  []
  (var collision false)
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :range [1 (dec grid-x-size)]
         :when (and (= :moving
                       (get-in grid [i j]))
                    (or (= (inc i)
                           (dec grid-x-size))
                        (= :full
                           (get-in grid [(inc i) j]))))]
    (set collision true)
    (break))
  collision)

(defn move-right
  []
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :down-to [(dec grid-x-size) 1]
         :when (= :moving
                  (get-in grid [i j]))]
    (-> grid
        (put-in [(inc i) j] :moving)
        (put-in [i j] :empty)))
  (++ piece-pos-x))

(defn resolve-lateral-move
  []
  (var collision true)
  #
  (cond
    (j/key-down? :a)
    (when (not (left-blocked?))
      (move-left)
      (set collision false))
    #
    (j/key-down? :d)
    (when (not (right-blocked?))
      (move-right)
      (set collision false)))
  #
  collision)

(defn blocked?
  [src dst]
  (and (= :moving (get-in grid src))
       (not= :empty (get-in grid dst))
       (not= :moving (get-in grid dst))))

(defn can-rotate?
  []
  (not
    (or (blocked? [(+ piece-pos-x 3) piece-pos-y]
                  [piece-pos-x piece-pos-y])
        (blocked? [(+ piece-pos-x 3) (+ piece-pos-y 3)]
                  [(+ piece-pos-x 3) piece-pos-y])
        (blocked? [piece-pos-x (+ piece-pos-y 3)]
                  [(+ piece-pos-x 3) (+ piece-pos-y 3)])
        (blocked? [piece-pos-x piece-pos-y]
                  [piece-pos-x (+ piece-pos-y 3)])
        (blocked? [(+ piece-pos-x 1) piece-pos-y]
                  [piece-pos-x (+ piece-pos-y 2)])
        (blocked? [(+ piece-pos-x 3) (+ piece-pos-y 1)]
                  [(+ piece-pos-x 1) piece-pos-y])
        (blocked? [(+ piece-pos-x 2) (+ piece-pos-y 3)]
                  [(+ piece-pos-x 3) (+ piece-pos-y 1)])
        (blocked? [piece-pos-x (+ piece-pos-y 2)]
                  [(+ piece-pos-x 2) (+ piece-pos-y 3)])
        (blocked? [(+ piece-pos-x 2) piece-pos-y]
                  [piece-pos-x (+ piece-pos-y 1)])
        (blocked? [(+ piece-pos-x 3) (+ piece-pos-y 2)]
                  [(+ piece-pos-x 2) piece-pos-y])
        (blocked? [(+ piece-pos-x 1) (+ piece-pos-y 3)]
                  [(+ piece-pos-x 3) (+ piece-pos-y 2)])
        (blocked? [piece-pos-x (+ piece-pos-y 1)]
                  [(+ piece-pos-x 1) (+ piece-pos-y 3)])
        (blocked? [(+ piece-pos-x 1) (+ piece-pos-y 1)]
                  [(+ piece-pos-x 1) (+ piece-pos-y 2)])
        (blocked? [(+ piece-pos-x 2) (+ piece-pos-y 1)]
                  [(+ piece-pos-x 1) (+ piece-pos-y 1)])
        (blocked? [(+ piece-pos-x 2) (+ piece-pos-y 2)]
                  [(+ piece-pos-x 2) (+ piece-pos-y 1)])
        (blocked? [(+ piece-pos-x 1) (+ piece-pos-y 2)]
                  [(+ piece-pos-x 2) (+ piece-pos-y 2)]))))

(defn rotate-ccw
  []
  (defn left-rotate-units
    [positions]
    (var aux (get-in piece (first positions)))
    (loop [i :range [0 (dec (length positions))]]
      (put-in piece (get positions i)
              (get-in piece (get positions (inc i)))))
    (put-in piece (last positions) aux))
  #
  (left-rotate-units [[0 0] [3 0] [3 3] [0 3]])
  (left-rotate-units [[1 0] [3 1] [2 3] [0 2]])
  (left-rotate-units [[2 0] [3 2] [1 3] [0 1]])
  (left-rotate-units [[1 1] [2 1] [2 2] [1 2]]))

(defn resolve-turn-move
  []
  (when (j/key-down? :w)
    # rotate piece counterclockwise if appropriate
    (when (can-rotate?)
      (rotate-ccw))
    # clear grid spots occupied that were occupied by piece
    (loop [j :down-to [(- grid-y-size 2) 0]
           i :range [1 (dec grid-x-size)]
           :when (= :moving
                    (get-in grid [i j]))]
      (put-in grid [i j] :empty))
    # fill grid spots that the piece occupies
    (loop [i :range [piece-pos-x (+ piece-pos-x 4)]
           j :range [piece-pos-y (+ piece-pos-y 4)]
           :when (= :moving
                    (get-in piece
                            [(- i piece-pos-x) (- j piece-pos-y)]))]
      (put-in grid [i j] :moving))
    #
    (break true))
  #
  false)

(defn check-detection
  [state]
  # check if there is even one spot below the current line that a piece
  # cannot be moved into (i.e. :full or :block)
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :range [1 (dec grid-x-size)]
         :when (and (= :moving
                       (get-in grid [i j]))
                    (or (= :full
                           (get-in grid [i (inc j)]))
                        (= :block
                           (get-in grid [i (inc j)]))))]
    (put state :detection true))
  state)

(defn check-completion
  [state]
  (var calculator 0)
  # determine if any lines need to be deleted
  (loop [j :down-to [(- grid-y-size 2) 0]]
    (set calculator 0)
    # count spots that are occupied by stationary blocks (i.e. :full)
    (loop [i :range [1 (dec grid-x-size)]]
      (when (= :full
               (get-in grid [i j]))
        (++ calculator))
      # if appropriate, mark spots that need to be deleted and remember
      # that at least one line needs to be deleted
      (when (= (- grid-x-size 2)
               calculator)
        (put state :line-to-delete true)
        (set calculator 0)
        (loop [z :range [1 (dec grid-x-size)]]
          (put-in grid [z j] :fading)))))
  state)

(defn delete-complete-lines
  []
  # start at the bottom row (above the bottom :block row) and work way upward
  (loop [j :down-to [(- grid-y-size 2) 0]]
    # if left-most spot is :fading, whole row is
    (while (= :fading
              (get-in grid [1 j]))
      # delete the current row by marking all spots in it :empty
      (loop [i :range [1 (dec grid-x-size)]]
        (put-in grid [i j] :empty))
      # shift all rows above down by one appropriately
      (loop [j2 :down-to [(dec j) 0]
             i2 :range [1 (dec grid-x-size)]]
        (case (get-in grid [i2 j2])
          :full
          (-> grid
              (put-in [i2 (inc j2)] :full)
              (put-in [i2 j2] :empty))
          #
          :fading
          (-> grid
              (put-in [i2 (inc j2)] :fading)
              (put-in [i2 j2] :empty)))))))

(defn init-grid
  [a-grid]
  (loop [i :range [0 grid-x-size]
         :before (put a-grid i (array/new grid-y-size))
         j :range [0 grid-y-size]]
    (if (or (= i 0)
            (= i (dec grid-x-size))
            (= j (dec grid-y-size)))
      # pre-fill left, right, and bottom edges of the grid
      (put-in a-grid [i j] :block)
      # all other spots are :empty
      (put-in a-grid [i j] :empty)))
  a-grid)

(defn init-piece
  [a-piece]
  # mark all spots in a-piece :empty
  (loop [i :range [0 piece-dim]
         :before (put a-piece i (array/new piece-dim))
         j :range [0 grid-x-size]]
    (put-in a-piece [i j] :empty))
  a-piece)

(defn init-game
  [state]
  (set piece-pos-x 0)
  (set piece-pos-y 0)
  (set grid (init-grid grid))
  (set future-piece (init-piece future-piece))
  (put state :game-over false)
  (put state :pause false)
  (put state :begin-play true)
  (put state :piece-active false)
  (put state :fading-color :gray)
  # whether any lines need to be deleted
  (put state :line-to-delete false)
  # number of lines deleted so far
  (put state :lines 0)
  (put state :detection false)
  (put state :gravity-move-counter 0)
  (put state :lateral-move-counter 0)
  (put state :turn-move-counter 0)
  (put state :fast-fall-move-counter 0)
  (put state :fade-line-counter 0)
  state)

(defn toggle-mute
  []
  (if (zero? bgm-volume)
    (set bgm-volume 0.5)
    (set bgm-volume 0))
  (j/set-music-volume bgm bgm-volume))

(defn toggle-pause
  [state]
  (put state :pause (not (state :pause)))
  (if (state :pause)
    (j/pause-music-stream bgm)
    (j/resume-music-stream bgm))
  state)

(defn handle-line-deletion
  [state]
  (++ (state :fade-line-counter))
  (if (< (% (state :fade-line-counter) 8) 4)
    (put state :fading-color :maroon)
    (put state :fading-color :gray))
  (when (>= (state :fade-line-counter) fading-time)
    (delete-complete-lines)
    (put state :fade-line-counter 0)
    (put state :line-to-delete false)
    (++ (state :lines)))
  #
  state)

(defn handle-active-piece
  [state]
  (++ (state :fast-fall-move-counter))
  (++ (state :gravity-move-counter))
  (++ (state :lateral-move-counter))
  (++ (state :turn-move-counter))
  # arrange for move if necessary
  (when (or (j/key-pressed? :a)
            (j/key-pressed? :d))
    (put state :lateral-move-counter lateral-speed))
  (when (j/key-pressed? :w)
    (put state :turn-move-counter turning-speed))
  # fall?
  (when (and (j/key-down? :s)
             (>= (state :fast-fall-move-counter)
                 fast-fall-await-counter))
    (+= (state :gravity-move-counter) gravity-speed))
  (when (>= (state :gravity-move-counter) gravity-speed)
    # falling
    (check-detection state)
    # collision?
    (resolve-falling-move state)
    # any lines completed?
    (check-completion state)
    (put state :gravity-move-counter 0))
  # sideways move
  (when (>= (state :lateral-move-counter) lateral-speed)
    (when (not (resolve-lateral-move))
      (put state :lateral-move-counter 0)))
  # turning
  (when (>= (state :turn-move-counter) turning-speed)
    (when (resolve-turn-move)
      (put state :turn-move-counter 0)))
  #
  state)

(defn init-active-piece
  [state]
  (create-piece state)
  (put state :piece-active true)
  (put state :fast-fall-move-counter 0)
  state)

(defn check-game-over
  [state]
  (loop [j :range [0 2] # XXX: 2?
         i :range [1 (dec grid-x-size)]
         :when (= :full
                  (get-in grid [i j]))]
    (put state :game-over true)
    (break))
  state)

(defn update-game
  [state]
  (when (state :game-over)
    (when (j/key-pressed? :enter)
      (init-game state))
    (break state))
  #
  (when (j/key-pressed? :m)
    (toggle-mute))
  #
  (when (j/key-pressed? :p)
    (toggle-pause state))
  #
  (when (state :pause)
    (break state))
  #
  (when (state :line-to-delete)
    (handle-line-deletion state)
    (break state))
  #
  (if (state :piece-active)
    (handle-active-piece state)
    (init-active-piece state))
  #
  (check-game-over state)
  state)

(defn draw-grid
  [state]
  (var offset-x
    (- (/ screen-width 2)
       (* grid-x-size (/ square-size 2))
       50))
  (var offset-y
    (- (/ screen-height 2)
       (+ (* (dec grid-y-size) (/ square-size 2))
          (* square-size 2))
       50))
  (var controller offset-x)
  # draw grid
  (for j 0 grid-y-size
    (for i 0 grid-x-size
      (case (get-in grid [i j])
        :empty
        (do # outline of square
          (j/draw-line offset-x offset-y
                       (+ offset-x square-size) offset-y
                       :light-gray)
          (j/draw-line offset-x offset-y
                       offset-x (+ offset-y square-size)
                       :light-gray)
          (j/draw-line (+ offset-x square-size) offset-y
                       (+ offset-x square-size) (+ offset-y square-size)
                       :light-gray)
          (j/draw-line offset-x (+ offset-y square-size)
                       (+ offset-x square-size) (+ offset-y square-size)
                       :light-gray))
        #
        :full
        (j/draw-rectangle offset-x offset-y
                          square-size square-size :black)
        #
        :moving
        (j/draw-rectangle offset-x offset-y
                          square-size square-size :dark-gray)
        #
        :block
        (j/draw-rectangle offset-x offset-y
                          square-size square-size :light-gray)
        #
        :fading
        (j/draw-rectangle offset-x offset-y
                          square-size square-size
                          (state :fading-color))
        #
        (eprintf "Unexpected value: %p at %p, %p"
                 (get-in grid [i j]) i j))
      (+= offset-x square-size))
    (set offset-x controller)
    (+= offset-y square-size))
  #
  state)

(defn draw-info-box
  [state x y]
  (var offset-x x)
  (var offset-y y)
  (var controller offset-x)
  # draw future piece
  (for j 0 piece-dim
    (for i 0 piece-dim
      (case (get-in future-piece [i j])
        :empty
        (do
          (j/draw-line offset-x offset-y
                       (+ offset-x square-size) offset-y
                       :light-gray)
          (j/draw-line offset-x offset-y
                       offset-x (+ offset-y square-size)
                       :light-gray)
          (j/draw-line (+ offset-x square-size) offset-y
                       (+ offset-x square-size) (+ offset-y square-size)
                       :light-gray)
          (j/draw-line offset-x (+ offset-y square-size)
                       (+ offset-x square-size) (+ offset-y square-size)
                       :light-gray)
          (+= offset-x square-size))
        #
        :moving
        (do
          (j/draw-rectangle offset-x offset-y
                            square-size square-size :gray)
          (+= offset-x square-size))))
    (set offset-x controller)
    (+= offset-y square-size))
  # label future piece box
  (j/draw-text "UPCOMING:"
               offset-x (- offset-y 100)
               10 :gray)
  # show how many lines completed so far
  (j/draw-text (string/format "LINES:      %04i" (state :lines))
               offset-x (+ offset-y 20)
               10 :gray)
  # XXX: or return state or?
  [offset-x offset-y])

(defn draw-pause-overlay
  []
  (let [message "GAME PAUSED"]
    (j/draw-text message
                 (- (/ screen-width 2)
                    (/ (j/measure-text message 40)
                       2))
                 (- (/ screen-height 2)
                    40)
                 40 :gray)))

(defn draw-play-again-overlay
  []
  (let [message "PRESS [ENTER] TO PLAY AGAIN"]
    # XXX: why are get-screen-width and get-screen-height used here
    #      when they are not in draw-grid and draw-pause-overlay?
    (j/draw-text message
                 (- (/ (j/get-screen-width) 2)
                    (/ (j/measure-text message 20)
                       2))
                 (- (/ (j/get-screen-height) 2)
                    50)
                 20 :gray)))

(defn draw-game
  [state]
  (j/begin-drawing)
  #
  (j/clear-background :dark-green)
  #
  (if (state :game-over)
    (draw-play-again-overlay)
    (do
      (draw-grid state)
      (draw-info-box state 500 45) # XXX: hard-coded
      # show pause overlay when appropriate
      (when (state :pause)
        (draw-pause-overlay))))
  #
  (j/end-drawing)
  state)

(defn update-draw-frame
  []
  # XXX
  (when (zero? (mod (dyn :frame) 1000))
    (let [d (os/date (os/time) true)]
      (printf "%02d:%02d:%02d - %p"
              (d :hours) (d :minutes) (d :seconds) (dyn :frame))))
  (setdyn :frame (inc (dyn :frame)))
  (when bgm
    (j/update-music-stream bgm))
  (-> state
      update-game
      draw-game))

(defn desktop
  []
  (j/set-config-flags :msaa-4x-hint)
  (j/set-target-fps 60))

# now that a loop is not being done in janet, this needs to
# happen
(j/init-window screen-width screen-height "Jaylib Demo")

(j/init-audio-device)
(set bgm (j/load-music-stream "resources/theme.ogg"))
(j/play-music-stream bgm)
(j/set-music-volume bgm bgm-volume)

(set state
     (init-game state))

# XXX
(setdyn :frame 0)

# this fiber is used repeatedly by the c code, partly to maintain
# dynamic variables (as those are per-fiber), but also because reusing
# a fiber with a function is likely faster than parsing and compiling
# code each time the game loop performs one iteration
(def main-fiber
  (fiber/new
    (fn []
      # XXX: this content only gets used when main.c uses janet_continue
      (while (not (window-should-close))
        (printf "frame: %p" (dyn :frame))
        (setdyn :frame (inc (dyn :frame)))
        (update-draw-frame)
        (yield)))
    # important for inheriting existing dynamic variables
    :i))

# XXX: original code
'(defn main
  [& args]
  #
  (j/set-config-flags :msaa-4x-hint)
  (j/init-window screen-width screen-height "Jaylib Demo")
  (j/set-target-fps 60)
  #
  (j/set-exit-key 0)
  #
  (init-game state)
  #
  (while (not (j/window-should-close))
    (update-draw-frame))
  #
  (j/close-window))

