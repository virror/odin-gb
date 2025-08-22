package main

import "core:text/edit"
import "core:fmt"
import sdl "vendor:sdl2"
import sdlttf "vendor:sdl2/ttf"
import sdlimg "vendor:sdl2/image"

SKIP_BIOS :: false
ROM_PATH :: "tests/APOCNOW.GB"
SERIAL_DEBUG :: true

WIN_WIDTH :: 160
WIN_HEIGHT :: 144

Vector2f :: distinct [2]f32
Vector2u :: distinct [2]u32
Vector2i :: distinct [2]i32
Vector3f :: distinct [3]f32
Vector3u :: distinct [3]u32
Vector3i :: distinct [3]i32

exit := false
pause := true
last_pause:= true
redraw := false
@(private="file")
step := false
@(private="file")
window: ^sdl.Window
debug_render: ^sdl.Renderer

main :: proc() {
    sdl.Init(sdl.INIT_VIDEO | sdl.INIT_GAMECONTROLLER)
    defer sdl.Quit()

    sdlttf.Init()
    defer sdlttf.Quit()

    sdlimg.Init(sdlimg.INIT_PNG)
    defer sdlttf.Quit()

    window = sdl.CreateWindow("psx emu", 100, 100, WIN_WIDTH, WIN_HEIGHT,
        sdl.WINDOW_OPENGL)
    assert(window != nil, "Failed to create main window")
    defer sdl.DestroyWindow(window)
    render_init(window)

    debug_window := sdl.CreateWindow("debug", 800, 100, 600, 600,
        sdl.WINDOW_OPENGL | sdl.WINDOW_RESIZABLE)
    assert(debug_window != nil, "Failed to create debug window")
    defer sdl.DestroyWindow(debug_window)
    debug_render = sdl.CreateRenderer(debug_window, -1, sdl.RENDERER_ACCELERATED)
    defer sdl.DestroyRenderer(debug_render)

    //controller := controller_create()
    //defer sdl.GameControllerClose(controller)

    debug_init()
    bus_init()

    when TEST_ENABLE {
        test_all()
    }

    when SKIP_BIOS {
        disable_bootloader()
    }

    bus_load_ROM(ROM_PATH)

    ticks: u16
    step_length :f32= 1.0 / 60.0
    accumulated_time: f32
    prev_time := sdl.GetTicks()

    debug_draw()
    for !exit {
        time := sdl.GetTicks()
        accumulated_time += f32(time - prev_time) / 1000.0
        prev_time = time
        //ticks_to_run :u16= 20//evt_check()
        //ticks = 0
        //for (ticks < ticks_to_run) {
            handle_events()
            if (!pause || step) && !redraw {
                //handle_events()
                cycles := cpu_step()
                //tmr_update_all(cycles)
                ticks += cycles
                //evt_total_ticks += cycles

                redraw = ppu_step(cycles)

                if step {
                    step = false
                    debug_draw()
                    free_all(context.temp_allocator)
                }
            }
            if pause != last_pause {
                debug_draw()
                last_pause = pause
            }

            if ((accumulated_time > step_length) && redraw) {
                // Draw if its time and ppu is ready
                /*sdl.RenderClear(main_render)
                texture = draw_main(ppu.getPixels(), texture)
                sdl.RenderCopy(main_render, texture, NULL, NULL)
                sdl.RenderPresent(main_render)*/
                draw_main(ppu_get_pixels())
                redraw = false
                //frame_cnt += accumulated_time;

                /*if(frame_cnt > 0.25) { //Update frame counter 4 times/s
                    frame_cnt = 0;
                    std::string frames = std::to_string((int)round(1 / accumulated_time));
                    SDL_SetWindowTitle(main_window, (title + " - " + frames + "fps").c_str());
                }*/
                accumulated_time = 0
            }
        //}
    }

}

draw_main :: proc(screen_buffer: []u16) {
    texture := texture_create(WIN_WIDTH, WIN_HEIGHT, &screen_buffer[0])
    render_screen(texture)
    texture_destroy(texture)
}

@(private="file")
handle_events :: proc() {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case sdl.EventType.QUIT:
            exit = true
        case sdl.EventType.WINDOWEVENT:
            if event.window.event == sdl.WindowEventID.CLOSE {
                exit = true
            }
        case:
            //input_process(&event)
            handle_dbg_keys(&event)
        }
    }
}

@(private="file")
handle_dbg_keys :: proc(event: ^sdl.Event) {
    if event.type == sdl.EventType.KEYDOWN {
        #partial switch event.key.keysym.sym {
        case sdl.Keycode.p:
            pause = !pause
        case sdl.Keycode.s:
            step = true
        case sdl.Keycode.ESCAPE:
            exit = true
        }
    }
}

disable_bootloader :: proc() {
    bus_write(u16(IO.BL), 1)
    bus_set(u16(IO.LCDC), 0x91)
    PC = 0x100
    SP = 0xFFFE
}