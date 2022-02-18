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

