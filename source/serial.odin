package main

import "core:fmt"

clock_cnt: u16
tranferCounter: u16

serial_step :: proc(cycle: u16) {
    if(tranferCounter > 0) {
        clock_cnt += cycle
        if(clock_cnt >= 512) {
            clock_cnt -= 512
            tranferCounter += 1
            if(tranferCounter >= 8) { //Transfer done
                tranferCounter = 0
                bus_set(u16(IO.SB), 0xFF)
                bus_set(u16(IO.SC), 0)
                iFlags := IRQ(bus_get(u16(IO.IF)))
                iFlags.Serial = true
                bus_write(u16(IO.IF), u8(iFlags))
            }
        }
    } else {
        sc := bus_get(u16(IO.SC))
        if(bit_test(sc, 7)) {
            tranferCounter = 1 //Start transfer
        }
    }
}
