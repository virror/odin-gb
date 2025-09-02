package main

import "core:fmt"

clock_cnt: u16
tranferCounter: u16

serial_step :: proc() {
    if(tranferCounter > 0) {
        clock_cnt += 4
        if(clock_cnt >= 512) {
            clock_cnt -= 512
            tranferCounter += 1
            if(tranferCounter >= 8) { //Transfer done
                tranferCounter = 0
                bus_set(IO_SB, 0xFF)
                bus_set(IO_SC, 0)
                iFlags := IRQ(bus_get(IO_IF))
                iFlags.Serial = true
                bus_write(IO_IF, u8(iFlags))
            }
        }
    } else {
        sc := bus_get(IO_SC)
        if(bit_test(sc, 7)) {
            tranferCounter = 1 //Start transfer
        }
    }
}
