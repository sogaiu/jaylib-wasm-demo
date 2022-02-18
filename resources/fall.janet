(import ./params :as p)

(defn resolve-falling-move!
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  (def grid (state :grid))
  #
  (if (state :blocked-below)
    # stop the piece
    (loop [j :down-to [(- grid-y-size 2) 0]
           i :range [1 (dec grid-x-size)]
           :when (= :moving
                    (get-in grid [i j]))]
      (put-in grid [i j] :full)
      (put state :blocked-below false)
      (put state :piece-active false))
    # move the piece down
    (do
      (loop [j :down-to [(- grid-y-size 2) 0]
             i :range [1 (dec grid-x-size)]
             :when (= :moving
                      (get-in grid [i j]))]
        (put-in grid [i (inc j)] :moving)
        (put-in grid [i j] :empty))
      (++ (state :piece-pos-y))))
  #
  state)

(comment

  (import ./utils :as u)

  (let [t-grid [[:block :empty :empty  :empty  :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :empty :moving :moving :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :empty :empty  :empty  :empty :block]
                [:block :block :block  :block  :block :block]]
        grid (u/transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))
                :piece-pos-x 1
                :piece-pos-y 1}]
    (u/transpose ((resolve-falling-move! state) :grid)))
  # =>
  @[@[:block :empty :empty  :empty  :empty :block]
    @[:block :empty :empty  :empty  :empty :block]
    @[:block :empty :moving :empty  :empty :block]
    @[:block :empty :moving :moving :empty :block]
    @[:block :empty :moving :empty  :empty :block]
    @[:block :block :block  :block  :block :block]]

  )

(defn check-blocked-below!
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  # check if there is even one spot below the current line that a piece
  # cannot be moved into (i.e. :full or :block)
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :range [1 (dec grid-x-size)]
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

(comment

  (import ./utils :as u)

  (let [t-grid [[:block :moving :empty  :block]
                [:block :moving :empty  :block]
                [:block :moving :moving :block]
                [:block :block  :block  :block]]
        grid (u/transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))}]
    ((check-blocked-below! state) :blocked-below))
  # =>
  true

  )

(defn check-completion!
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  (var calculator 0)
  # determine if any lines need to be deleted
  (loop [j :down-to [(- grid-y-size 2) 0]
         :let [grid (state :grid)]
         :before (set calculator 0)]
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

(comment

  (import ./utils :as u)

  (let [t-grid [[:block :moving :empty  :block]
                [:block :moving :empty  :block]
                [:block :moving :moving :block]
                [:block :block  :block  :block]]
        grid (u/transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))}]
    ((check-completion! state) :line-to-delete))
  # =>
  nil

  (let [t-grid [[:block :empty :empty :empty :block]
                [:block :full  :full  :full  :block]
                [:block :full  :full  :full  :block]
                [:block :block :block :block :block]]
        grid (u/transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))}
        new-state (check-completion! state)]
    [(state :line-to-delete)
     (u/transpose (state :grid))])
  # =>
  [true
   @[@[:block :empty  :empty  :empty  :block]
     @[:block :fading :fading :fading :block]
     @[:block :fading :fading :fading :block]
     @[:block :block  :block  :block  :block]]]

  )

