# a port of:
#
# https://github.com/raysan5/raylib-games/blob/master/classics/src/tetris.c

###########################################################################

(import jaylib :as j)
(import ./params :as p)
(import ./draw :as d)
(import ./state :as s)

###########################################################################

(def an-rng
  (math/rng)
  # XXX: wasn't playing well with wasm
  #'(math/rng (os/cryptorand 8))
  )

###########################################################################

(defn get-random-piece!
  [state]
  # empty out future-piece
  (loop [i :range [0 p/piece-dim]
         j :range [0 p/piece-dim]]
    (put-in state [:future-piece i j] :empty))
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
    (put-in state [:future-piece ;a-unit] :moving))
  #
  state)

(defn create-piece!
  [state]
  (put state :piece-pos-x
       (math/floor (/ (- p/grid-x-size 4)
                      2)))
  (put state :piece-pos-y 0)
  # create extra piece this one time
  (when (state :begin-play)
    (get-random-piece! state)
    (put state :begin-play false))
  # copy newly obtained future-piece to piece
  (loop [i :range [0 p/piece-dim]
         j :range [0 p/piece-dim]]
    (put-in state [:piece i j]
            (get-in state [:future-piece i j])))
  # get another future piece
  (get-random-piece! state)
  # put the piece in the grid
  (def piece-pos-x (state :piece-pos-x))
  (loop [i :range [piece-pos-x (+ piece-pos-x 4)]
         j :range [0 p/piece-dim]
         :when (= :moving
                  (get-in state [:piece (- i piece-pos-x) j]))]
    (put-in state [:grid i j] :moving))
  #
  state)

(defn resolve-falling-move!
  [state]
  (def grid (state :grid))
  #
  (if (state :detection)
    # stop the piece
    (loop [j :down-to [(- p/grid-y-size 2) 0]
           i :range [1 (dec p/grid-x-size)]
           :when (= :moving
                    (get-in grid [i j]))]
      (put-in grid [i j] :full)
      (put state :detection false)
      (put state :piece-active false))
    # move the piece down
    (do
      (loop [j :down-to [(- p/grid-y-size 2) 0]
             i :range [1 (dec p/grid-x-size)]
             :when (= :moving
                      (get-in grid [i j]))]
        (put-in grid [i (inc j)] :moving)
        (put-in grid [i j] :empty))
      (++ (state :piece-pos-y))))
  #
  state)

(defn left-blocked?
  [state]
  (var collision false)
  (loop [j :down-to [(- p/grid-y-size 2) 0]
         i :range [1 (dec p/grid-x-size)]
         :let [grid (state :grid)]
         :when (and (= :moving
                       (get-in grid [i j]))
                    (or (zero? (dec i))
                        (= :full
                           (get-in grid [(dec i) j]))))]
    (set collision true)
    (break))
  (put state :result collision)
  #
  state)

(defn move-left!
  [state]
  (loop [j :down-to [(- p/grid-y-size 2) 0]
         i :range [1 (dec p/grid-x-size)]
         :let [grid (state :grid)]
         :when (= :moving
                  (get-in grid [i j]))]
    (put-in grid [(dec i) j] :moving)
    (put-in grid [i j] :empty))
  (-- (state :piece-pos-x))
  #
  state)

(defn right-blocked?
  [state]
  (var collision false)
  (loop [j :down-to [(- p/grid-y-size 2) 0]
         i :range [1 (dec p/grid-x-size)]
         :let [grid (state :grid)]
         :when (and (= :moving
                       (get-in grid [i j]))
                    (or (= (inc i)
                           (dec p/grid-x-size))
                        (= :full
                           (get-in grid [(inc i) j]))))]
    (set collision true)
    (break))
  (put state :result collision)
  #
  state)

(defn move-right!
  [state]
  (loop [j :down-to [(- p/grid-y-size 2) 0]
         i :down-to [(dec p/grid-x-size) 1]
         :let [grid (state :grid)]
         :when (= :moving
                  (get-in grid [i j]))]
    (put-in grid [(inc i) j] :moving)
    (put-in grid [i j] :empty))
  (++ (state :piece-pos-x))
  #
  state)

(defn resolve-lateral-move!
  [state]
  (var collision true)
  #
  (cond
    (j/key-down? :a)
    (when (not ((left-blocked? state) :result))
      (move-left! state)
      (set collision false))
    #
    (j/key-down? :d)
    (when (not ((right-blocked? state) :result))
      (move-right! state)
      (set collision false)))
  #
  (put state :result collision)
  #
  state)

(defn can-rotate?
  [state]
  (def grid (state :grid))
  (defn blocked?
    [src dst]
    (and (= :moving (get-in grid src))
         (not= :empty (get-in grid dst))
         (not= :moving (get-in grid dst))))
  #
  (def piece-pos-x (state :piece-pos-x))
  (def piece-pos-y (state :piece-pos-y))
  #
  (put state :result
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
  #
  state)

(defn rotate-ccw!
  [state]
  (defn left-rotate-units
    [positions]
    (var aux
      (get-in state [:piece ;(first positions)]))
    (loop [i :range [0 (dec (length positions))]]
      (put-in state [:piece ;(get positions i)]
              (get-in state [:piece ;(get positions (inc i))])))
    (put-in state [:piece ;(last positions)] aux))
  #
  (left-rotate-units [[0 0] [3 0] [3 3] [0 3]])
  (left-rotate-units [[1 0] [3 1] [2 3] [0 2]])
  (left-rotate-units [[2 0] [3 2] [1 3] [0 1]])
  (left-rotate-units [[1 1] [2 1] [2 2] [1 2]])
  #
  state)

(defn resolve-turn-move!
  [state]
  (var result false)
  (def grid (state :grid))
  #
  (when (j/key-down? :w)
    # rotate piece counterclockwise if appropriate
    (when ((can-rotate? state) :result)
      (rotate-ccw! state))
    # clear grid spots occupied that were occupied by piece
    (loop [j :down-to [(- p/grid-y-size 2) 0]
           i :range [1 (dec p/grid-x-size)]
           :when (= :moving
                    (get-in grid [i j]))]
      (put-in grid [i j] :empty))
    # fill grid spots that the piece occupies
    (def piece-pos-x (state :piece-pos-x))
    (def piece-pos-y (state :piece-pos-y))
    (loop [i :range [piece-pos-x (+ piece-pos-x 4)]
           j :range [piece-pos-y (+ piece-pos-y 4)]
           :when (= :moving
                    (get-in state
                            [:piece (- i piece-pos-x) (- j piece-pos-y)]))]
      (put-in grid [i j] :moving))
    #
    (set result true))
  #
  (put state :result result)
  #
  state)

(defn check-detection!
  [state]
  # check if there is even one spot below the current line that a piece
  # cannot be moved into (i.e. :full or :block)
  (loop [j :down-to [(- p/grid-y-size 2) 0]
         i :range [1 (dec p/grid-x-size)]
         :let [grid (state :grid)]
         :when (and (= :moving
                       (get-in grid [i j]))
                    (or (= :full
                           (get-in grid [i (inc j)]))
                        (= :block
                           (get-in grid [i (inc j)]))))]
    (put state :detection true))
  #
  state)

(defn check-completion!
  [state]
  (var calculator 0)
  # determine if any lines need to be deleted
  (loop [j :down-to [(- p/grid-y-size 2) 0]
         :let [grid (state :grid)]]
    (set calculator 0)
    # count spots that are occupied by stationary blocks (i.e. :full)
    (loop [i :range [1 (dec p/grid-x-size)]]
      (when (= :full
               (get-in grid [i j]))
        (++ calculator))
      # if appropriate, mark spots that need to be deleted and remember
      # that at least one line needs to be deleted
      (when (= (- p/grid-x-size 2)
               calculator)
        (put state :line-to-delete true)
        (set calculator 0)
        (loop [z :range [1 (dec p/grid-x-size)]]
          (put-in grid [z j] :fading)))))
  state)

(defn delete-complete-lines!
  [state]
  (var n-lines 0)
  # start at the bottom row (above the bottom :block row) and work way upward
  (loop [j :down-to [(- p/grid-y-size 2) 0]
         :let [grid (state :grid)]]
    # if left-most spot is :fading, whole row is
    (while (= :fading
              (get-in grid [1 j]))
      # delete the current row by marking all spots in it :empty
      (loop [i :range [1 (dec p/grid-x-size)]]
        (put-in grid [i j] :empty))
      # count each deleted line
      (++ n-lines)
      # shift all rows above down by one appropriately
      (loop [j2 :down-to [(dec j) 0]
             i2 :range [1 (dec p/grid-x-size)]]
        (case (get-in grid [i2 j2])
          :full
          (-> grid
              (put-in [i2 (inc j2)] :full)
              (put-in [i2 j2] :empty))
          #
          :fading
          (-> grid
              (put-in [i2 (inc j2)] :fading)
              (put-in [i2 j2] :empty))))))
  #
  (put state :result n-lines)
  #
  state)

(defn toggle-mute!
  [state]
  (if (zero? (state :bgm-volume))
    (put state :bgm-volume 0.5)
    (put state :bgm-volume 0))
  (j/set-music-volume (state :bgm) (state :bgm-volume))
  #
  state)

(defn toggle-pause!
  [state]
  (put state :pause (not (state :pause)))
  (if (state :pause)
    (j/pause-music-stream (state :bgm))
    (j/resume-music-stream (state :bgm)))
  #
  state)

(defn handle-line-deletion!
  [state]
  (++ (state :fade-line-counter))
  (if (< (% (state :fade-line-counter) 8) 4)
    (put state :fading-color :maroon)
    (put state :fading-color :gray))
  (when (>= (state :fade-line-counter) p/fading-time)
    (def n-lines
      ((delete-complete-lines! state) :result))
    (put state :fade-line-counter 0)
    (put state :line-to-delete false)
    (+= (state :lines) n-lines))
  #
  state)

(defn handle-active-piece!
  [state]
  (++ (state :fast-fall-move-counter))
  (++ (state :gravity-move-counter))
  (++ (state :lateral-move-counter))
  (++ (state :turn-move-counter))
  # arrange for move if necessary
  (when (or (j/key-pressed? :a)
            (j/key-pressed? :d))
    (put state :lateral-move-counter p/lateral-speed))
  (when (j/key-pressed? :w)
    (put state :turn-move-counter p/turning-speed))
  # fall?
  (when (and (j/key-down? :s)
             (>= (state :fast-fall-move-counter)
                 p/fast-fall-await-counter))
    (+= (state :gravity-move-counter) p/gravity-speed))
  (when (>= (state :gravity-move-counter) p/gravity-speed)
    # falling
    (check-detection! state)
    # collision?
    (resolve-falling-move! state)
    # any lines completed?
    (check-completion! state)
    (put state :gravity-move-counter 0))
  # sideways move
  (when (>= (state :lateral-move-counter) p/lateral-speed)
    (when (not ((resolve-lateral-move! state) :result))
      (put state :lateral-move-counter 0)))
  # turning
  (when (>= (state :turn-move-counter) p/turning-speed)
    (when ((resolve-turn-move! state) :result)
      (put state :turn-move-counter 0)))
  #
  state)

(defn init-active-piece!
  [state]
  (create-piece! state)
  (put state :piece-active true)
  (put state :fast-fall-move-counter 0)
  #
  state)

(defn check-game-over!
  [state]
  (loop [j :range [0 2] # XXX: 2?
         i :range [1 (dec p/grid-x-size)]
         :when (= :full
                  (get-in state [:grid i j]))]
    (put state :game-over true)
    (break))
  #
  state)

(defn update-game!
  [state]
  (when (state :game-over)
    (when (j/key-pressed? :enter)
      (s/init! state))
    (break state))
  #
  (when (j/key-pressed? :m)
    (toggle-mute! state))
  #
  (when (j/key-pressed? :p)
    (toggle-pause! state))
  #
  (when (state :pause)
    (break state))
  #
  (when (state :line-to-delete)
    (handle-line-deletion! state)
    (break state))
  #
  (if (state :piece-active)
    (handle-active-piece! state)
    (init-active-piece! state))
  #
  (check-game-over! state)
  #
  state)

(defn update-draw-frame!
  [state]
  # XXX
  (when (zero? (mod (dyn :frame) 1000))
    (let [d (os/date (os/time) true)]
      (printf "%02d:%02d:%02d - %p"
              (d :hours) (d :minutes) (d :seconds) (dyn :frame))))
  (setdyn :frame (inc (dyn :frame)))
  #
  (when (state :bgm)
    (j/update-music-stream (state :bgm)))
  #
  (-> state
      update-game!
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
  # now that a loop is not being done in janet, this needs to
  # happen
  (j/init-window p/screen-width p/screen-height "Jaylib Demo")
  #
  (s/init! state)
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

# XXX: original code
'(defn main
  [& args]
  (var state @{})
  #
  (j/set-config-flags :msaa-4x-hint)
  (j/init-window p/screen-width p/screen-height "Jaylib Demo")
  (j/set-target-fps 60)
  #
  (j/set-exit-key 0)
  #
  (s/init! state)
  #
  (while (not (j/window-should-close))
    (update-draw-frame! state))
  #
  (j/close-window))

