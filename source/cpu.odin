package main

import "core:fmt"

Operation :: enum {
    Fetch,
    CB,
    Execute,
    Irq,
    Dma,
}

Opcode :: struct {
    func: proc(),
	cycles: u8,
	args: u32,
	desc: cstring,
}

State :: struct {
    op: Opcode,
    cycle: u8,
    value: u16,
    number: u8,
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
halt: bool
halt_bug: bool
PC: u16
SP: u16
IME: bool
state: State
operation: Operation
irq_idx: int = -1

cpu_reset :: proc() {
    reg = {}
    halt = false
    halt_bug = false
    PC = 0
    SP = 0
    IME = false
    state = {}
    operation = .Fetch
    irq_idx = -1
}

cpu_step :: proc() {
    switch(operation) {
    case .Fetch:
        state.cycle = 0
        cpu_get_opcode()
        if(state.op.cycles == 1 && operation != .CB) {
            state.op.func()
        }
    case .CB:
        cpu_get_cb()
        if(state.op.cycles == 2) {
            state.op.func()
        }
    case .Execute:
        state.op.func()
    case .Irq:
        cpu_irq_do()
    case .Dma:
        opcodes[0x00].func()
    }
    state.cycle += 1
    if(state.cycle == state.op.cycles) {
        operation = .Fetch
        when(!TEST_ENABLE) {
            cpu_irq_check()
        }
    }
}

cpu_fetch :: proc() -> u8 {
    data := bus_read(PC)
    PC += 1
    return data
}

cpu_get_opcode :: proc() {
    opcode := cpu_fetch()
    op := opcodes[opcode]
    operation = .Execute

    if(halt_bug) {
        PC -= 1
        halt_bug = false
    }
    if(opcode == 0xCB) {
        operation = .CB
        state.op.cycles = 2
    } else {
        state.op = op
    }
    if(op.func == nil && opcode != 0xCB) {
        fmt.println("Unknown opcode: ", opcode)
    }
    state.number = opcode
}

cpu_get_cb :: proc() {
    opcode := cpu_fetch()
    op := cbcodes[opcode]
    operation = .Execute
    state.number = opcode
    state.op = op
}

cpu_irq_check :: proc() {
    iFlags := bus_read(IO_IF)
    eFlags := bus_read(IO_IE)
    i :u8

    for i = 0; i < 5; i += 1 {
        if(bit_test(iFlags, i) && bit_test(eFlags, i)) {
            halt = false
            irq_idx = int(i)
            break
        }
    }
    if(IME == true && irq_idx >= 0) {
        //operation = .Irq
        IME = false
        bus_set(IO_IF, (iFlags & ~(1 << i)))
        //state.op.cycles = 5

        Push(u8(PC >> 8))
        Push(u8(PC))
        irq_idx = -1
        PC = 0x0040 + u16(i) * 0x8
    }
}

cpu_irq_do :: proc() {
    switch(state.cycle) {
    case 0:
        //nop
    case 1:
        //nop
    case 2:
        Push(u8(PC >> 8))
    case 3:
        Push(u8(PC))
    case 4:
        i := u8(irq_idx)
        irq_idx = -1
        PC = 0x0040 + u16(i) * 0x8
    }
}

cpu_setInterrupt :: proc(enabled: bool) {
    IME = enabled
}

cpu_getInterrupt :: proc() -> bool {
    return IME
}

cpu_disable_bootloader :: proc() {
    PC = 0x100
    SP = 0xFFFE
    reg.AF = 0x01B0
    reg.BC = 0x0013
    reg.DE = 0x00D8
    reg.HL = 0x014D
    bus_write(IO_BL, 0x01)
    bus_write(IO_LCDC, 0x91)
    bus_write(IO_STAT, 0x81)
    bus_write(IO_LY, 0x91)
    bus_write(IO_IF, 0xE1)
    bus_write(IO_DIV, 0x18)
    bus_write(IO_BGP, 0xFC)
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
        value := cpu_fetch()
        return value
    case Index.HL:
        return bus_read(reg.HL)
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