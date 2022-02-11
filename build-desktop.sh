#! /bin/sh

# exit if some part fails
set -e

if [[ -z "${JAYLIB_WASM_DEMO_SKIP_DEPS}" ]]; then
    echo "[Preparing janet amalgamated bits]..."
    cd janet && \
        make clean && \
        PREFIX=resources make && \
        cd ..

    echo "[Preparing libraylib.a]..."
    cd jaylib/raylib/src && \
        make clean && \
        make &&
        cd ../../..

    echo "[Preparing jaylib.janet shim]..."
    mkdir -p resources/lib/janet && \
        janet make-jaylib-janet-shim.janet jaylib/src resources/lib/janet/jaylib.janet
fi

[ -e janet/build/c/janet.c ] || \
    (echo "janet/build/c/janet.c not found, please build" && exit 1)

[ -e jaylib/raylib/libraylib.a ] || \
    (echo "jaylib/raylib/libraylib.a not found, please build" && exit 1)

echo "[Compiling output]..."
gcc \
    -O0 -g3 \
    -Wall \
    -o main \
    main.c \
    janet/build/c/janet.c \
    jaylib/raylib/libraylib.a \
    -Ijanet/build \
    -Ijaylib/src \
    -Ijaylib/raylib/src \
    -lm -lpthread -ldl

