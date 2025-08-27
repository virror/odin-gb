package main

import "core:fmt"
import sdl "vendor:sdl2"

keyState: u8 = 0xFF
do_irq: bool

controller_create :: proc() -> ^sdl.GameController {
    controller: ^sdl.GameController
    for i in 0 ..< sdl.NumJoysticks() {
        if sdl.IsGameController(i) {
            controller = sdl.GameControllerOpen(i)
            if controller != nil {
                fmt.println("a")
                break
            }
        }
    }
    return controller
}

input_process :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.KEYDOWN:
        #partial switch event.key.keysym.sym {
        case sdl.Keycode.A:     // A
            input_set_key(0xFE)
        case sdl.Keycode.S:     // B
            input_set_key(0xFD)
        case sdl.Keycode.Z:     // Select
            input_set_key(0xFB)
        case sdl.Keycode.X:     // Start
            input_set_key(0xF7)
        case sdl.Keycode.RIGHT: // D-pad right
            input_set_key(0xEF)
        case sdl.Keycode.LEFT:  // D-pad left
            input_set_key(0xDF)
        case sdl.Keycode.UP:    // D-pad up
            input_set_key(0xBF)
        case sdl.Keycode.DOWN:  // D-pad down
            input_set_key(0x7F)
        
        }
    case sdl.EventType.CONTROLLERBUTTONDOWN:
        #partial switch sdl.GameControllerButton(event.cbutton.button) {
        case sdl.GameControllerButton.A:            // A
            input_set_key(0xFE)
        case sdl.GameControllerButton.B:            // B
            input_set_key(0xFD)
        case sdl.GameControllerButton.BACK:         // Select
            input_set_key(0xFB)
        case sdl.GameControllerButton.START:        // Start
            input_set_key(0xF7)
        case sdl.GameControllerButton.DPAD_RIGHT:   // D-pad right
            input_set_key(0xEF)
        case sdl.GameControllerButton.DPAD_LEFT:    // D-pad left
            input_set_key(0xDF)
        case sdl.GameControllerButton.DPAD_UP:      // D-pad up
            input_set_key(0xBF)
        case sdl.GameControllerButton.DPAD_DOWN:    // D-pad down
            input_set_key(0x7F)
        }
    case sdl.EventType.KEYUP:
        #partial switch event.key.keysym.sym {
        case sdl.Keycode.A:     // A
            input_clear_key(0x01)
        case sdl.Keycode.S:     // B
            input_clear_key(0x02)
        case sdl.Keycode.Z:     // Select
            input_clear_key(0x04)
        case sdl.Keycode.X:     // Start
            input_clear_key(0x08)
        case sdl.Keycode.RIGHT: // D-pad right
            input_clear_key(0x10)
        case sdl.Keycode.LEFT:  // D-pad left
            input_clear_key(0x20)
        case sdl.Keycode.UP:    // D-pad up
            input_clear_key(0x40)
        case sdl.Keycode.DOWN:  // D-pad down
            input_clear_key(0x80)
        }
    case sdl.EventType.CONTROLLERBUTTONUP:
        #partial switch sdl.GameControllerButton(event.cbutton.button) {
        case sdl.GameControllerButton.A:            // A
            input_clear_key(0x01)
        case sdl.GameControllerButton.B:            // B
            input_clear_key(0x02)
        case sdl.GameControllerButton.BACK:         // Select
            input_clear_key(0x04)
        case sdl.GameControllerButton.START:        // Start
            input_clear_key(0x08)
        case sdl.GameControllerButton.DPAD_RIGHT:   // D-pad right
            input_clear_key(0x10)
        case sdl.GameControllerButton.DPAD_LEFT:    // D-pad left
            input_clear_key(0x20)
        case sdl.GameControllerButton.DPAD_UP:      // D-pad up
            input_clear_key(0x40)
        case sdl.GameControllerButton.DPAD_DOWN:    // D-pad down
            input_clear_key(0x80)
        }
    }
}

input_set_key :: proc(key: u8) {
    keyState &= key
    iFlags := IRQ(bus_get(u16(IO.IF)))
    iFlags.Joypad = true
	bus_write(u16(IO.IF), u8(iFlags))
}

input_clear_key :: proc(key: u8) {
    keyState |= key
    iFlags := IRQ(bus_get(u16(IO.IF)))
    iFlags.Joypad = true
	bus_write(u16(IO.IF), u8(iFlags))
}