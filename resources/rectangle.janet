(var screen-width 800)

(var screen-height 450)

###########################################################################

(defn init-game
  []
  )

(defn update-game
  []
  )

(defn draw-game
  []
  (begin-drawing)
  #
  (eprint "before clear-background")
  #
  (clear-background :dark-green)
  #
  (eprint "after clear-background")
  #
  (draw-text `Hi!`
             100 100
             100 :gray)
  #
  (end-drawing))

(defn update-draw-frame
  []
  (update-game)
  (draw-game))

(defn desktop
  []
  (set-config-flags :msaa-4x-hint)
  (set-target-fps 60))

# now that a loop is not being done in janet, this needs to
# happen
(init-window screen-width screen-height `Jaylib Wasm Demo`)
(init-game)

# XXX: original code
'(defn main
  [& args]
  #
  (set-config-flags :msaa-4x-hint)
  (init-window screen-width screen-height `Jaylib Wasm Demo`)
  (set-target-fps 60)
  #
  (set-exit-key 0)
  #
  (init-game)
  #
  (var exit-window false)
  #
  (while (not exit-window)
    (set exit-window
         (window-should-close))
    (update-draw-frame))
  #
  (close-window))

