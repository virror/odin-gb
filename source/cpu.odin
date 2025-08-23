package main

import "core:fmt"

Opcode :: struct {
    func: proc(),
	cycles: u8,
	args: u32,
	desc: cstring,
}

Flags :: bit_field u8 {
    unused: u8  | 4,
    C: bool     | 1,
    H: bool     | 1,
    N: bool     | 1,
    Z: bool     | 1,
}

Reg :: struct #raw_union {
    using _: struct { F: Flags, A: u8, C, B, E, D, L, H: u8 },
    using _: struct {AF: u16, BC: u16, DE: u16, HL: u16},
}

reg: Reg
EI: bool
cycleMod: u8
halt: bool
PC: u16
SP: u16
last: Opcode
interruptEnabled: bool
dTimer: u16
tTimer: u16

cpu_step :: proc() -> u16 {
    op: Opcode
    cycleMod = 0
    if !halt {
        op, _ = cpu_get_opcode(false)
        PC += 1
        if (EI) {
            interruptEnabled = true
            EI = false
        }
        op.func()
        last = op
    } else {
        op = opcodes[0x00] //If HALT, NOP
    }
    cpu_handle_irq()
    cpu_handle_tmr(op.cycles + cycleMod)

    return u16(op.cycles + cycleMod)
}

cpu_get_opcode :: proc(debug: bool) -> (Opcode, u8) {
    op: Opcode
    opcode := bus_get(PC)

    if opcode == 0xCB {
        if !debug {
            PC += 1
            op = cbcodes[bus_read8(PC)]
        } else {
            op = cbcodes[bus_read8(PC + 1)]
        }
    } else {
        op = opcodes[opcode]
    }
    if op.func == nil {
        fmt.println("Unknown opcode: ", opcode)
    }
    return op, opcode
}

cpu_handle_irq :: proc() {
    iFlags := bus_get(u16(IO.IF))
    eFlags := bus_get(u16(IO.IE))

    if(iFlags != 0) {
        for i :u8= 0; i < 5; i += 1 {
            if(bit_test(iFlags, i) && bit_test(eFlags, i)) {
                halt = false
                if(interruptEnabled == true) {
                    interruptEnabled = false
                    SP -= 1
                    bus_set(SP, u8(PC >> 8))
                    SP -= 1
                    bus_set(SP, u8(PC))
                    bus_set(u16(IO.IF), (iFlags & ~(1 << i)))
                    PC = 0x0040 + u16(i) * 0x8 //TODO: Must fix for multiple interrupts, lowest priority first
                    cycleMod += 20
                }
            }
        }
    }
}

cpu_handle_tmr :: proc(cycle: u8) {
    //div timer
    dTimer += u16(cycle)
    if(dTimer >= 256) {
        dTimer -= 256
        div := bus_get(u16(IO.DIV))
        div += 1
        bus_set(u16(IO.DIV), div)
    }

    //tima timer
    tac := bus_get(u16(IO.TAC))
    if(bit_test(tac, 2)) {	//Timer enabled
        tTimer += u16(cycle)
        tSpeed := tac & 0x03
        compare :u16= 1024
        switch (tSpeed)
        {
        case 0:
            compare = 1024
            break
        case 1:
            compare = 16
            break
        case 2:
            compare = 64
            break
        case 3:
            compare = 256
            break
        }
        if(tTimer >= compare) {
            tTimer -= compare
            tima := u16(bus_get(u16(IO.TIMA)))
            tima += 1
            if(tima > 255) {
                tima = u16(bus_get(u16(IO.TMA)))
                iFlags := IRQ(bus_get(u16(IO.IF)))
                iFlags.Timer = true
                bus_set(u16(IO.IF), u8(iFlags)) //Set Timer interrupt flag
            }
            bus_set(u16(IO.TIMA), u8(tima))
        }
    }
}

cpu_setInterrupt :: proc(enabled: bool) {
    interruptEnabled = enabled
}

cpu_getInterrupt :: proc() -> bool {
    return interruptEnabled
}

//a + b
cpu_setCarryAdd8 :: proc(a: u8, b: u8) {
    reg.F.C = (a + b) < a
}

//a - b
cpu_setCarrySub8 :: proc(a: u8, b: u8) {
    reg.F.C = b > a
}

//a + b
cpu_setCarryAdd16 :: proc(a: u16, b: u16) {
    reg.F.C = (a + b) < a
}

//a + b
cpu_setCarrySub16 :: proc(a: u16, b: u16) {
    reg.F.C = b > a
}

//a + b
cpu_setHalfAdd8 :: proc(a: u8, b: u8) {
    reg.F.H = (((a & 0x0F) + (b & 0x0F)) & 0x10) == 0x10
}

//a - b
cpu_setHalfSub8 :: proc(a: u8, b: u8) {
    reg.F.H = (b & 0x0F) > (a & 0x0F)
}

//a + b
cpu_setHalfAdd16 :: proc(a: u16, b: u16) {
    reg.F.H = (((a & 0xFFF) + (b & 0xFFF)) & 0x1000) == 0x1000
}

//a - b
cpu_setHalfSub16 :: proc(a: u16, b: u16) {
    reg.F.H = (b & 0xFF) > (a & 0xFF)
}

getReg :: proc(index: Index) -> u8 {
    switch (index)
    {
    case Index.A:
        return reg.A
    case Index.B:
        return reg.B
    case Index.C:
        return reg.C
    case Index.D:
        return reg.D
    case Index.E:
        return reg.E
    case Index.H:
        return reg.H
    case Index.L:
        return reg.L
    case Index.n:
        value := bus_read8(PC)
        PC += 1
        return value
    case Index.HL:
        return bus_read8(reg.HL)
    case:
        return reg.A
    }
}

setReg :: proc(index: Index, value: u8) {
    switch (index)
    {
    case Index.A:
        reg.A = value
        break
    case Index.B:
        reg.B = value
        break
    case Index.C:
        reg.C = value
        break
    case Index.D:
        reg.D = value
        break
    case Index.E:
        reg.E = value
        break
    case Index.H:
        reg.H = value
        break
    case Index.L:
        reg.L = value
        break
    case Index.HL:
        bus_write(reg.HL, value)
        break
    case Index.n:
        //Unused
    }
}