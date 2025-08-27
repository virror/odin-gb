package main

import "core:text/edit"
import "core:fmt"
import sdl "vendor:sdl2"
import sdlttf "vendor:sdl2/ttf"
import sdlimg "vendor:sdl2/image"

SKIP_BIOS :: false
ROM_PATH :: "tests/bgbtest.gb"
SERIAL_DEBUG :: true

WIN_WIDTH :: 160
WIN_HEIGHT :: 144
WIN_SCALE :: 2

Vector2f :: distinct [2]f32
Vector3f :: distinct [3]f32

exit := false
pause := true
last_pause:= true
redraw := false
@(private="file")
step := false
@(private="file")
window: ^sdl.Window
debug_render: ^sdl.Renderer
file_name: string

main :: proc() {
    sdl.Init(sdl.INIT_VIDEO | sdl.INIT_GAMECONTROLLER | sdl.INIT_AUDIO)
    defer sdl.Quit()

    sdlttf.Init()
    defer sdlttf.Quit()

    sdlimg.Init(sdlimg.INIT_PNG)
    defer sdlttf.Quit()

    window = sdl.CreateWindow("odin-gb", 100, 100, WIN_WIDTH * WIN_SCALE, WIN_HEIGHT * WIN_SCALE,
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

    controller := controller_create()
    defer sdl.GameControllerClose(controller)

    // Audio stuff
    desired: sdl.AudioSpec
    obtained: sdl.AudioSpec

    desired.freq = 48000
    desired.format = sdl.AUDIO_F32
    desired.channels = 1
    desired.samples = 64
    desired.callback = nil//audio_handler

    device := sdl.OpenAudioDevice(
        nil,
        false,
        &desired,
        &obtained,
        false,
    )
    defer sdl.CloseAudioDevice(device)
    assert(device != 0, "Failed to create audio device") // TODO: Handle error

    debug_init()
    bus_init()

    when TEST_ENABLE {
        test_all()
        return
    }

    when SKIP_BIOS {
        disable_bootloader()
    }

    bus_load_ROM(ROM_PATH)
    sdl.SetWindowTitle(window, fmt.caprintf("odin-gb - %s", file_name))

    step_length :f32= 1.0 / 60.0
    accumulated_time: f32
    prev_time := sdl.GetTicks()

    debug_draw()
    for !exit {
        time := sdl.GetTicks()
        accumulated_time += f32(time - prev_time) / 1000.0
        prev_time = time

        handle_events()
        if (!pause || step) && !redraw {
            cpu_step()
            redraw = ppu_step(4)
            serial_step(4)
            apu_step()

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
            draw_main(ppu_get_pixels())
            redraw = false
            accumulated_time = 0
        }
    }
    if(bus_has_battery()) {
        bus_save_ram()
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
        case sdl.EventType.KEYDOWN:
            handle_dbg_keys(&event)
        }
        input_process(&event)
    }
}

@(private="file")
handle_dbg_keys :: proc(event: ^sdl.Event) {
    #partial switch event.key.keysym.sym {
    case sdl.Keycode.p:
        pause = !pause
    case sdl.Keycode.s:
        step = true
    case sdl.Keycode.ESCAPE:
        exit = true
    }
}

disable_bootloader :: proc() {
    bus_write(u16(IO.BL), 1)
    bus_set(u16(IO.LCDC), 0x91)
    PC = 0x100
    SP = 0xFFFE
}