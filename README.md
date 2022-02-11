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
* Janet

## Steps

* Ensure repository has been cloned recursively:
    ```
    git clone --recursive https://github.com/sogaiu/jaylib-wasm-demo
    ```

* For *nixen, with emsdk under `~/src/emsdk`:
    ```
    source ~/src/emsdk/emsdk_env.sh
    janet build-unix.janet
    ```

* For Windows, with emsdk in a sibling directory of this repository (likely need to do via a Native Tools Command Prompt):
    ```
    ..\emsdk\emsdk_env.bat
    janet build-windows.janet
    ```

* Start a web server to serve the built files:

    For a machine with python3, that might be:
    ```
    python3 -m http.server --directory public
    ```

* Try out the results:

    Visit http://localhost:8000 and click on `main.html`

## Notes

The "game loop" currently relies on invoking `janet_pcall` to invoke
Janet code.  At present, this means dynamic variables from previous
invocations are not preserved as `janet_pcall` resets passed fibers
(or creates completely new ones).  This is at least partly beacuse
dynamic variables are associated with each fiber.

One alternative is to use `janet_continue`, which allows one to pass a
fiber which doesn't get reset.  Since the same fiber can be reused
without resetting, dynamic variables can be preserved between
invocations.  However, Emscripten then produces somewhat broken code
unless `ASYNCIFY` is specified when compiling (this was discovered via
a DevTools console message).  Using `ASYNCIFY` does yield running
code, but the resulting code is likely slower due to added
instrumentation.  Additionally, at present, audio hasn't been made to
work for the `janet_continue` + `ASYNCIFY` combination (at least in
this demo)...

In summary, current advice is:

* if audio is desired, use `janet_pcall` and don't use dynamic variables
* if audio is unneeded, one can use `janet_continue` instead

## Thanks

* bakpakin
* MikeBeller
* pyrmont
* raysan5
* saikyun
* yumaikas
* ZakharValaha

