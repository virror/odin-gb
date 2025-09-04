package main

import "core:text/edit"
import "core:fmt"
import sdl "vendor:sdl3"
import sdlttf "vendor:sdl3/ttf"
import sdlimg "vendor:sdl3/image"

SKIP_BIOS :: false
ROM_PATH :: "roms/Legend of Zelda, The - Link's Awakening (USA, Europe).gb"
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
    if(!sdl.Init(sdl.INIT_VIDEO | sdl.INIT_GAMEPAD | sdl.INIT_AUDIO)) {
        panic("Failed to init SDL3!")
    }
    defer sdl.Quit()

    sdlttf.Init()
    defer sdlttf.Quit()
    
    window = sdl.CreateWindow("odin-gb", WIN_WIDTH * WIN_SCALE, WIN_HEIGHT * WIN_SCALE, sdl.WINDOW_VULKAN)
    assert(window != nil, "Failed to create main window")
    defer sdl.DestroyWindow(window)
    sdl.SetWindowPosition(window, 200, 200)
    render_init(window)

    debug_window: ^sdl.Window
    if(!sdl.CreateWindowAndRenderer("debug", 600, 600, sdl.WINDOW_VULKAN, &debug_window, &debug_render)) {
        panic("Failed to create debug window")
    }
    defer sdl.DestroyWindow(debug_window)
    defer sdl.DestroyRenderer(debug_render)
    sdl.SetWindowPosition(debug_window, 700, 100)

    controller := controller_create()
    defer sdl.CloseGamepad(controller)

    // Audio stuff
    desired: sdl.AudioSpec
    desired.freq = 48000
    desired.format = sdl.AudioFormat.F32
    desired.channels = 1
    //desired.samples = 64

    device := sdl.OpenAudioDeviceStream(sdl.AUDIO_DEVICE_DEFAULT_PLAYBACK, &desired, nil, nil)
    defer sdl.ClearAudioStream(device)
    assert(device != nil, "Failed to create audio device") // TODO: Handle error

    debug_init()
    bus_init()

    when TEST_ENABLE {
        test_all()
        return
    }

    when SKIP_BIOS {
        cpu_disable_bootloader()
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
            redraw = ppu_step()
            serial_step()
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
    render_pre()
    render_set_shader()
    render_quad()
    render_post()
    texture_destroy(texture)
}

@(private="file")
handle_events :: proc() {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case sdl.EventType.QUIT:
            exit = true
        case sdl.EventType.WINDOW_CLOSE_REQUESTED:
            exit = true
        case sdl.EventType.KEY_DOWN:
            handle_dbg_keys(&event)
        }
        input_process(&event)
    }
}

@(private="file")
handle_dbg_keys :: proc(event: ^sdl.Event) {
    switch event.key.key {
    case sdl.K_P:
        pause = !pause
    case sdl.K_S:
        step = true
    case sdl.K_ESCAPE:
        exit = true
    }
}