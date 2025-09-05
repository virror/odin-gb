package main

import "core:fmt"
import "core:math"
import "core:strings"
import sdl "vendor:sdl3"

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
@(private="file")
ui_blocking: bool
@(private="file")
window: ^sdl.Window
@(private="file")
input_string: string
@(private="file")
input_idx: int
@(private="file")
input_cursor: ^Ui_element
@(private="file")
input_text: ^Ui_element
@(private="file")
input_timer: f32

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

input_update :: proc(dt: f32) {
    if input_text != nil {
        input_timer += dt
        if input_timer > 0.5 {
            input_timer = 0
            input_cursor.disabled = !input_cursor.disabled
        }
    }
}

input_process :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.KEY_DOWN:
        if text_input_active() {
            switch event.key.key {
            case sdl.K_BACKSPACE:
                text_input_remove()
            case sdl.K_RETURN:
                text_input_stop()
            case sdl.K_LEFT:
                text_input_move(true)
            case sdl.K_RIGHT:
                text_input_move(false)
            case sdl.K_HOME:
                text_input_home()
            case sdl.K_END:
                text_input_end()
            }
        } else {
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
    case sdl.EventType.MOUSE_MOTION:
        mouse_state.position.x = f32(event.motion.x)
        mouse_state.position.y = resolution.y - f32(event.motion.y)
    case sdl.EventType.MOUSE_BUTTON_DOWN:
        mouse_state.button[Mouse_button(event.button.button)] = true
    case sdl.EventType.MOUSE_BUTTON_UP:
        delete_key(&mouse_state.button, Mouse_button(event.button.button))
    case sdl.EventType.TEXT_INPUT:
        text_input_add(string(event.text.text))
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

mouse_down :: proc(i: Mouse_button) -> bool {
    return mouse_state.button[i] && mouse_state.prev_button[i]
}

mouse_pressed_raw :: proc(i: Mouse_button) -> bool {
    return mouse_state.button[i] && !mouse_state.prev_button[i]
}

mouse_released_raw :: proc(i: Mouse_button) -> bool {
    return !mouse_state.button[i] && mouse_state.prev_button[i]
}

mouse_pressed :: proc(i: Mouse_button) -> bool {
    return mouse_state.button[i] && !mouse_state.prev_button[i] && !ui_blocking
}

mouse_released :: proc(i: Mouse_button) -> bool {
    return !mouse_state.button[i] && mouse_state.prev_button[i] && !ui_blocking
}

set_blocking :: proc(blocking: bool) {
    ui_blocking = blocking
}

input_reset :: proc() {
    clear(&mouse_state.prev_button)
    for k, v in mouse_state.button {
        mouse_state.prev_button[k] = v
    }
}

text_input_click :: proc(element: ^Ui_element) {
    if input_text == nil || element._input != input_text {
        text_input_stop()
        text_input_start(element)
    } else {
        posX: f32
        ratio := resolution.y / WIN_HEIGHT

        switch element.anchor {
        case .top_left, .middle_left, .bottom_left:
            posX = mouse_state.position.x / ratio
        case .top_center, .middle_center, .bottom_center:
            posX = (mouse_state.position.x - (resolution.x / 2)) / ratio
        case .top_right, .middle_right, .bottom_right:
            posX = (mouse_state.position.x - resolution.x) / ratio
        }
        posX = posX - input_text.position.x
        text_pos := f32(len(input_string)) * input_text.size.x
        if posX > text_pos {
            input_cursor.position.x = input_text.position.x + text_pos - (input_text.size.x / 2)
        } else {
            posX = math.round(posX / input_text.size.x) * input_text.size.x
            input_cursor.position.x = input_text.position.x + posX - (input_text.size.x / 2)
            input_idx = int(posX / input_text.size.x)
        }
    }
}

text_input_start :: proc(element: ^Ui_element) {
    if sdl.StartTextInput(window) {
        input_text = element._input
        if input_cursor == nil {
            input_cursor = ui_text({-3, 10}, 10, "|", .middle_left, element)
        }
        input_cursor.disabled = false
        input_cursor.size = element._input.size.y
        posX := -(element._input.size.x / 2) + f32(len(element._input.text)) * element._input.size.x
        input_cursor.position = element._input.position + {posX, 0}
        input_cursor.anchor = element._input.anchor
        input_string = element._input.text
        input_idx = len(element._input.text)
    }
}

text_input_stop :: proc() {
    if sdl.StopTextInput(window) {
        if input_cursor != nil {
            input_cursor.disabled = true
        }
        input_text = nil
    }
}

text_input_active :: proc() -> bool {
    return sdl.TextInputActive(window)
}

@(private="file")
text_input_add :: proc(sub_str: string) {
    if input_idx == 0 {
        a := []string { sub_str, input_string}
        input_string = strings.concatenate(a)
    } else if len(input_string) != input_idx {
        string1, _ := strings.substring(input_string, 0, input_idx)
        string2, _ := strings.substring(input_string, input_idx, len(input_string))
        a := []string { string1, sub_str, string2}
        input_string = strings.concatenate(a)
    } else {
        a := []string { input_string, sub_str}
        input_string = strings.concatenate(a)
    }
    input_text.text = input_string
    text_input_cursor(true)
}

@(private="file")
text_input_remove :: proc() {
    if input_idx == 0 {
        return
    } else if len(input_string) != input_idx {
        string1, _ := strings.substring(input_string, 0, input_idx - 1)
        string2, _ := strings.substring(input_string, input_idx, len(input_string))
        a := []string { string1, string2}
        input_string = strings.concatenate(a)
    } else {
        string1, _ := strings.substring(input_string, 0, input_idx - 1)
        input_string = string1
    }
    input_text.text = input_string
    text_input_cursor(false)
}

@(private="file")
text_input_move :: proc(left: bool) {
    if left {
        if input_idx > 0 {
            text_input_cursor(false)
        }
    } else {
        if input_idx < len(input_string) {
            text_input_cursor(true)
        }
    }
}

@(private="file")
text_input_home :: proc() {
    input_idx = 0
    input_cursor.position.x = input_text.position.x + -(input_text.size.x / 2)
    input_timer = 0
    input_cursor.disabled = false
}

@(private="file")
text_input_end :: proc() {
    input_idx = len(input_string)
    posX := -(input_text.size.x / 2) + f32(len(input_text.text)) * input_text.size.x
    input_cursor.position.x = input_text.position.x + posX
    input_timer = 0
    input_cursor.disabled = false
}

@(private="file")
text_input_cursor :: proc(add: bool) {
    if add {
        input_idx += 1
        input_cursor.position.x += input_text.size.x
    } else {
        input_idx -= 1
        input_cursor.position.x -= input_text.size.x
    }
    input_timer = 0
    input_cursor.disabled = false
}