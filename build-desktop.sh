#! /bin/sh

# XXX: make janet once before proceeding, e.g.
#
#      cd janet && make clean && PREFIX=resources make
#
#      this should produce a build subdirectory in janet with some bits

# XXX: make libraylib.a also, e.g.
#
#      make clean
#      cd jaylib/raylib/src
#      make
#
#      this should produce libraylib.a in jaylib/raylib

# XXX: make jaylib.janet shim
#
#      janet make-jaylib-janet-shim.janet jaylib/src resources/lib/janet/jaylib.janet

    #-O2 \
# XXX: only tested on linux
gcc \
    -O0 -g3 \
    -Wall \
    -o main \
    main.c \
    janet/build/c/janet.c jaylib/raylib/libraylib.a \
    -Ijanet/build \
    -Ijaylib/src \
    -Ijaylib/raylib/src \
    -lm -lpthread -ldl

