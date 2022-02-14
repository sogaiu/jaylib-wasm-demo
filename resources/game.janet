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

# 2-d array with dimensions grid-horizontal-size x grid-vertical-size
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
(var incoming-piece @[])

# x (horizontal) coordinate of top-left of "piece grid"
#
# "piece grid" is a piece-dim x piece-dim square of spots within the
# game grid.  the spots within the "piece grid" that represent the
# piece have the value :moving, while the other spots within the
# "piece grid" that are not occupied by the piece have the value
# :empty.
(var piece-position-x 0)

# y (vertical) coordinate of top-left of "piece grid"
(var piece-position-y 0)

(var fading-color nil)

(var begin-play true)

(var piece-active false)

(var detection false)

# whether any lines need to be deleted
(var line-to-delete false)

(var level 1)

# number of lines deleted so far
(var lines 0)

(var gravity-movement-counter 0)

(var lateral-movement-counter 0)

(var turn-movement-counter 0)

(var fast-fall-movement-counter 0)

(var fade-line-counter 0)

(var gravity-speed 30)

###########################################################################

(var bgm nil)

(var bgm-volume 0.5)

###########################################################################

(defn get-random-piece
  []
  # empty out incoming-piece
  (loop [i :range [0 piece-dim]
         j :range [0 piece-dim]]
    (put-in incoming-piece [i j] :empty))
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
    (put-in incoming-piece a-unit :moving)))

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
  (loop [i :range [0 piece-dim]
         j :range [0 piece-dim]]
    (put-in piece [i j]
            (get-in incoming-piece [i j])))
  # get another incoming piece
  (get-random-piece)
  # put the piece in the grid
  (loop [i :range [piece-position-x (+ piece-position-x 4)]
         j :range [0 piece-dim]
         :when (= :moving
                  (get-in piece [(- i piece-position-x) j]))]
    (put-in grid [i j] :moving))
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
    (j/key-down? :a)
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
    (j/key-down? :d)
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
  (when (j/key-down? :w)
    (var aux nil)
    (var checker false)
    # check whether rotation is not possible
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
    # rotate piece counterclockwise if appropriate
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
    # clear grid spots occupied that were occupied by piece
    (loop [j :down-to [(- grid-vertical-size 2) 0]]
      (for i 1 (dec grid-horizontal-size)
        (when (= :moving
                 (get-in grid [i j]))
          (put-in grid [i j] :empty))))
    # fill grid spots that the piece occupies
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
  # check if spots below all of the spots occupied by a piece can be
  # moved into (i.e. not :full and not :block)
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
  # determine if any lines need to be deleted
  (loop [j :down-to [(- grid-vertical-size 2) 0]]
    (set calculator 0)
    # count spots that are occupied by stationary blocks (i.e. :full)
    (loop [i :range [1 (dec grid-horizontal-size)]]
      (when (= :full
               (get-in grid [i j]))
        (++ calculator))
      # if appropriate, mark spots that need to be deleted and remember
      # that at least one line needs to be deleted
      (when (= (- grid-horizontal-size 2)
               calculator)
        (set line-to-delete true)
        (set calculator 0)
        (for z 1 (dec grid-horizontal-size)
          (put-in grid [z j] :fading))))))

(defn delete-complete-lines
  []
  # start at the bottom row (above the bottom :block row) and work way upward
  (loop [j :down-to [(- grid-vertical-size 2) 0]]
    (while (= :fading
              (get-in grid [1 j])) # if left-most spot is :fading, whole row is
      # delete the current row by marking all spots in it :empty
      (for i 1 (dec grid-horizontal-size)
        (put-in grid [i j] :empty))
      # shift all rows above down by one appropriately
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
    # work on a column at a time
    (each j (range grid-vertical-size)
      (if (or (= i 0)
              (= i (dec grid-horizontal-size))
              (= j (dec grid-vertical-size)))
        # pre-fill left, right, and bottom edges of the grid
        (put-in a-grid [i j] :block)
        # all other spots are :empty
        (put-in a-grid [i j] :empty))))
  a-grid)

(defn init-piece
  [a-piece]
  # mark all spots in a-piece :empty
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
      (when (j/key-pressed? :m)
        (if (zero? bgm-volume)
          (set bgm-volume 0.5)
          (set bgm-volume 0))
        (j/set-music-volume bgm bgm-volume))
      (when (j/key-pressed? :p)
        (set pause (not pause))
        (if pause
          (j/pause-music-stream bgm)
          (j/resume-music-stream bgm)))
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
                (when (or (j/key-pressed? :a)
                          (j/key-pressed? :d))
                  (set lateral-movement-counter lateral-speed))
                (when (j/key-pressed? :w)
                  (set turn-movement-counter turning-speed))
                # fall?
                (when (and (j/key-down? :s)
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
    (when (j/key-pressed? :enter)
      (init-game)
      (set game-over false))))

(defn draw-game
  []
  (j/begin-drawing)
  #
  (j/clear-background :dark-green)
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
            :full
            (do
              (j/draw-rectangle offset-x offset-y
                                square-size square-size :black)
              (+= offset-x square-size))
            #
            :moving
            (do
              (j/draw-rectangle offset-x offset-y
                                square-size square-size :dark-gray)
              (+= offset-x square-size))
            #
            :block
            (do
              (j/draw-rectangle offset-x offset-y
                                square-size square-size :light-gray)
              (+= offset-x square-size))
            #
            :fading
            (do
              (j/draw-rectangle offset-x offset-y
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
      #
      (j/draw-text `INCOMING:`
                   offset-x (- offset-y 100)
                   10 :gray)
      # XXX: `text-format` doesn't exist, so using `string/format`
      (j/draw-text (string/format `LINES:      %04i` lines)
                   offset-x (+ offset-y 20)
                   10 :gray)
      (when pause
        (j/draw-text `GAME PAUSED`
                     (- (/ screen-width 2)
                        (/ (j/measure-text `GAME PAUSED` 40)
                           2))
                     (- (/ screen-height 2)
                        40)
                     40 :gray)))
    # XXX: why are get-screen-width and get-screen-height used here
    #      when they are not above?
    (j/draw-text `PRESS [ENTER] TO PLAY AGAIN`
                 (- (/ (j/get-screen-width) 2)
                    (/ (j/measure-text `PRESS [ENTER] TO PLAY AGAIN` 20)
                       2))
                 (- (/ (j/get-screen-height) 2)
                  50)
               20 :gray))
  #
  (j/end-drawing))

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
  (update-game)
  (draw-game))

(defn desktop
  []
  (j/set-config-flags :msaa-4x-hint)
  (j/set-target-fps 60))

# now that a loop is not being done in janet, this needs to
# happen
(j/init-window screen-width screen-height `Jaylib Demo`)

(j/init-audio-device)
(set bgm (j/load-music-stream "resources/theme.ogg"))
(j/play-music-stream bgm)
(j/set-music-volume bgm bgm-volume)

(init-game)

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
  (j/init-window screen-width screen-height `Jaylib Demo`)
  (j/set-target-fps 60)
  #
  (j/set-exit-key 0)
  #
  (init-game)
  #
  (while (not (j/window-should-close))
    (update-draw-frame))
  #
  (j/close-window))

