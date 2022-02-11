# create jaylib.janet, a janet file to enable `use` and `import`
# forms for jaylib to work, hopefully reducing the number of
# changes necessary to get one's jaylib-using code to work on the web

# this code "scrapes" .h files from jaylib and then creates a file
# named `jaylib.janet`.  by placing this file in an appropriate
# location (e.g. resources/lib/janet/jaylib.janet) for bundling by
# emcc, use of `(import jaylib)` or `(use jaylib)` or similar in one's
# janet code should (continue to) work in the context of wasm /
# emscripten.  note that use of this method is likely to add a bit of
# overhead to startup -- but perhaps it is negligible.

# sample invocation:
#
#   janet make-jaylib-janet-shim.janet jaylib/src resources/lib/janet/jaylib.janet
#
# `jaylib/src` is an example of where jaylib's .h files live
# `resources/lib/janet/jaylib.janet` is an example output file destination

(defn main
  [& args]
  (def dir-root
    (when-let [dir (get args 1)]
      dir))
  (def shim-file-path
    (when-let [filepath (get args 2)]
      filepath))
  #
  (default dir-root "jaylib/src")
  (default shim-file-path "resources/lib/janet/jaylib.janet")
  #
  (def shim-file-dir
    (if-let [rev-path (string/reverse shim-file-path)
             slash-idx (string/find "/" rev-path)]
      (-> (string/slice rev-path (inc slash-idx))
          (string/reverse))
      "."))
  (unless (= :directory
             (os/stat shim-file-dir :mode))
    (eprintf "%p should exist and be a directory" shim-file-dir)
    (os/exit 1))
  #
  (def cfuns @[])
  # XXX: draw-grid is (was at one point?) duplicated in 3d.h
  (def dups @{})
  # parse *.h files in jaylib, collecting names
  (each hf (os/dir dir-root)
    (def res
      (->> (slurp (string dir-root "/" hf))
           (peg/match
             ~(sequence (thru "_cfuns[] = {")
                        (thru "\n")
                        (some (sequence (thru `"`)
                                        (capture (to `"`))
                                        `"`
                                        (thru "\n")))))))
    # XXX
    '(when res
       (printf "%p: %p" hf (length res))
       (pp res))
    (array/concat cfuns res))
  # prepare jaylib.janet for writing
  (def jjf
    (try
      (file/open shim-file-path :w)
      ([e]
        (eprintf "problem opening file for writing: %p" e)
        (os/exit 1))))
  # XXX
  '(print (length cfuns))
  # populate jaylib.janet with def forms
  (each cf cfuns
    (when cf
      (when (nil? (get dups cf))
        (file/write jjf
                    (string "(def " cf " " cf ")\n"))
        (put dups cf true))))
  #
  (file/close jjf))

