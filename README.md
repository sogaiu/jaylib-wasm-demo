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

The "game loop" currently relies on invoking a modified version of
`janet_pcall` named `janet_pcall_keep_env` to invoke Janet code.
`janet_pcall` resets passed fibers (or creates completely new ones)
which implies that dynamic variables are not preserved between
invocations because dynamic variables are associated with specific
fibers.  If `janet_pcall_keep_env` is passed a non-NULL fiber, the
associated environment (and hence dynamic variables) are reused.

An alternative is to use `janet_continue`, which allows one to pass a
fiber which doesn't get reset.  Since the same fiber can be reused
without resetting, dynamic variables can be preserved between
invocations.  However, Emscripten then produces somewhat broken code [1]
unless `ASYNCIFY` is specified when compiling (this was discovered via
a DevTools console message).  Using `ASYNCIFY` does yield running
code, but the resulting code is likely slower due to added
instrumentation.  Additionally, at present, audio hasn't been made to
work for the `janet_continue` + `ASYNCIFY` combination (at least in
this demo)...

In summary, current advice is:

* if audio is desired, either use `janet_pcall` and don't use dynamic
  variables, or use `janet_pcall_keep_env`.
* if audio is unneeded, one can use `janet_continue` instead.

[1] Currently, it's not clear why `ASYNCIFY` is necessary.  bakpakin's
    `webrepl.c` for janet-lang.org's web REPL also uses
    `janet_continue` but `ASYNCIFY` does not appear to be needed
    there.  One difference that might be relevant is that the demo
    would be triggering `janet_continue` via
    `emscripten_set_main_loop`, while `webrepl.c`'s `janet_continue`
    is user-triggered.

## Thanks

* bakpakin
* MikeBeller
* pyrmont
* raysan5
* saikyun
* yumaikas
* ZakharValaha

