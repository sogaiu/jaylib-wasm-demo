# jaylib-wasm-demo

A demo of using [jaylib](https://github.com/janet-lang/jaylib) in a web browser

## Overview

The current approach is to build a small program that embeds [janet](https://janet-lang.org) and is linked to [Raylib](https://www.raylib.com/).  The program loads and executes an example game written in Janet that uses Raylib via jaylib.

The program is made executable in a web browser by being compiled by [Emscripten](https://emscripten.org/).

The goal of this demo is to produce appropriate `.wasm`, `.js`, `.html`, and related files and then to test their functionality via a web browser.  Before compilation via Emscripten can take place, some pieces need to be prepared:

* `main.c` - the aforementioned small program
* `janet.c` + support files - for embedding janet
* `libraylib.a` - "HTML5-ready" Raylib static library
* `game.janet` - a small game written in Janet / jaylib

## Prerequisites

* Emscripten 3.1.3 (other versions might work)
* Usual build tools

## Steps

* Ensure repository has been cloned recursively:
    ```
    git clone --recursive https://github.com/sogaiu/jaylib-wasm-demo
    ```

* Build janet once to produce [an amalgamated `janet.c`](https://janet-lang.org/capi/embedding.html) and `janet.h`-related:

    For *nixen, that's:
    ```
    cd janet
    make
    cd ..
    ```

    For Windows (likely need an appropriate Developer prompt):
    ```
    cd janet
    build_win.bat
    cd ..
    ```

* Build [HTML5-ready `libraylib.a`](https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)#2-compile-raylib-library):

    For *nixen, with emsdk under `~/src/emsdk`, that's something like:
    ```
    source ~/src/emsdk/emsdk_env.sh
    cd jaylib/raylib/src
    make PLATFORM=PLATFORM_WEB -B
    # if the line above fails, try:
    make PLATFORM=PLATFORM_WEB -B -e
    cd ../../..
    ```

    For Windows, with emsdk in a sibling directory of this repository:
    ```
    ..\emsdk\emsdk_env.bat
    cd jaylib\raylib\src
    emcc -c rcore.c -Os -Wall -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
    emcc -c rshapes.c -Os -Wall -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
    emcc -c rtextures.c -Os -Wall -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
    emcc -c rtext.c -Os -Wall -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
    emcc -c rmodels.c -Os -Wall -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES2
    emcc -c utils.c -Os -Wall -DPLATFORM_WEB
    emcc -c raudio.c -Os -Wall -DPLATFORM_WEB
    emar rcs libraylib.a rcore.o rshapes.o rtextures.o rtext.o rmodels.o utils.o raudio.o
    cd ..\..\..
    ```

    Note that on Windows, `emcc` and `emar` are `.bat` files, so if putting some of the lines above in a `.bat` file for convenient execution, using `call` in front of each line using `emcc` or `emar` may be necessary.

* Build wasm bits using [emcc](https://emscripten.org/docs/tools_reference/emcc.html) (a directory named `public` will be created if necessary and populated):

    For *nixen, that's:
    ```
    sh build-wasm.sh
    ```

    For Windows:
    ```
    build-wasm.bat
    ```

* Start a web server to serve the built files:

    For a machine with python3, that might be:
    ```
    python3 -m http.server --directory public
    ```

* Try out the results:

    Visit http://localhost:8000 and click on `main.html`

---

## Thanks

* bakpakin
* MikeBeller
* pyrmont
* raysan5
* saikyun
* yumaikas
* ZakharValaha

