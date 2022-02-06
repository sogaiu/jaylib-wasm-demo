#! /bin/sh

# XXX: make janet once before proceeding, e.g.
#
#      cd janet && make
#
#      this should produce a build subdirectory in janet with some bits

# XXX: make libraylib.a also, e.g.
#
#      cd jaylib/raylib/src
#      make
#
#      this should produce libraylib.a in jaylib/raylib

# XXX: only tested on linux
gcc \
    -O2 -Wall \
    -o main \
    main.c \
    janet/build/c/janet.c jaylib/raylib/libraylib.a \
    -Ijanet/build \
    -Ijaylib/src \
    -Ijaylib/raylib/src \
    -lm -lpthread -ldl

