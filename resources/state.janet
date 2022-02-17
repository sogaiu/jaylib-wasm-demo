(import ./params :as p)

(defn init-grid
  []
  (def a-grid @[])
  (loop [i :range [0 p/grid-x-size]
         :before (put a-grid i (array/new p/grid-y-size))
         j :range [0 p/grid-y-size]]
    (if (or (= i 0)
            (= i (dec p/grid-x-size))
            (= j (dec p/grid-y-size)))
      # pre-fill left, right, and bottom edges of the grid
      (put-in a-grid [i j] :block)
      # all other spots are :empty
      (put-in a-grid [i j] :empty)))
  a-grid)

(defn init-piece
  []
  (def a-piece @[])
  # mark all spots in a-piece :empty
  (loop [i :range [0 p/piece-dim]
         :before (put a-piece i (array/new p/piece-dim))
         j :range [0 p/grid-x-size]]
    (put-in a-piece [i j] :empty))
  a-piece)

(defn init!
  [state]
  # x-coordinate of top-left of "piece grid"
  #
  # "piece grid" is a piece-dim x piece-dim square of spots within the
  # game grid.  the spots within the "piece grid" that represent the
  # piece have the value :moving, while the other spots within the
  # "piece grid" that are not occupied by the piece have the value
  # :empty.
  (put state :piece-pos-x 0)
  # y-coordinate of top-left of "piece grid"
  (put state :piece-pos-y 0)
  # 2-d array with dimensions grid-x-size x grid-y-size
  #
  # possibly values include:
  #
  # :empty  - space unoccupied
  # :full   - occupied (by what was part of past piece)
  # :moving - occupied by part of in-motion piece
  # :block  - pre-filled space - left, right, or bottom edge
  # :fading - about to be deleted / cleared
  (put state :grid (init-grid))
  # 2-d array with dimensions piece-dim x piece-dim
  #
  # possible values include:
  #
  # :empty  - spot is empty
  # :moving - spot is part of piece
  (put state :piece @[])
  # same structure and content as piece
  (put state :future-piece (init-piece))
  (put state :game-over false)
  (put state :pause false)
  (put state :begin-play true)
  (put state :piece-active false)
  (put state :fading-color :gray)
  # whether any lines need to be deleted
  (put state :line-to-delete false)
  # number of lines deleted so far
  (put state :lines 0)
  (put state :blocked-below false)
  (put state :gravity-move-counter 0)
  (put state :lateral-move-counter 0)
  (put state :turn-move-counter 0)
  (put state :fast-fall-move-counter 0)
  (put state :fade-line-counter 0)
  #
  (put state :bgm nil)
  (put state :bgm-volume 0.5)
  # XXX: hack for retrieving result of function invocation
  (put state :result nil)
  state)
