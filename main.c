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
#include <emscripten/emscripten.h>
#endif

static JanetTable* core_env = NULL;

void UpdateDrawFrame(void)
{
  Janet result;

  //int ret =
  janet_dostring(core_env, "(update-draw-frame)",
                 "source", &result);
}

int main(int argc, char** argv) {
  janet_init();

  core_env = janet_core_env(NULL);

  // make some jaylib functions available
  janet_cfuns(core_env, NULL, core_cfuns);
  janet_cfuns(core_env, NULL, shapes_cfuns);
  janet_cfuns(core_env, NULL, audio_cfuns);
  janet_cfuns(core_env, NULL, gesture_cfuns);
  janet_cfuns(core_env, NULL, text_cfuns);
  janet_cfuns(core_env, NULL, image_cfuns);
  janet_cfuns(core_env, NULL, threed_cfuns);

  Janet result;

  int ret =
    janet_dostring(core_env,
                   "(import ./resources/tetris :prefix \"\")",
                   "tetris.janet", &result);

#if defined(PLATFORM_WEB)
  // XXX: chrome dev console suggests using framerate of 0
  //emscripten_set_main_loop(UpdateDrawFrame, 60, 1);
  emscripten_set_main_loop(UpdateDrawFrame, 0, 1);
#else
  int ret2 =
    janet_dostring(core_env, "(desktop)", "source", &result);
  while (!WindowShouldClose())
  {
    UpdateDrawFrame();
  }
#endif

  janet_deinit();

  return ret;
}
