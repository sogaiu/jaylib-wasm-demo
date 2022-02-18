(import jaylib :as j)
(import ./params :as p)

(defn left-blocked?
  [state]
  (def grid-x-size
    (or (state :grid-x-size) p/grid-x-size))
  (def grid-y-size
    (or (state :grid-y-size) p/grid-y-size))
  (def collision
    (label result
      (loop [j :down-to [(- grid-y-size 2) 0]
             i :range [1 (dec grid-x-size)]
             :let [grid (state :grid)]
             :when (and (= :moving
                           (get-in grid [i j]))
                        (or (zero? (dec i))
                            (= :full
                               (get-in grid [(dec i) j]))))]
        (return result true))
      (return result false)))
  #
  (put state :result collision)
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
    ((left-blocked? state) :result))
  # =>
  true

  (let [t-grid [[:block :empty :moving :empty  :block]
                [:block :empty :moving :moving :block]
                [:block :empty :moving :empty  :block]
                [:block :block :block  :block  :block]]
        grid (u/transpose t-grid)
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

  (import ./utils :as u)

  (let [t-grid [[:block :empty :empty  :empty  :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :empty :moving :moving :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :block :block  :block  :block :block]]
        grid (u/transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))
                :piece-pos-x 1
                :piece-pos-y 1}]
    (u/transpose ((move-left! state) :grid)))
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
      (return result false)))
  #
  (put state :result collision)
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
    ((right-blocked? state) :result))
  # =>
  true

  (let [t-grid [[:block :moving :empty  :empty :block]
                [:block :moving :moving :empty :block]
                [:block :moving :empty  :empty :block]
                [:block :block  :block  :block :block]]
        grid (u/transpose t-grid)
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

  (import ./utils :as u)

  (let [t-grid [[:block :empty :empty  :empty  :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :empty :moving :moving :empty :block]
                [:block :empty :moving :empty  :empty :block]
                [:block :block :block  :block  :block :block]]
        grid (u/transpose t-grid)
        state @{:grid grid
                :grid-x-size (length grid)
                :grid-y-size (length (get grid 0))
                :piece-pos-x 1
                :piece-pos-y 1}]
    (u/transpose ((move-right! state) :grid)))
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

