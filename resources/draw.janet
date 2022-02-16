(import jaylib :as j)
(import ./params :as p)

(defn draw-grid
  [state]
  (var offset-x
    (- (/ p/screen-width 2)
       (* p/grid-x-size (/ p/square-size 2))
       50))
  (var offset-y
    (- (/ p/screen-height 2)
       (+ (* (dec p/grid-y-size) (/ p/square-size 2))
          (* p/square-size 2))
       50))
  (var controller offset-x)
  # draw grid
  (for j 0 p/grid-y-size
    (for i 0 p/grid-x-size
      (case (get-in state [:grid i j])
        :empty
        (do # outline of square
          (j/draw-line offset-x offset-y
                       (+ offset-x p/square-size) offset-y
                       :light-gray)
          (j/draw-line offset-x offset-y
                       offset-x (+ offset-y p/square-size)
                       :light-gray)
          (j/draw-line (+ offset-x p/square-size) offset-y
                       (+ offset-x p/square-size) (+ offset-y p/square-size)
                       :light-gray)
          (j/draw-line offset-x (+ offset-y p/square-size)
                       (+ offset-x p/square-size) (+ offset-y p/square-size)
                       :light-gray))
        #
        :full
        (j/draw-rectangle offset-x offset-y
                          p/square-size p/square-size :black)
        #
        :moving
        (j/draw-rectangle offset-x offset-y
                          p/square-size p/square-size :dark-gray)
        #
        :block
        (j/draw-rectangle offset-x offset-y
                          p/square-size p/square-size :light-gray)
        #
        :fading
        (j/draw-rectangle offset-x offset-y
                          p/square-size p/square-size
                          (state :fading-color))
        #
        (eprintf "Unexpected value: %p at %p, %p"
                 (get-in state [:grid i j]) i j))
      (+= offset-x p/square-size))
    (set offset-x controller)
    (+= offset-y p/square-size))
  #
  state)

(defn draw-info-box
  [state [x y]]
  (var offset-x x)
  (var offset-y y)
  (var controller offset-x)
  # draw future piece
  (for j 0 p/piece-dim
    (for i 0 p/piece-dim
      (case (get-in state [:future-piece i j])
        :empty
        (do
          (j/draw-line offset-x offset-y
                       (+ offset-x p/square-size) offset-y
                       :light-gray)
          (j/draw-line offset-x offset-y
                       offset-x (+ offset-y p/square-size)
                       :light-gray)
          (j/draw-line (+ offset-x p/square-size) offset-y
                       (+ offset-x p/square-size) (+ offset-y p/square-size)
                       :light-gray)
          (j/draw-line offset-x (+ offset-y p/square-size)
                       (+ offset-x p/square-size) (+ offset-y p/square-size)
                       :light-gray)
          (+= offset-x p/square-size))
        #
        :moving
        (do
          (j/draw-rectangle offset-x offset-y
                            p/square-size p/square-size :gray)
          (+= offset-x p/square-size))))
    (set offset-x controller)
    (+= offset-y p/square-size))
  # label future piece box
  (j/draw-text "UPCOMING:"
               offset-x (- offset-y 100)
               10 :gray)
  # show how many lines completed so far
  (j/draw-text (string/format "LINES:      %04i" (state :lines))
               offset-x (+ offset-y 20)
               10 :gray)
  #
  (put state :result [offset-x offset-y])
  #
  state)

(defn draw-pause-overlay
  []
  (let [message "GAME PAUSED"]
    (j/draw-text message
                 (- (/ p/screen-width 2)
                    (/ (j/measure-text message 40)
                       2))
                 (- (/ p/screen-height 2)
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
      (draw-info-box state [500 45]) # XXX: hard-coded
      # show pause overlay when appropriate
      (when (state :pause)
        (draw-pause-overlay))))
  #
  (j/end-drawing)
  #
  state)

