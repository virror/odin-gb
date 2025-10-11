package main

import "core:text/edit"
import "core:fmt"
import "base:runtime"
import sdl "vendor:sdl3"
import sdlttf "vendor:sdl3/ttf"
import "../../odin-libs/emu"

DEBUG :: false
SKIP_BIOS :: false
SERIAL_DEBUG :: false

WIN_WIDTH :: 160
WIN_HEIGHT :: 144
WIN_SCALE :: 2

Vector2f :: distinct [2]f32

exit := false
@(private="file")
pause := true
@(private="file")
redraw := false
@(private="file")
step := false
@(private="file")
window: ^sdl.Window
debug_render: ^sdl.Renderer
file_name: string
@(private="file")
pause_btn: ^emu.Ui_element
@(private="file")
load_btn: ^emu.Ui_element
@(private="file")
resume_btn: ^emu.Ui_element
@(private="file")
bepa: sdl.DialogFileFilter = {name = "Gameboy rom", pattern = "gb"}
game_path: string
resolution: emu.Vector2f

when ODIN_OS == .Darwin {
    WINDOW_TYPE :: sdl.WINDOW_METAL
} else {
    WINDOW_TYPE :: sdl.WINDOW_VULKAN
}

main :: proc() {
    if(!sdl.Init(sdl.INIT_VIDEO | sdl.INIT_GAMEPAD | sdl.INIT_AUDIO)) {
        panic("Failed to init SDL3!")
    }
    defer sdl.Quit()
    
    resolution = {WIN_WIDTH * WIN_SCALE, WIN_HEIGHT * WIN_SCALE}
    window = sdl.CreateWindow("odin-gb", i32(resolution.x), i32(resolution.y), sdl.WINDOW_VULKAN)
    assert(window != nil, "Failed to create main window")
    defer sdl.DestroyWindow(window)
    sdl.SetWindowPosition(window, 200, 200)
    emu.render_init(window)
    emu.render_update_viewport(i32(resolution.x), i32(resolution.y))

    when(DEBUG) {
        if(!sdlttf.Init()) {
            panic("Failed to init sdl3 ttf!")
        }
        defer sdlttf.Quit()

        debug_window: ^sdl.Window
        if(!sdl.CreateWindowAndRenderer("debug", 600, 600, sdl.WINDOW_OPENGL, &debug_window, &debug_render)) {
            panic("Failed to create debug window")
        }
        defer sdl.DestroyWindow(debug_window)
        defer sdl.DestroyRenderer(debug_render)
        sdl.SetWindowPosition(debug_window, 700, 100)

        debug_init()
        defer debug_quit()
    }
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

    when TEST_ENABLE {
        test_all()
        return
    }

    emu.ui_sprite_create_all()
    create_ui()

    step_length :f32= 1.0 / 60.0
    accumulated_time: f32
    prev_time := sdl.GetTicks()

    debug_draw()
    for !exit {
        time := sdl.GetTicks()
        accumulated_time += f32(time - prev_time) / 1000.0
        prev_time = time

        if (!pause || step) && !redraw {
            cpu_step()
            tmr_step()
            redraw = ppu_step()
            serial_step()
            apu_step()

            if step {
                step = false
                debug_draw()
                free_all(context.temp_allocator)
            }
        }

        if ((accumulated_time > step_length)) {
            handle_events()
            emu.ui_process()
            emu.render_pre()
            emu.render_set_shader()
            if(redraw || pause) {
                tex := emu.texture_create(WIN_WIDTH, WIN_HEIGHT, &screen_buffer[0], 2)
                emu.render_quad({
                    texture = tex,
                    position = {-resolution.x / 2, -resolution.y / 2},
                    size = {resolution.x, resolution.y},
                    scale = 1,
                    offset = {0, 0},
                    flip = {0, 0},
                    color = {1, 1, 1, 1},
                })
                emu.texture_destroy(tex)
            }
            redraw = false
            accumulated_time = 0
            emu.ui_render()
            emu.render_post()
        }
    }
    if(bus_has_battery()) {
        bus_save_ram()
    }
}

pause_emu :: proc(do_pause: bool) {
    pause = do_pause
    if(!pause) {
        //sdl.ResumeAudioStreamDevice(audio_stream)
    } else {
        //sdl.PauseAudioStreamDevice(audio_stream)
        debug_draw()
    }
}

@(private="file")
handle_events :: proc() {
    emu.input_reset()
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case sdl.EventType.QUIT:
            exit = true
        case sdl.EventType.WINDOW_CLOSE_REQUESTED:
            exit = true
        case sdl.EventType.WINDOW_MOUSE_ENTER:
            if(!pause) {
                pause_btn.disabled = false
            }
        case sdl.EventType.WINDOW_MOUSE_LEAVE:
            pause_btn.disabled = true
        case sdl.EventType.KEY_DOWN:
            handle_dbg_keys(&event)
        }
        input_process(&event)
    }
}

@(private="file")
handle_dbg_keys :: proc(event: ^sdl.Event) {
    switch event.key.key {
    case sdl.K_S:
        step = true
    case sdl.K_ESCAPE:
        exit = true
    }
}

@(private="file")
reset_all :: proc() {
    ppu_reset()
    apu_reset()
    cpu_reset()
    bus_reset()
    tmr_reset()
}

@(private="file")
create_ui :: proc() {
    pause_btn = emu.ui_button({0, 0}, {245, 245}, pause_game, .middle_center)
    pause_btn.disabled = true
    pause_btn.sprite = emu.ui_sprites[2]
    pause_btn.color = {1, 1, 1, 0.4}

    load_btn = emu.ui_button({0, 0}, {150, 40}, load_game, .middle_center)
    emu.ui_text({0, 0}, 16, "Load game", .middle_center, load_btn)

    resume_btn = emu.ui_button({0, 50}, {150, 40}, resume_game, .middle_center)
    resume_btn.disabled = true
    emu.ui_text({0, 0}, 16, "Resume", .middle_center, resume_btn)
}

@(private="file")
pause_game :: proc(button: ^emu.Ui_element) {
    pause_emu(true)
    pause_btn.disabled = true
    load_btn.disabled = false
    resume_btn.disabled = false
}

@(private="file")
resume_game :: proc(button: ^emu.Ui_element) {
    pause_emu(false)
    pause_btn.disabled = false
    load_btn.disabled = true
    resume_btn.disabled = true
}

@(private="file")
load_game :: proc(button: ^emu.Ui_element) {
    sdl.ShowOpenFileDialog(load_callback, nil, window, &bepa, 1, nil, false)
}

load_callback :: proc "c" (userdata: rawptr, filelist: [^]cstring, filter: i32) {
    context = runtime.default_context()
    game_path = string(filelist[0])
    if(game_path != "") {
        reset_all()
        bus_load_ROM(game_path)
        sdl.SetWindowTitle(window, fmt.caprintf("odin-gb - %s", file_name))
        pause_emu(false)
        load_btn.disabled = true
        resume_btn.disabled = true
        when SKIP_BIOS {
            cpu_disable_bootloader()
        }
    }
}