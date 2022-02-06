mkdir public

emcc ^
    -Os -Wall ^
    -DPLATFORM_WEB ^
    -o public/main.html ^
    main.c ^
    janet/build/c/janet.c jaylib/raylib/src/libraylib.a ^
    -Ijanet/build ^
    -Ijanet/src/conf ^
    -Ijanet/src/include ^
    -Ijaylib/src ^
    -Ijaylib/raylib/src ^
    --preload-file resources ^
    --source-map-base http://localhost:8000/ ^
    -s ASSERTIONS=2 ^
    -s ALLOW_MEMORY_GROWTH=1 ^
    -s FORCE_FILESYSTEM=1 ^
    -s USE_GLFW=3 ^
    -s EXPORTED_RUNTIME_METHODS="['cwrap']" ^
    -s AGGRESSIVE_VARIABLE_ELIMINATION=1

