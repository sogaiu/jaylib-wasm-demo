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

  Janet result;

  const JanetRegExt regs[] = {
    // XXX: JANET_REG didn't work but JANET_REG_ does...why?
    JANET_REG_("set-config-flags", cfun_SetConfigFlags),
    JANET_REG_("set-target-fps", cfun_SetTargetFPS),
    JANET_REG_("set-exit-key", cfun_SetExitKey),
    JANET_REG_("init-window", cfun_InitWindow),
    JANET_REG_("close-window", cfun_CloseWindow),
    JANET_REG_("window-should-close", cfun_WindowShouldClose),
    JANET_REG_("get-screen-height", cfun_GetScreenHeight),
    JANET_REG_("get-screen-width", cfun_GetScreenWidth),
    //
    JANET_REG_("begin-drawing", cfun_BeginDrawing),
    JANET_REG_("end-drawing", cfun_EndDrawing),
    JANET_REG_("clear-background", cfun_ClearBackground),
    //
    JANET_REG_("key-down?", cfun_IsKeyDown),
    JANET_REG_("key-pressed?", cfun_IsKeyPressed),
    //
    JANET_REG_("draw-line", cfun_DrawLine),
    JANET_REG_("draw-rectangle", cfun_DrawRectangle),
    //
    JANET_REG_("draw-text", cfun_DrawText),
    JANET_REG_("measure-text", cfun_MeasureText),
    //
    JANET_REG_("init-audio-device", cfun_InitAudioDevice),
    JANET_REG_("close-audio-device", cfun_CloseAudioDevice),
    JANET_REG_("set-music-volume", cfun_SetMusicVolume),
    JANET_REG_("load-music-stream", cfun_LoadMusicStream),
    JANET_REG_("play-music-stream", cfun_PlayMusicStream),
    JANET_REG_("update-music-stream", cfun_UpdateMusicStream),
    JANET_REG_("pause-music-stream", cfun_PauseMusicStream),
    JANET_REG_("stop-music-stream", cfun_StopMusicStream),
    JANET_REG_("resume-music-stream", cfun_ResumeMusicStream),
    JANET_REG_END
  };

  // make some jaylib functions available
  janet_cfuns_ext(core_env, NULL, regs);

  // read in source for game
  FILE* code_file = fopen("resources/tetris.janet", "rb");
  //FILE* code_file = fopen("resources/rectangle.janet", "rb");
  if (NULL == code_file) {
    fprintf(stderr, "Could not open tetris.janet\n");
    exit(1);
  }
  fseek(code_file, 0, SEEK_END);
  size_t code_size = ftell(code_file);
  fseek(code_file, 0, SEEK_SET);
  unsigned char *code_buffer = janet_malloc(code_size);
  if (NULL == code_buffer) {
    fprintf(stderr, "Failed to allocate code buffer\n");
    exit(1);
  }
  if (!fread(code_buffer, 1, code_size, code_file)) {
    fprintf(stderr, "Failed to read into code buffer\n");
    exit(1);
  }
  fclose(code_file);

  // run source that was read in
  int ret =
    janet_dobytes(core_env, code_buffer, (int32_t) code_size, "source",
                  &result);
  janet_free(code_buffer);

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
