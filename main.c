#include "janet.h"
#include "raylib.h"

#include "types.h"

#include "core.h"
#include "shapes.h"
#include "audio.h"
#include "gestures.h"
#include "text.h"
#include "image.h"
#include "3d.h"

#if defined(PLATFORM_WEB)
#include <emscripten/html5.h>
#endif

static JanetTable* core_env = NULL;

static JanetFiber* game_fiber = NULL;

static JanetFunction* udf_fn = NULL;

void UpdateDrawFrame(void) {
  Janet ret;
  JanetSignal status = janet_pcall(udf_fn, 0, NULL, &ret, &game_fiber);
  if (status == JANET_SIGNAL_ERROR) {
    janet_stacktrace(game_fiber, ret);
    janet_deinit();
    game_fiber = NULL;
    // XXX
    abort();
  }
}

int main(int argc, char** argv) {
  janet_init();

  core_env = janet_core_env(NULL);

  // make jaylib functions available
  janet_cfuns(core_env, NULL, core_cfuns);
  janet_cfuns(core_env, NULL, shapes_cfuns);
  janet_cfuns(core_env, NULL, audio_cfuns);
  janet_cfuns(core_env, NULL, gesture_cfuns);
  janet_cfuns(core_env, NULL, text_cfuns);
  janet_cfuns(core_env, NULL, image_cfuns);
  janet_cfuns(core_env, NULL, threed_cfuns);

  Janet ret;

  int status =
    janet_dostring(core_env,
                   "(import ./resources/game :prefix \"\")\n"
                   // want this in c anyway, so "returning" this
                   "update-draw-frame",
                   "game.janet", &ret);

  if (status == JANET_SIGNAL_ERROR) {
    printf("error loading game\n");
    janet_deinit();
    game_fiber = NULL;
    return -1;
  }

  janet_gcroot(ret);
  udf_fn = janet_unwrap_function(ret);

  game_fiber = janet_fiber(udf_fn, 64, 0, NULL);

#if defined(PLATFORM_WEB)
  // XXX: chrome dev console suggests using framerate of 0
  //emscripten_set_main_loop(UpdateDrawFrame, 60, 1);
  emscripten_set_main_loop(UpdateDrawFrame, 0, 1);
#else
  // XXX: don't use `setdyn` in `desktop`
  status =
    janet_dostring(core_env, "(desktop)", "source", &ret);

  if (status == JANET_SIGNAL_ERROR) {
    printf("error during desktop-specific init\n");
    janet_deinit();
    game_fiber = NULL;
    return -1;
  }

  while (!WindowShouldClose())
  {
    UpdateDrawFrame();
  }
#endif

  janet_deinit();

  return 0;
}
