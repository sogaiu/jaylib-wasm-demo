(import jaylib :as j)
(import ./params :as p)

(defn transpose
  [a-grid]
  (def new-grid @[])
  (loop [j :range [0 (length (get a-grid 0))]
         :before (put new-grid j @[])
         i :range [0 (length a-grid)]]
    (put-in new-grid [j i]
            (get-in a-grid [i j])))
  new-grid)

(comment

  (transpose [[1 2 3]
              [4 5 6]
              [7 8 9]])
  # =>
  @[@[1 4 7]
    @[2 5 8]
    @[3 6 9]]

  (transpose [[1 2 3 4]
              [5 6 7 8]])
  # =>
  @[@[1 5]
    @[2 6]
    @[3 7]
    @[4 8]]

  )

(defn left-blocked?
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  (def collision
    (label result
      (do
        (loop [j :down-to [(- grid-y-size 2) 0]
               i :range [1 (dec grid-x-size)]
               :let [grid (state :grid)]
               :when (and (= :moving
                             (get-in grid [i j]))
                          (or (zero? (dec i))
                              (= :full
                                 (get-in grid [(dec i) j]))))]
          (return result true))
        (return result false))))
  #
  (put state :result collision)
  #
  state)

(comment

  (let [t-grid [[:block :moving :empty  :block]
                [:block :moving :empty  :block]
                [:block :moving :moving :block]
                [:block :block  :block  :block]]
        grid (transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))}]
    ((left-blocked? state) :result))
  # =>
  true

  (let [t-grid [[:block :empty :moving :empty  :block]
                [:block :empty :moving :moving :block]
                [:block :empty :moving :empty  :block]
                [:block :block :block  :block  :block]]
        grid (transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))}]
    ((left-blocked? state) :result))
  # =>
  false

  )

(defn move-left!
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :range [1 (dec grid-x-size)]
         :let [grid (state :grid)]
         :when (= :moving
                  (get-in grid [i j]))]
    (-> grid
        (put-in [(dec i) j] :moving)
        (put-in [i j] :empty)))
  (-- (state :piece-pos-x))
  #
  state)

(comment

  (let [t-grid [[:block :empty :empty  :empty  :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :empty :moving :moving :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :block :block  :block  :block :block]]
        grid (transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))
                :piece-pos-x 1
                :piece-pos-y 1}]
    (transpose ((move-left! state) :grid)))
  # =>
  @[@[:block :empty  :empty  :empty :empty :block]
    @[:block :moving :empty  :empty :empty :block]
    @[:block :moving :moving :empty :empty :block]
    @[:block :moving :empty  :empty :empty :block]
    @[:block :block  :block  :block :block :block]]

  )

(defn right-blocked?
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  (def collision
    (label result
      (do
        (loop [j :down-to [(- grid-y-size 2) 0]
               i :range [1 (dec grid-x-size)]
               :let [grid (state :grid)]
               :when (and (= :moving
                             (get-in grid [i j]))
                          (or (= (inc i)
                                 (dec grid-x-size))
                              (= :full
                                 (get-in grid [(inc i) j]))))]
          (return result true))
        (return result false))))
  #
  (put state :result collision)
  #
  state)

(comment

  (let [t-grid [[:block :moving :empty  :block]
                [:block :moving :empty  :block]
                [:block :moving :moving :block]
                [:block :block  :block  :block]]
        grid (transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))}]
    ((right-blocked? state) :result))
  # =>
  true

  (let [t-grid [[:block :moving :empty  :empty :block]
                [:block :moving :moving :empty :block]
                [:block :moving :empty  :empty :block]
                [:block :block  :block  :block :block]]
        grid (transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))}]
    ((right-blocked? state) :result))
  # =>
  false

  )

(defn move-right!
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  (loop [j :down-to [(- grid-y-size 2) 0]
         i :down-to [(dec grid-x-size) 1]
         :let [grid (state :grid)]
         :when (= :moving
                  (get-in grid [i j]))]
    (-> grid
        (put-in [(inc i) j] :moving)
        (put-in [i j] :empty)))
  (++ (state :piece-pos-x))
  #
  state)

(comment

  (let [t-grid [[:block :empty :empty  :empty  :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :empty :moving :moving :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :block :block  :block  :block :block]]
        grid (transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))
                :piece-pos-x 1
                :piece-pos-y 1}]
    (transpose ((move-right! state) :grid)))
  # =>
  @[@[:block :empty :empty :empty  :empty  :block]
    @[:block :empty :empty :moving :empty  :block]
    @[:block :empty :empty :moving :moving :block]
    @[:block :empty :empty :moving :empty  :block]
    @[:block :block :block :block  :block  :block]]

  )

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

