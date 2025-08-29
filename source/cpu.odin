package main

import "core:fmt"

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
    cb: bool,
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
dTimer: u16
tTimer: u16
tima_ovf: bool
state: State

cpu_step :: proc() {
    if(!halt) {
        if(state.cycle == state.op.cycles || state.cb) {
            state.op = cpu_get_opcode()
            if((!state.cb && state.op.cycles == 1) || (state.cb && state.op.cycles == 2)) {
                state.op.func()
            }
            if(state.cycle == 2) {
                state.cb = false
            }
        } else {
            state.op.func()
            state.cycle += 1
        }
    } else {
        opcodes[0x00].func() //If HALT, NOP
    }
    when(!TEST_ENABLE) {
        if(tima_ovf) {
            cpu_tima_irq()
        }
        cpu_handle_tmr()
        if(state.cycle == state.op.cycles) {
            cpu_handle_irq()
        }
    }
}

cpu_fetch :: proc() -> u8 {
    data := bus_read(PC)
    PC += 1
    return data
}

cpu_get_opcode :: proc() -> Opcode {
    op: Opcode
    
    opcode := cpu_fetch()
    if(halt_bug) {
        PC -= 1
        halt_bug = false
    }
    if(state.cb) { 
        op = cbcodes[opcode]
        state.cycle += 1
    } else {
        op = opcodes[opcode]
        state.cycle = 1
        if(opcode == 0xCB) {
            state.cb = true
        }
    }
    if(op.func == nil && opcode != 0xCB) {
        fmt.println("Unknown opcode: ", opcode)
    }
    state.number = opcode
    return op
}

cpu_handle_irq :: proc() {
    iFlags := bus_read(IO_IF)
    eFlags := bus_read(IO_IE)

    for i :u8= 0; i < 5; i += 1 {
        if(bit_test(iFlags, i) && bit_test(eFlags, i)) {
            halt = false
            if(IME == true) {
                IME = false
                Push(u8(PC >> 8))
                Push(u8(PC))
                bus_set(IO_IF, (iFlags & ~(1 << i)))
                PC = 0x0040 + u16(i) * 0x8
            }
        }
    }
}

cpu_handle_tmr :: proc() {
    //div timer
    dTimer += 4
    if(dTimer >= 256) {
        dTimer -= 256
        div := bus_get(IO_DIV)
        div += 1
        bus_set(IO_DIV, div)
    }

    //tima timer
    tac := bus_get(IO_TAC)
    if(bit_test(tac, 2)) {	//Timer enabled
        tTimer += 4
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
            tima := u16(bus_get(IO_TIMA))
            tima += 1
            if(tima > 255) {
                tima = 0
                tima_ovf = true
            }
            bus_set(IO_TIMA, u8(tima))
        }
    }
}

cpu_tima_irq :: proc() {
    tima := u16(bus_get(IO_TIMA))
    tima = u16(bus_get(IO_TMA))
    iFlags := IRQ(bus_get(IO_IF))
    iFlags.Timer = true
    bus_set(IO_IF, u8(iFlags)) //Set Timer interrupt flag
    tima_ovf = false
}

cpu_setInterrupt :: proc(enabled: bool) {
    IME = enabled
}

cpu_getInterrupt :: proc() -> bool {
    return IME
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