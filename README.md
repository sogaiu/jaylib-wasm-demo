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

1. Build janet once to produce amalgamated `janet.c` and patched `janet.h`:

    For *nixen, that's:
    ```
    cd janet
    make
    cd ..
    ```

2. Build [wasm version of `libraylib.a`](https://github.com/raysan5/raylib/wiki/Working-for-Web-(HTML5)#2-compile-raylib-library):

    For *nixen, with emsdk under `~/src/emsdk`, that's something like:
    ```
    source ~/src/emsdk/emsdk_env.sh      # tested with emscripten 3.1.3
    cd jaylib/raylib/src
    make PLATFORM=PLATFORM_WEB -B
    # if the line above fails, try:
    make PLATFORM=PLATFORM_WEB -B -e
    cd ../../..
    ```

3. Build wasm bits (`public` directory will get populated):

    For *nixen, that's:
    ```
    sh build-wasm.sh
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

