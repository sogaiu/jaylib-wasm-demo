(def out-dir "public")

(def port "8000")

(def preload-dir "resources")

###########################################################################

(def start (os/clock))

(unless (os/getenv "EMSDK")
  (eprintf "emsdk environment not detected: try emsdk_env.bat?")
  (os/exit 1))

(prinf "\n[ensuring existence of directory: %p]..." out-dir)
(try
  (os/mkdir out-dir)
  ([e]
    (eprintf "<<problem with mkdir for: %p>>" out-dir)
    (os/exit 1)))

(printf "\n[preparing amalgamated janet.c and related]...")
(let [old-dir (os/cwd)]
  (try
    (os/cd "janet")
    ([e]
      (eprintf "<<failed to cd to janet directory>>")
      (os/exit 1)))
  (try
    (os/execute ["build_win.bat" "clean"] :px)
    ([e]
      (eprintf "<<problem with cleaning for janet>>")
      (os/exit 1)))
  (try
    (os/execute ["build_win.bat"] :px)
    ([e]
      (eprintf "<<problem building janet>>")
      (os/exit 1)))
  (try
    (os/cd old-dir)
    ([e]
      (eprintf "<<problem restoring current directory>>")
      (os/exit 1))))

(printf "\n[preparing HTML5-aware libraylib.a]...")
(let [old-dir (os/cwd)]
  (try
    (os/cd "jaylib/raylib/src")
    ([e]
      (eprintf "<<failed to cd to janet directory>>")
      (os/exit 1)))
  (def commands
    [["emcc.bat"
      "-c" "rcore.c" "-Os" "-Wall"
      "-DPLATFORM_WEB" "-DGRAPHICS_API_OPENGL_ES2"]
     ["emcc.bat"
      "-c" "rshapes.c" "-Os" "-Wall"
      "-DPLATFORM_WEB" "-DGRAPHICS_API_OPENGL_ES2"]
     ["emcc.bat"
      "-c" "rtextures.c" "-Os" "-Wall"
      "-DPLATFORM_WEB" "-DGRAPHICS_API_OPENGL_ES2"]
     ["emcc.bat"
      "-c" "rtext.c" "-Os" "-Wall"
      "-DPLATFORM_WEB" "-DGRAPHICS_API_OPENGL_ES2"]
     ["emcc.bat"
      "-c" "rmodels.c" "-Os" "-Wall"
      "-DPLATFORM_WEB" "-DGRAPHICS_API_OPENGL_ES2"]
     ["emcc.bat"
      "-c" "utils.c" "-Os" "-Wall" "-DPLATFORM_WEB"]
     ["emcc.bat"
      "-c" "raudio.c" "-Os" "-Wall" "-DPLATFORM_WEB"]
     ["emar.bat"
      "rcs" "libraylib.a"
      "rcore.o" "rshapes.o" "rtextures.o" "rtext.o" "rmodels.o"
      "utils.o" "raudio.o"]])
  (each cmd commands
    (try
      (os/execute cmd :px)
      ([e]
        (eprintf "<<problem building libraylib.a: %p>>" cmd)
        (os/exit 1))))
  (try
    (os/cd old-dir)
    ([e]
      (eprintf "<<problem restoring current directory>>")
      (os/exit 1))))

(printf "\n[compiling with emcc]...")
(try
  (os/execute ["emcc.bat"
               "-Os" "-Wall"
               "-DPLATFORM_WEB"
               "-o" (string out-dir "/main.html")
               "main.c"
               "janet/build/c/janet.c"
               "jaylib/raylib/src/libraylib.a"
               "-Ijanet/build"
               "-Ijanet/src/conf"
               "-Ijanet/src/include"
               "-Ijaylib/src"
               "-Ijaylib/raylib/src"
               "--preload-file" preload-dir
               "--source-map-base" (string "http://localhost:" port "/")
               "-s" "ASYNCIFY"
               "-s" "ASSERTIONS=2"
               "-s" "ALLOW_MEMORY_GROWTH=1"
               "-s" "FORCE_FILESYSTEM=1"
               "-s" "USE_GLFW=3"
               "-s" `EXPORTED_RUNTIME_METHODS=['cwrap']`
               "-s" "AGGRESSIVE_VARIABLE_ELIMINATION=1"]
              :px)
  ([e]
    (eprintf "<<problem compiling with emcc>>")
    (os/exit 1)))
(print)

(def end (os/clock))

(printf "Completed in %p seconds" (- end start))

