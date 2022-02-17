(import jaylib :as j)
(import ./params :as p)

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
    (-> grid
        (put-in [(dec i) j] :moving)
        (put-in [i j] :empty)))
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
    (-> grid
        (put-in [(inc i) j] :moving)
        (put-in [i j] :empty)))
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

