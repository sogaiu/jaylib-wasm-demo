(def build-dir "build")

(def preload-dir "resources")

###########################################################################

(defn customize-build-script
  [src]
  (def result @[])
  #
  (each line (string/split "\n" src)
    (if (string/has-prefix? `build\janet_boot .` line)
      (array/push result
                  (string `build\janet_boot . `
                          # this is what is being added
                          `JANET_PATH ` preload-dir `/lib/janet `
                          `> build\c\janet.c`))
      (array/push result
                  line)))
  (string/join result "\n"))

###########################################################################

(def start (os/clock))

(prinf "\n[ensuring existence of build directory: %p]..." build-dir)
(try
  (os/mkdir build-dir)
  ([e]
    (eprintf "<<problem with mkdir for: %p>>" build-dir)
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
  # create and execute custom build script
  (def build-file-src (slurp "build_win.bat"))
  (def custom-build-file-path "build_win_custom.bat")
  (spit custom-build-file-path (customize-build-script build-file-src))
  (try
    (os/execute [custom-build-file-path] :px)
    ([e]
      (eprintf "<<problem building janet>>")
      (os/exit 1)))
  (try
    (os/cd old-dir)
    ([e]
      (eprintf "<<problem restoring current directory>>")
      (os/exit 1))))
#
(printf "\n[preparing object files for raylib.lib]...")
(def commands
  [["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rshapes.o"
    "jaylib/raylib/src/rshapes.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rtextures.o"
    "jaylib/raylib/src/rtextures.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/raudio.o"
    "jaylib/raylib/src/raudio.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rglfw.o"
    "jaylib/raylib/src/rglfw.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rcore.o"
    "jaylib/raylib/src/rcore.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rmodels.o"
    "jaylib/raylib/src/rmodels.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rtext.o"
    "jaylib/raylib/src/rtext.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ijaylib/raylib/src"
    "-Ijaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/utils.o"
    "jaylib/raylib/src/utils.c"]])
(each cmd commands
  (try
    (os/execute cmd :px)
    ([e]
      (eprintf "<<problem building object file: %p>>" cmd)
      (os/exit 1))))

(printf "\n[creating raylib.lib]...")
(try
  (os/execute ["lib.exe"
               "/nologo"
               "/out:build/raylib.lib"
               "build/rcore.o"
               "build/rmodels.o"
               "build/raudio.o"
               "build/rglfw.o"
               "build/rshapes.o"
               "build/rtext.o"
               "build/rtextures.o"
               "build/utils.o"
               ]
              :px)
  ([e]
    (eprintf "<<problem compiling: %p>>" e)
    (os/exit 1)))

(printf "\n[preparing jaylib.janet shim]...")
(os/mkdir (string preload-dir "/lib"))
(os/mkdir (string preload-dir "/lib/janet"))
(try
  (os/execute ["janet"
               "make-jaylib-janet-shim.janet"
               "jaylib/src"
               (string preload-dir "/lib/janet/jaylib.janet")] :px)
  ([e]
    (eprintf "<<problem creating jaylib.janet shim>>")
    (os/exit 1)))

(printf "\n[compiling final product]...")
(try
  (os/execute ["cl.exe"
               "main.c"
               "janet/build/c/janet.c"
               "-Ijanet/src/include"
               "-Ijanet/src/conf"
               "-Ijaylib/raylib/src"
               "-Ijaylib/src"
               "/MD"
               #"/link" "/DEBUG"
               "build/raylib.lib"
               "user32.lib"
               "opengl32.lib"
               "gdi32.lib"
               "winmm.lib"
               "shell32.lib"
               ]
              :px)
  ([e]
    (eprintf "<<problem compiling: %p>>" e)
    (os/exit 1)))
(print)

(def end (os/clock))

(printf "Completed in %p seconds" (- end start))

