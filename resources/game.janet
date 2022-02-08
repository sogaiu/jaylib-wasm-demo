# a port of:
#
# https://github.com/raysan5/raylib-games/blob/master/classics/src/tetris.c

# XXX: functions are made available via main.c
#(use jaylib)

###########################################################################

(def an-rng
  (math/rng)
  # XXX: wasn't playing well with wasm
  #'(math/rng (os/cryptorand 8))
  )

###########################################################################

(def square-size 20)

(def grid-horizontal-size 12)

(def grid-vertical-size 20)

(def piece-dim 4)

(def lateral-speed 10)

(def turning-speed 12)

(def fast-fall-await-counter 30)

(def fading-time 33)

###########################################################################

(var screen-width 800)

(var screen-height 450)

(var game-over false)

(var pause false)

(var grid @[])

(var piece @[])

(var incoming-piece @[])

(var piece-position-x 0)

(var piece-position-y 0)

(var fading-color nil)

(var begin-play true)

(var piece-active false)

(var detection false)

(var line-to-delete false)

(var level 1)

(var lines 0)

(var gravity-movement-counter 0)

(var lateral-movement-counter 0)

(var turn-movement-counter 0)

(var fast-fall-movement-counter 0)

(var fade-line-counter 0)

(var gravity-speed 30)

###########################################################################

(var bgm nil)

(var bgm-volume 1)

###########################################################################

(defn get-random-piece
  []
  (def random
    # XXX: docs say math/rng-int will return up through max, but only max - 1?
    (math/rng-int an-rng (+ 6 1)))
  # empty out incoming-piece
  (for i 0 piece-dim
    (for j 0 piece-dim
      (put-in incoming-piece [i j] :empty)))
  #
  (case random
    0
    (do
      (put-in incoming-piece [1 1] :moving)
      (put-in incoming-piece [2 1] :moving)
      (put-in incoming-piece [1 2] :moving)
      (put-in incoming-piece [2 2] :moving))
    1
    (do
      (put-in incoming-piece [1 0] :moving)
      (put-in incoming-piece [1 1] :moving)
      (put-in incoming-piece [1 2] :moving)
      (put-in incoming-piece [2 2] :moving))
    2
    (do
      (put-in incoming-piece [1 2] :moving)
      (put-in incoming-piece [2 0] :moving)
      (put-in incoming-piece [2 1] :moving)
      (put-in incoming-piece [2 2] :moving))
    3
    (do
      (put-in incoming-piece [0 1] :moving)
      (put-in incoming-piece [1 1] :moving)
      (put-in incoming-piece [2 1] :moving)
      (put-in incoming-piece [3 1] :moving))
    4
    (do
      (put-in incoming-piece [1 0] :moving)
      (put-in incoming-piece [1 1] :moving)
      (put-in incoming-piece [1 2] :moving)
      (put-in incoming-piece [2 1] :moving))
    5
    (do
      (put-in incoming-piece [1 1] :moving)
      (put-in incoming-piece [2 1] :moving)
      (put-in incoming-piece [2 2] :moving)
      (put-in incoming-piece [3 2] :moving))
    6
    (do
      (put-in incoming-piece [1 2] :moving)
      (put-in incoming-piece [2 2] :moving)
      (put-in incoming-piece [2 1] :moving)
      (put-in incoming-piece [3 1] :moving))))

(defn create-piece
  []
  (set piece-position-x
       (math/floor (/ (- grid-horizontal-size 4)
                      2)))
  (set piece-position-y 0)
  # create extra piece this one time
  (when begin-play
    (get-random-piece)
    (set begin-play false))
  # copy newly obtained incoming-piece to piece
  (for i 0 piece-dim
    (for j 0 piece-dim
      (put-in piece [i j]
              (get-in incoming-piece [i j]))))
  # get another incoming piece
  (get-random-piece)
  # put the piece in the grid
  (for i piece-position-x (+ piece-position-x 4)
    (for j 0 piece-dim
      (when (= :moving
               (get-in piece [(- i piece-position-x) j]))
        (put-in grid [i j] :moving))))
  #
  true)

(defn resolve-falling-movement
  []
  (if detection
    # stop the piece
    (loop [j :down-to [(- grid-vertical-size 2) 0]]
      (loop [i :range [1 (dec grid-horizontal-size)]]
        (when (= :moving
                 (get-in grid [i j]))
          (put-in grid [i j] :full)
          (set detection false)
          (set piece-active false))))
    # move the piece down
    (do
      (loop [j :down-to [(- grid-vertical-size 2) 0]]
        (loop [i :range [1 (dec grid-horizontal-size)]]
          (when (= :moving
                   (get-in grid [i j]))
            (put-in grid [i (inc j)] :moving)
            (put-in grid [i j] :empty))))
      (++ piece-position-y))))

(defn resolve-lateral-movement
  []
  (var collision false)
  #
  (cond
    (key-down? :left)
    (do
      # determine if moving left is possible
      (loop [j :down-to [(- grid-vertical-size 2) 0]]
        (loop [i :range [1 (dec grid-horizontal-size)]]
          (when (= :moving
                   (get-in grid [i j]))
            (when (or (zero? (dec i))
                      (= :full
                         (get-in grid [(dec i) j])))
              (set collision true)))))
      # move left if possible
      (when (not collision)
        (loop [j :down-to [(- grid-vertical-size 2) 0]]
          (loop [i :range [1 (dec grid-horizontal-size)]]
            (when (= :moving
                     (get-in grid [i j]))
              (put-in grid [(dec i) j] :moving)
              (put-in grid [i j] :empty))))
        (-- piece-position-x)))
    #
    (key-down? :right)
    (do
      # determine if moving right is possible
      (loop [j :down-to [(- grid-vertical-size 2) 0]]
        (loop [i :range [1 (dec grid-horizontal-size)]]
          (when (= :moving
                   (get-in grid [i j]))
            (when (or (= (inc i)
                         (dec grid-horizontal-size))
                      (= :full
                         (get-in grid [(inc i) j])))
              (set collision true)))))
      # move right if possible
      (when (not collision)
        (loop [j :down-to [(- grid-vertical-size 2) 0]]
          (loop [i :down-to [(dec grid-horizontal-size) 1]]
            (when (= :moving
                     (get-in grid [i j]))
              (put-in grid [(inc i) j] :moving)
              (put-in grid [i j] :empty))))
        (++ piece-position-x))))
  #
  collision)

(defn resolve-turn-movement
  []
  (when (key-down? :up)
    (var aux nil)
    (var checker false)
    #
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 3) piece-position-y]))
               (not= :empty
                     (get-in grid
                             [piece-position-x piece-position-y]))
               (not= :moving
                     (get-in grid
                             [piece-position-x piece-position-y])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 3) (+ piece-position-y 3)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 3) piece-position-y]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 3) piece-position-y])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [piece-position-x (+ piece-position-y 3)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 3) (+ piece-position-y 3)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 3) (+ piece-position-y 3)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [piece-position-x piece-position-y]))
               (not= :empty
                     (get-in grid
                             [piece-position-x (+ piece-position-y 3)]))
               (not= :moving
                     (get-in grid
                             [piece-position-x (+ piece-position-y 3)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 1) piece-position-y]))
               (not= :empty
                     (get-in grid
                             [piece-position-x (+ piece-position-y 2)]))
               (not= :moving
                     (get-in grid
                             [piece-position-x (+ piece-position-y 2)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 3) (+ piece-position-y 1)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 1) piece-position-y]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 1) piece-position-y])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 2) (+ piece-position-y 3)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 3) (+ piece-position-y 1)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 3) (+ piece-position-y 1)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [piece-position-x (+ piece-position-y 2)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 2) (+ piece-position-y 3)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 2) (+ piece-position-y 3)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 2) piece-position-y]))
               (not= :empty
                     (get-in grid
                             [piece-position-x (+ piece-position-y 1)]))
               (not= :moving
                     (get-in grid
                             [piece-position-x (+ piece-position-y 1)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 3) (+ piece-position-y 2)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 2) piece-position-y]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 2) piece-position-y])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 1) (+ piece-position-y 3)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 3) (+ piece-position-y 2)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 3) (+ piece-position-y 2)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [piece-position-x (+ piece-position-y 1)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 1) (+ piece-position-y 3)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 1) (+ piece-position-y 3)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 1) (+ piece-position-y 1)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 1) (+ piece-position-y 2)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 1) (+ piece-position-y 2)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 2) (+ piece-position-y 1)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 1) (+ piece-position-y 1)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 1) (+ piece-position-y 1)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 2) (+ piece-position-y 2)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 2) (+ piece-position-y 1)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 2) (+ piece-position-y 1)])))
      (set checker true))
    (when (and (= :moving
                  (get-in grid
                          [(+ piece-position-x 1) (+ piece-position-y 2)]))
               (not= :empty
                     (get-in grid
                             [(+ piece-position-x 2) (+ piece-position-y 2)]))
               (not= :moving
                     (get-in grid
                             [(+ piece-position-x 2) (+ piece-position-y 2)])))
      (set checker true))
    #
    (when (not checker)
      (set aux (get-in piece [0 0]))
      (put-in piece [0 0]
              (get-in piece [3 0]))
      (put-in piece [3 0]
              (get-in piece [3 3]))
      (put-in piece [3 3]
              (get-in piece [0 3]))
      (put-in piece [0 3] aux)
      #
      (set aux (get-in piece [1 0]))
      (put-in piece [1 0]
              (get-in piece [3 1]))
      (put-in piece [3 1]
              (get-in piece [2 3]))
      (put-in piece [2 3]
              (get-in piece [0 2]))
      (put-in piece [0 2] aux)
      #
      (set aux (get-in piece [2 0]))
      (put-in piece [2 0]
              (get-in piece [3 2]))
      (put-in piece [3 2]
              (get-in piece [1 3]))
      (put-in piece [1 3]
              (get-in piece [0 1]))
      (put-in piece [0 1] aux)
      #
      (set aux (get-in piece [1 1]))
      (put-in piece [1 1]
              (get-in piece [2 1]))
      (put-in piece [2 1]
              (get-in piece [2 2]))
      (put-in piece [2 2]
              (get-in piece [1 2]))
      (put-in piece [1 2] aux))
    #
    (loop [j :down-to [(- grid-vertical-size 2) 0]]
      (for i 1 (dec grid-horizontal-size)
        (when (= :moving
                 (get-in grid [i j]))
          (put-in grid [i j] :empty))))
    #
    (for i piece-position-x (+ piece-position-x 4)
      (for j piece-position-y (+ piece-position-y 4)
        (when (= :moving
                 (get-in piece
                         [(- i piece-position-x) (- j piece-position-y)]))
          (put-in grid [i j] :moving))))
    #
    (break true))
  #
  false)

(defn check-detection
  []
  (loop [j :down-to [(- grid-vertical-size 2) 0]]
    (loop [i :range [1 (dec grid-horizontal-size)]]
      (when (and (= :moving
                    (get-in grid [i j]))
                 (or (= :full
                        (get-in grid [i (inc j)]))
                     (= :block
                        (get-in grid [i (inc j)]))))
        (set detection true)))))

(defn check-completion
  []
  (var calculator 0)
  #
  (loop [j :down-to [(- grid-vertical-size 2) 0]]
    (set calculator 0)
    (loop [i :range [1 (dec grid-horizontal-size)]]
      (when (= :full
               (get-in grid [i j]))
        (++ calculator))
      (when (= (- grid-horizontal-size 2)
               calculator)
        (set line-to-delete true)
        (set calculator 0)
        (for z 1 (dec grid-horizontal-size)
          (put-in grid [z j] :fading))))))

(defn delete-complete-lines
  []
  (loop [j :down-to [(- grid-vertical-size 2) 0]]
    (while (= :fading
              (get-in grid [1 j]))
      (for i 1 (dec grid-horizontal-size)
        (put-in grid [i j] :empty))
      (loop [j2 :down-to [(dec j) 0]]
        (for i2 1 (dec grid-horizontal-size)
          (cond
            (= :full
               (get-in grid [i2 j2]))
            (do
              (put-in grid [i2 (inc j2)] :full)
              (put-in grid [i2 j2] :empty))
            #
            (= :fading
               (get-in grid [i2 j2]))
            (do
              (put-in grid [i2 (inc j2)] :fading)
              (put-in grid [i2 j2] :empty))))))))

(defn init-grid
  [a-grid]
  (each i (range grid-horizontal-size)
    (put a-grid i (array/new grid-vertical-size))
    (each j (range grid-vertical-size)
      (if (or (= i 0)
              (= i (dec grid-horizontal-size))
              (= j (dec grid-vertical-size)))
        (put-in a-grid [i j] :block)
        (put-in a-grid [i j] :empty))))
  a-grid)

(defn init-piece
  [a-piece]
  (each i (range piece-dim)
    (put a-piece i (array/new piece-dim))
    (each j (range grid-horizontal-size)
      (put-in a-piece [i j] :empty)))
  a-piece)

(defn init-game
  []
  (set level 1)
  (set lines 0)
  (set fading-color :gray)
  (set piece-position-x 0)
  (set piece-position-y 0)
  (set pause false)
  (set begin-play true)
  (set piece-active false)
  (set detection false)
  (set line-to-delete false)
  (set gravity-movement-counter 0)
  (set lateral-movement-counter 0)
  (set turn-movement-counter 0)
  (set fast-fall-movement-counter 0)
  (set fade-line-counter 0)
  (set gravity-speed 30)
  (set grid (init-grid grid))
  (set incoming-piece (init-piece incoming-piece)))

(defn update-game
  []
  (if (not game-over)
    (do
      # XXX
      #(when (key-pressed? :m)
      #  (if (zero? bgm-volume)
      #    (set bgm-volume 1)
      #    (set bgm-volume 0))
      #  (set-music-volume bgm bgm-volume))
      (when (key-pressed? :p)
        (set pause (not pause))
        #(if pause
        #  (pause-music-stream bgm)
        #  (resume-music-stream bgm))
        )
      #
      (when (not pause)
        (if (not line-to-delete)
          (do
            (if (not piece-active)
              (do # piece not falling
                (set piece-active (create-piece))
                (set fast-fall-movement-counter 0))
              (do # piece falling
                (++ fast-fall-movement-counter)
                (++ gravity-movement-counter)
                (++ lateral-movement-counter)
                (++ turn-movement-counter)
                # arrange for movement if necessary
                (when (or (key-pressed? :left)
                          (key-pressed? :right))
                  (set lateral-movement-counter lateral-speed))
                (when (key-pressed? :up)
                  (set turn-movement-counter turning-speed))
                # fall?
                (when (and (key-down? :down)
                           (>= fast-fall-movement-counter
                               fast-fall-await-counter))
                  (+= gravity-movement-counter gravity-speed))
                (when (>= gravity-movement-counter gravity-speed)
                  # falling
                  (check-detection)
                  # collision?
                  (resolve-falling-movement)
                  # any lines completed?
                  (check-completion)
                  (set gravity-movement-counter 0))
                # side ways movement
                (when (>= lateral-movement-counter lateral-speed)
                  (when (not (resolve-lateral-movement))
                    (set lateral-movement-counter 0)))
                # turning
                (when (>= turn-movement-counter turning-speed)
                  (when (resolve-turn-movement)
                    (set turn-movement-counter 0)))))
            # game over?
            (for j 0 2 # XXX: 2?
              (for i 1 (dec grid-horizontal-size)
                (when (= :full
                         (get-in grid [i j]))
                  (set game-over true)))))
          (do # there is a line to delete
            (++ fade-line-counter)
            (if (< (% fade-line-counter 8) 4)
              (set fading-color :maroon)
              (set fading-color :gray))
            (when (>= fade-line-counter fading-time)
              (delete-complete-lines)
              (set fade-line-counter 0)
              (set line-to-delete false)
              (++ lines))))))
    (when (key-pressed? :enter)
      (init-game)
      (set game-over false))))

(defn draw-game
  []
  (begin-drawing)
  #
  (clear-background :dark-green)
  #
  (if (not game-over)
    (do
      (var offset-x
        (- (/ screen-width 2)
           (* grid-horizontal-size (/ square-size 2))
           50))
      (var offset-y
        (- (/ screen-height 2)
           (+ (* (dec grid-vertical-size) (/ square-size 2))
              (* square-size 2))
           50))
      (var controller offset-x)
      (for j 0 grid-vertical-size
        (for i 0 grid-horizontal-size
          (case (get-in grid [i j])
            :empty
            (do
              (draw-line offset-x offset-y
                         (+ offset-x square-size) offset-y
                         :light-gray)
              (draw-line offset-x offset-y
                         offset-x (+ offset-y square-size)
                         :light-gray)
              (draw-line (+ offset-x square-size) offset-y
                         (+ offset-x square-size) (+ offset-y square-size)
                         :light-gray)
              (draw-line offset-x (+ offset-y square-size)
                         (+ offset-x square-size) (+ offset-y square-size)
                         :light-gray)
              (+= offset-x square-size))
            #
            :full
            (do
              (draw-rectangle offset-x offset-y
                              square-size square-size :black)
              (+= offset-x square-size))
            #
            :moving
            (do
              (draw-rectangle offset-x offset-y
                              square-size square-size :dark-gray)
              (+= offset-x square-size))
            #
            :block
            (do
              (draw-rectangle offset-x offset-y
                              square-size square-size :light-gray)
              (+= offset-x square-size))
            #
            :fading
            (do
              (draw-rectangle offset-x offset-y
                              square-size square-size fading-color)
              (+= offset-x square-size))
            #
            (eprintf `Unexpected value: %p at %p, %p`
                     (get-in grid [i j]) i j)))
        (set offset-x controller)
        (+= offset-y square-size))
      # XXX: hard-coded
      (set offset-x 500)
      (set offset-y 45)
      # XXX: original had a second variable with name missing an l
      (set controller offset-x)
      #
      (for j 0 piece-dim
        (for i 0 piece-dim
          (case (get-in incoming-piece [i j])
            :empty
            (do
              (draw-line offset-x offset-y
                         (+ offset-x square-size) offset-y
                         :light-gray)
              (draw-line offset-x offset-y
                         offset-x (+ offset-y square-size)
                         :light-gray)
              (draw-line (+ offset-x square-size) offset-y
                         (+ offset-x square-size) (+ offset-y square-size)
                         :light-gray)
              (draw-line offset-x (+ offset-y square-size)
                         (+ offset-x square-size) (+ offset-y square-size)
                         :light-gray)
              (+= offset-x square-size))
            #
            :moving
            (do
              (draw-rectangle offset-x offset-y
                              square-size square-size :gray)
              (+= offset-x square-size))))
        (set offset-x controller)
        (+= offset-y square-size))
      #
      (draw-text `INCOMING:`
                 offset-x (- offset-y 100)
                 10 :gray)
      # XXX: `text-format` doesn't exist, so using `string/format`
      (draw-text (string/format `LINES:      %04i` lines)
                 offset-x (+ offset-y 20)
                 10 :gray)
      (when pause
        (draw-text `GAME PAUSED`
                   (- (/ screen-width 2)
                      (/ (measure-text `GAME PAUSED` 40)
                         2))
                   (- (/ screen-height 2)
                      40)
                   40 :gray)))
    # XXX: why are get-screen-width and get-screen-height used here
    #      when they are not above?
    (draw-text `PRESS [ENTER] TO PLAY AGAIN`
               (- (/ (get-screen-width) 2)
                  (/ (measure-text `PRESS [ENTER] TO PLAY AGAIN` 20)
                     2))
               (- (/ (get-screen-height) 2)
                  50)
               20 :gray))
  #
  (end-drawing))

(defn update-draw-frame
  []
  (when bgm
    (update-music-stream bgm))
  (update-game)
  (draw-game))

# XXX: don't use `setdyn` in here
(defn desktop
  []
  (set-config-flags :msaa-4x-hint)
  (set-target-fps 60))

# now that a loop is not being done in janet, this needs to
# happen
(init-window screen-width screen-height `Jaylib Wasm Demo`)

(init-audio-device)
(set bgm (load-music-stream "resources/theme.ogg"))
(play-music-stream bgm)
(set-music-volume bgm bgm-volume)

(init-game)

(def main-fiber
  (fiber/new
    (fn []
      (while (not (window-should-close))
        (update-draw-frame)
        (yield))
      #
      (close-window))
    :i))

# XXX: original code
'(defn main
  [& args]
  #
  (set-config-flags :msaa-4x-hint)
  (init-window screen-width screen-height `Jaylib Wasm Demo`)
  (set-target-fps 60)
  #
  (set-exit-key 0)
  #
  (init-game)
  #
  (var exit-window false)
  #
  (while (not exit-window)
    (set exit-window
         (window-should-close))
    (update-draw-frame))
  #
  (close-window))
