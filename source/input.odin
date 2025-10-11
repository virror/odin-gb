package main

import "core:fmt"
import sdl "vendor:sdl3"
import "../../odin-libs/emu"

Mouse_button :: enum {
    left = 1,
    middle = 2,
    right = 3,
}

Mouse_state :: struct {
    position: Vector2f,
    button: map[Mouse_button]bool,
    prev_button: map[Mouse_button]bool,
}

keyState: u8 = 0xFF
@(private="file")
do_irq: bool

controller_create :: proc() -> ^sdl.Gamepad {
    controller: ^sdl.Gamepad
    count: i32
    ids := sdl.GetGamepads(&count)
    for i in 0 ..< count {
        if sdl.IsGamepad(ids[i]) {
            controller = sdl.OpenGamepad(ids[i])
            if controller != nil {
                break
            }
        }
    }
    return controller
}

input_process :: proc(event: ^sdl.Event) {
    emu.input_process(event)
    #partial switch event.type {
    case sdl.EventType.KEY_DOWN:
        switch event.key.key {
        case sdl.K_A:     // A
            input_set_key(0xFE)
        case sdl.K_S:     // B
            input_set_key(0xFD)
        case sdl.K_Z:     // Select
            input_set_key(0xFB)
        case sdl.K_X:     // Start
            input_set_key(0xF7)
        case sdl.K_RIGHT: // D-pad right
            input_set_key(0xEF)
        case sdl.K_LEFT:  // D-pad left
            input_set_key(0xDF)
        case sdl.K_UP:    // D-pad up
            input_set_key(0xBF)
        case sdl.K_DOWN:  // D-pad down
            input_set_key(0x7F)
        }
    case sdl.EventType.GAMEPAD_BUTTON_DOWN:
        #partial switch sdl.GamepadButton(event.gbutton.button) {
        case sdl.GamepadButton.SOUTH:        // A
            input_set_key(0xFE)
        case sdl.GamepadButton.EAST:         // B
            input_set_key(0xFD)
        case sdl.GamepadButton.BACK:         // Select
            input_set_key(0xFB)
        case sdl.GamepadButton.START:        // Start
            input_set_key(0xF7)
        case sdl.GamepadButton.DPAD_RIGHT:   // D-pad right
            input_set_key(0xEF)
        case sdl.GamepadButton.DPAD_LEFT:    // D-pad left
            input_set_key(0xDF)
        case sdl.GamepadButton.DPAD_UP:      // D-pad up
            input_set_key(0xBF)
        case sdl.GamepadButton.DPAD_DOWN:    // D-pad down
            input_set_key(0x7F)
        }
    case sdl.EventType.KEY_UP:
        switch event.key.key {
        case sdl.K_A:     // A
            input_clear_key(0x01)
        case sdl.K_S:     // B
            input_clear_key(0x02)
        case sdl.K_Z:     // Select
            input_clear_key(0x04)
        case sdl.K_X:     // Start
            input_clear_key(0x08)
        case sdl.K_RIGHT: // D-pad right
            input_clear_key(0x10)
        case sdl.K_LEFT:  // D-pad left
            input_clear_key(0x20)
        case sdl.K_UP:    // D-pad up
            input_clear_key(0x40)
        case sdl.K_DOWN:  // D-pad down
            input_clear_key(0x80)
        }
    case sdl.EventType.GAMEPAD_BUTTON_UP:
        #partial switch sdl.GamepadButton(event.gbutton.button) {
        case sdl.GamepadButton.SOUTH:        // A
            input_clear_key(0x01)
        case sdl.GamepadButton.EAST:         // B
            input_clear_key(0x02)
        case sdl.GamepadButton.BACK:         // Select
            input_clear_key(0x04)
        case sdl.GamepadButton.START:        // Start
            input_clear_key(0x08)
        case sdl.GamepadButton.DPAD_RIGHT:   // D-pad right
            input_clear_key(0x10)
        case sdl.GamepadButton.DPAD_LEFT:    // D-pad left
            input_clear_key(0x20)
        case sdl.GamepadButton.DPAD_UP:      // D-pad up
            input_clear_key(0x40)
        case sdl.GamepadButton.DPAD_DOWN:    // D-pad down
            input_clear_key(0x80)
        }
    }
}

input_set_key :: proc(key: u8) {
    keyState &= key
    iFlags := IRQ(bus_get(IO_IF))
    iFlags.Joypad = true
	bus_write(IO_IF, u8(iFlags))
}

input_clear_key :: proc(key: u8) {
    keyState |= key
    iFlags := IRQ(bus_get(IO_IF))
    iFlags.Joypad = true
	bus_write(IO_IF, u8(iFlags))
}