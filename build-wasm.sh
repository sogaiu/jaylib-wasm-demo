#! /bin/sh

source ~/src/emsdk/emsdk_env.sh

mkdir -p public

# XXX: make janet once before proceeding, e.g.
#
#      cd janet && make
#
#      this should produce a build subdirectory in janet with some bits

# XXX: make libraylib.a (wasm version) also, e.g.
#
#      source ~/src/emsdk/emsdk_env.sh # activate emscripten 3.1.3
#      cd jaylib/raylib/src
#      make PLATFORM=PLATFORM_WEB -B -e
#
#      this should produce libraylib.a in jaylib/raylib/src

emcc \
    -Os -Wall \
    -DPLATFORM_WEB \
    -o public/main.html \
    main.c \
    janet/build/c/janet.c jaylib/raylib/src/libraylib.a \
    -Ijanet/build \
    -Ijaylib/src \
    -Ijaylib/raylib/src \
    --preload-file resources \
    --source-map-base http://localhost:8000/ \
    -s ASSERTIONS=2 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s FORCE_FILESYSTEM=1 \
    -s USE_GLFW=3 \
    -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
    -s AGGRESSIVE_VARIABLE_ELIMINATION=1

