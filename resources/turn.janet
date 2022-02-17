(import jaylib :as j)
(import ./params :as p)

# in rot-info below, each row can be thought of as representing a
# counterclockwise rotation of n items that are components (units) of
# a piece, e.g. the row:
#
#   [[0 0] [3 0] [3 3] [0 3]]
#
# can indicate:
#
#   * move the unit at 3,0 to 0,0
#   * move the unit at 3,3 to 3,0
#   * move the unit at 0,3 to 3,3
#   * move the unit at 0,0 to 0,3
#
#      0     1     2     3
#   +-----+-----+-----+-----+
#   |     |     |     |     |
# 0 |  <- | --- | --- | -^  |
#   |  |  |     |     |  |  |
#   +-----------------------+
#   |  |  |     |     |  |  |
# 1 |  |  |     |     |  |  |
#   |  |  |     |     |  |  |
#   +-----------------------+
#   |  |  |     |     |  |  |
# 2 |  |  |     |     |  |  |
#   |  |  |     |     |  |  |
#   +-----------------------+
#   |  |  |     |     |  |  |
# 3 |  V- | --- | --- | ->  |
#   |     |     |     |     |
#   +-----+-----+-----+-----+
#
# this is done in rotate-ccw! below.
#
# the info in all of the rows can also be used to check whether a
# counterclockwise rotation is possible (i.e. not blocked),
# e.g. looking at:
#
#   [[0 0] [3 0] [3 3] [0 3]]
#
# and checking that:
#
#   * the unit at 3,0 can be moved to 0,0
#   * the unit at 3,3 can be moved to 3,0
#   * the unit at 0,3 can be moved to 3,3
#   * the unit at 0,0 can be moved to 0,3
#
# it indicates that rotation might be possible.  to fully answer
# the question, the other remaining rows would need to be checked
# in a similar manner.
#
# this is done in can-rotate? below.

(def rot-info
  {3
   [[[0 0] [2 0] [2 2] [0 2]]
    [[1 0] [2 1] [1 2] [0 1]]]
   4
   [[[0 0] [3 0] [3 3] [0 3]]
    [[1 0] [3 1] [2 3] [0 2]]
    [[2 0] [3 2] [1 3] [0 1]]
    [[1 1] [2 1] [2 2] [1 2]]]
   })

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
  (var blocked false)
  (loop [row :in (rot-info p/piece-dim)
         i :range [0 (length row)]
         :let [[x1 y1] (get row i)
               [x2 y2] (if (not= i (dec (length row)))
                         (get row (inc i))
                         (get row 0))]
         :when (blocked? [(+ piece-pos-x x2) (+ piece-pos-y y2)]
                         [(+ piece-pos-x x1) (+ piece-pos-y y1)])]
    (set blocked true)
    (break))
  (put state :result (not blocked))
  #
  state)

(defn rotate-ccw!
  [state]
  (def piece (state :piece))
  (defn left-rotate-units
    [positions]
    (var aux
      (get-in piece (first positions)))
    (loop [i :range [0 (dec (length positions))]]
      (put-in piece (get positions i)
              (get-in piece (get positions (inc i)))))
    (put-in piece (last positions) aux))
  #
  (each row (rot-info p/piece-dim)
    (left-rotate-units row))
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
    (loop [i :range [piece-pos-x (+ piece-pos-x p/piece-dim)]
           j :range [piece-pos-y (+ piece-pos-y p/piece-dim)]
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

