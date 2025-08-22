package main

import "core:fmt"
import sdl "vendor:sdl2"

keyState: u8
do_irq: bool

input_step :: proc() {
    keyState = 0xFF
    keys := (sdl.GetKeyboardState(nil))
    
    if(keys[sdl.SCANCODE_A] == 1) {
        input_set_key(0xFE)
    }
    if(keys[sdl.SCANCODE_S] == 1) {
        input_set_key(0xFD)
    }
    if(keys[sdl.SCANCODE_Z] == 1) {
        input_set_key(0xFB)
    }
    if(keys[sdl.SCANCODE_X] == 1) {
        input_set_key(0xF7)
    }
    if(keys[sdl.SCANCODE_RIGHT] == 1) {
        input_set_key(0xEF)
    }
    if(keys[sdl.SCANCODE_LEFT] == 1) {
        input_set_key(0xDF)
    }
    if(keys[sdl.SCANCODE_UP] == 1) {
        input_set_key(0xBF)
    }
    if(keys[sdl.SCANCODE_DOWN] == 1) {
        input_set_key(0x7F)
    }

    if(do_irq) {
        iFlags := IRQ(bus_get(u16(IO.IF)))
        iFlags.Joypad = true
		bus_write(u16(IO.IF), u8(iFlags))
        do_irq = false
    }
}

input_set_key :: proc(key: u8) {
    keyState &= key
    do_irq = true
}