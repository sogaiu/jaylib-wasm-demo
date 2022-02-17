(import ./params :as p)

(defn resolve-falling-move!
  [state]
  (def grid (state :grid))
  #
  (if (state :blocked-below)
    # stop the piece
    (loop [j :down-to [(- p/grid-y-size 2) 0]
           i :range [1 (dec p/grid-x-size)]
           :when (= :moving
                    (get-in grid [i j]))]
      (put-in grid [i j] :full)
      (put state :blocked-below false)
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

(defn check-blocked-below!
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
    (put state :blocked-below true))
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

