# jaylib-wasm-demo

A demo of using jaylib in a web browser

## Prerequisites

* Emscripten 3.1.3 (other versions might work)
* Usual build tools

## Steps

0. Ensure repository has been cloned recursively:
    ```
    git clone --recursive https://github.com/sogaiu/jaylib-wasm-demo
    ```

1. Build janet once to produce amalgamated `janet.c` and `janet.h`-related:

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

2. Build [wasm version of `libraylib.a`](https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)#2-compile-raylib-library):

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

    Note that on Windows, `emcc` and `emar` are `.bat` files, so if putting some of the lines above in a `.bat` file is desirable, using `call` in front of each line using `emcc` or `emar` may be necessary for things to work.

3. Build wasm bits (`public` directory will get populated):

    For *nixen, that's:
    ```
    sh build-wasm.sh
    ```

    For Windows:
    ```
    build-wasm.bat
    ```

4. Start a web server to serve the built files:

    For a machine with python3, that might be:
    ```
    python3 -m http.server --directory public
    ```

5. Try out the results:

    Visit http://localhost:8000 and click on `main.html`

---

## Thanks

* bakpakin
* MikeBeller
* pyrmont
* saikyun
* yumaikas
* ZakharValaha

