package main

import "core:fmt"

dac_enable: [4]bool

apu_step :: proc() {

}

apu_write :: proc(address: u16, data: u8) {
    switch(address) {
    case u16(IO.NR10):
        break
    case u16(IO.NR11):
        break
    case u16(IO.NR12):
        if((data & 0xF0) == 0) {
            dac_enable[0] = false
        }
        memory[address] = data
        break
    case u16(IO.NR13):
        break
    case u16(IO.NR14):
        break
    case u16(IO.NR21):
        break
    case u16(IO.NR22):
        if((data & 0xF0) == 0) {
            dac_enable[1] = false
        }
        memory[address] = data
        break
    case u16(IO.NR23):
        break
    case u16(IO.NR24):
        break
    case u16(IO.NR30):
        if(bit_get(data, 7) > 0) {
            dac_enable[2] = false
        }
        memory[address] = data
        break
    case u16(IO.NR31):
        break
    case u16(IO.NR32):
        break
    case u16(IO.NR33):
        break
    case u16(IO.NR34):
        break
    case u16(IO.NR41):
        break
    case u16(IO.NR42):
        if((data & 0xF0) == 0) {
            dac_enable[3] = false
        }
        memory[address] = data
        break
    case u16(IO.NR43):
        break
    case u16(IO.NR44):
        break
    case u16(IO.NR50):
        break
    case u16(IO.NR51):
        break
    case u16(IO.NR52):
        if(bit_get(data, 7) > 0) {
            apu_reset()
        }
        break
    }
}

apu_reset :: proc() {
    for i := u16(IO.NR10); i < u16(IO.NR51); i += 1 {
        memory[i] = 0
    }
}