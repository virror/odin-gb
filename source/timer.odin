package main

import "core:fmt"

Tac :: bit_field u8 {
    speed: u8    | 2,
    enable: bool | 1,
    unused: u8   | 5,
}

div: u16
tma: u8
tima: u16
tac: Tac
tTimer: u16
tima_ovf: bool
old_div_bit: bool

tmr_reset :: proc() {
    div = 0
    tma = 0
    tTimer = 0
    tima_ovf = false
}

tmr_read :: proc(address: u16) -> u8 {
    value: u8
    switch(address) {
    case IO_TMA:
        value = tma | 0xF8
    case IO_DIV:
        value = u8(div >> 8)
    case IO_TIMA:
        value = u8(tima)
    case IO_TAC:
        value = u8(tac)
    }
    return value
}

tmr_write :: proc(address: u16, data: u8) {
    switch(address) {
    case IO_TMA:
        tma = data
    case IO_DIV:
        div = 0
        if(tmr_get_div_bit()) {
            tima += 1
        }
    case IO_TIMA:
        tima = u16(data)
    case IO_TAC:
        tac = Tac(data)
    }
}

tmr_step :: proc() {
    if(tima_ovf) {
        tmr_irq()
    }
    div += 4

    if(tac.enable) {	//Timer enabled
        div_bit := tmr_get_div_bit()
        if(old_div_bit && !div_bit) {   //Falling edge
            tima += 1
            if(tima > 255) {
                tima = 0
                tima_ovf = true
            }
        }
        old_div_bit = div_bit
    }
}

tmr_irq :: proc() {
    tima = u16(tma)
    iFlags := IRQ(bus_get(IO_IF))
    iFlags.Timer = true
    bus_set(IO_IF, u8(iFlags)) //Set Timer interrupt flag
    tima_ovf = false
}

tmr_get_div_bit :: proc() -> bool {
    bit: u8
    switch (tac.speed)
    {
    case 0:
        bit = 9
        break
    case 1:
        bit = 3
        break
    case 2:
        bit = 5
        break
    case 3:
        bit = 7
        break
    }
    return (div & (1 << bit)) != 0
}