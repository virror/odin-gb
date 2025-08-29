package main

import "core:fmt"

dac_enable: [4]bool

apu_step :: proc() {

}

apu_write :: proc(address: u16, data: u8) {
    switch(address) {
    case IO_NR10:
        break
    case IO_NR11:
        break
    case IO_NR12:
        if((data & 0xF0) == 0) {
            dac_enable[0] = false
        }
        memory[address] = data
        break
    case IO_NR13:
        break
    case IO_NR14:
        break
    case IO_NR21:
        break
    case IO_NR22:
        if((data & 0xF0) == 0) {
            dac_enable[1] = false
        }
        memory[address] = data
        break
    case IO_NR23:
        break
    case IO_NR24:
        break
    case IO_NR30:
        if(bit_get(data, 7) > 0) {
            dac_enable[2] = false
        }
        memory[address] = data
        break
    case IO_NR31:
        break
    case IO_NR32:
        break
    case IO_NR33:
        break
    case IO_NR34:
        break
    case IO_NR41:
        break
    case IO_NR42:
        if((data & 0xF0) == 0) {
            dac_enable[3] = false
        }
        memory[address] = data
        break
    case IO_NR43:
        break
    case IO_NR44:
        break
    case IO_NR50:
        break
    case IO_NR51:
        break
    case IO_NR52:
        if(bit_get(data, 7) > 0) {
            apu_reset()
        }
        break
    }
}

apu_reset :: proc() {
    for i := IO_NR10; i < IO_NR51; i += 1 {
        memory[i] = 0
    }
}