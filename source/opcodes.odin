package main

import "core:fmt"
import "base:intrinsics"

Index :: enum {
	A,
	B,
	C,
	D,
	E,
	H,
	L,
	n,
	HL,
}

opcodes: [256]Opcode = {
    {OC00, 4,  0, "NOP"},
    {OC01, 12, 2, "LD BC, nn"},
    {OC02, 8,  0, "LD (BC), A"},
    {OC03, 8,  0, "INC BC"},
    {OC04, 4,  0, "INC B"},
    {OC05, 4,  0, "DEC B"},
    {OC06, 8,  1, "LD B, n"},
    {OC07, 4,  0, "RLCA"},
    {OC08, 20, 2, "LD nn, SP"},
    {OC09, 8,  0, "ADD HL, BC"},
    {OC0A, 8,  0, "LD A, (BC)"},
    {OC0B, 8,  0, "DEC BC"},
    {OC0C, 4,  0, "INC C"},
    {OC0D, 4,  0, "DEC C"},
    {OC0E, 8,  1, "LD C, n"},
    {OC0F, 4,  0, "RRCA"},
    {OC10, 4,  0, "STOP"},
    {OC11, 12, 2, "LD DE, nn"},
    {OC12, 8,  0, "LD (DE), A"},
    {OC13, 8,  0, "INC DE"},
    {OC14, 4,  0, "INC D"},
    {OC15, 4,  0, "DEC D"},
    {OC16, 8,  1, "LD D, n"},
    {OC17, 4,  0, "RLA"},
    {OC18, 12, 1, "JR n"},
    {OC19, 8,  0, "ADD HL, DE"},
    {OC1A, 8,  0, "LD A, (DE)"},
    {OC1B, 8,  0, "DEC DE"},
    {OC1C, 4,  0, "INC E"},
    {OC1D, 4,  0, "DEC E"},
    {OC1E, 8,  1, "LD E, n"},
    {OC1F, 4,  0, "RRA"},
    {OC20, 8,  1, "JR NZ, n"},
    {OC21, 12, 2, "LD HL, nn"},
    {OC22, 8,  0, "LD (HL+), A"},
    {OC23, 8,  0, "INC HL"},
    {OC24, 4,  0, "INC H"},
    {OC25, 4,  0, "DEC H"},
    {OC26, 8,  1, "LD H, n"},
    {OC27, 4,  0, "DAA"},
    {OC28, 8,  1, "JR Z, n"},
    {OC29, 8,  0, "ADD HL, HL"},
    {OC2A, 8,  0, "LD A (HL+)"},
    {OC2B, 8,  0, "DEC HL"},
    {OC2C, 4,  0, "INC L"},
    {OC2D, 4,  0, "DEC L"},
    {OC2E, 8,  1, "LD L, n"},
    {OC2F, 4,  0, "CPL"},
    {OC30, 8,  1, "JR NC, n"},
    {OC31, 12, 2, "LD SP, nn"},
    {OC32, 8,  0, "LD (HL-), A"},
    {OC33, 8,  0, "INC SP"},
    {OC34, 12, 0, "INC (HL)"},
    {OC35, 12, 0, "DEC (HL)"},
    {OC36, 12, 1, "LD (HL), n"},
    {OC37, 4,  0, "SCF"},
    {OC38, 8,  1, "JR C, n"},
    {OC39, 8,  0, "ADD HL, SP"},
    {OC3A, 8,  0, "LD A (HL-)"},
    {OC3B, 8,  0, "DEC SP"},
    {OC3C, 4,  0, "INC A"},
    {OC3D, 4,  0, "DEC A"},
    {OC3E, 8,  1, "LD A, n"},
    {OC3F, 4,  0, "CCF"},
    {OC40, 4,  0, "LD B, B"},
    {OC41, 4,  0, "LD B, C"},
    {OC42, 4,  0, "LD B, D"},
    {OC43, 4,  0, "LD B, E"},
    {OC44, 4,  0, "LD B, H"},
    {OC45, 4,  0, "LD B, L"},
    {OC46, 8,  0, "LD B, (HL)"},
    {OC47, 4,  0, "LD B, A"},
    {OC48, 4,  0, "LD C, B"},
    {OC49, 4,  0, "LD C, C"},
    {OC4A, 4,  0, "LD C, D"},
    {OC4B, 4,  0, "LD C, E"},
    {OC4C, 4,  0, "LD C, H"},
    {OC4D, 4,  0, "LD C, L"},
    {OC4E, 8,  0, "LD C, (HL)"},
    {OC4F, 4,  0, "LD C, A"},
    {OC50, 4,  0, "LD D, B"},
    {OC51, 4,  0, "LD D, C"},
    {OC52, 4,  0, "LD D, D"},
    {OC53, 4,  0, "LD D, E"},
    {OC54, 4,  0, "LD D, H"},
    {OC55, 4,  0, "LD D, L"},
    {OC56, 8,  0, "LD D, (HL)"},
    {OC57, 4,  0, "LD D, A"},
    {OC58, 4,  0, "LD E, B"},
    {OC59, 4,  0, "LD E, C"},
    {OC5A, 4,  0, "LD E, D"},
    {OC5B, 4,  0, "LD E, E"},
    {OC5C, 4,  0, "LD E, H"},
    {OC5D, 4,  0, "LD E, L"},
    {OC5E, 8,  0, "LD E, (HL)"},
    {OC5F, 4,  0, "LD E, A"},
    {OC60, 4,  0, "LD H, B"},
    {OC61, 4,  0, "LD H, C"},
    {OC62, 4,  0, "LD H, D"},
    {OC63, 4,  0, "LD H, E"},
    {OC64, 4,  0, "LD H, H"},
    {OC65, 4,  0, "LD H, L"},
    {OC66, 8,  0, "LD E, (HL)"},
    {OC67, 4,  0, "LD H, A"},
    {OC68, 4,  0, "LD L, B"},
    {OC69, 4,  0, "LD L, C"},
    {OC6A, 4,  0, "LD L, D"},
    {OC6B, 4,  0, "LD L, E"},
    {OC6C, 4,  0, "LD L, H"},
    {OC6D, 4,  0, "LD L, L"},
    {OC6E, 8,  0, "LD L, (HL)"},
    {OC6F, 4,  0, "LD L, A"},
    {OC70, 8,  0, "LD (HL), B"},
    {OC71, 8,  0, "LD (HL), C"},
    {OC72, 8,  0, "LD (HL), D"},
    {OC73, 8,  0, "LD (HL), E"},
    {OC74, 8,  0, "LD (HL), H"},
    {OC75, 8,  0, "LD (HL), L"},
    {OC76, 4,  0, "HALT"},
    {OC77, 8,  0, "LD (HL), A"},
    {OC78, 4,  0, "LD A, B"},
    {OC79, 4,  0, "LD A, C"},
    {OC7A, 4,  0, "LD A, D"},
    {OC7B, 4,  0, "LD A, E"},
    {OC7C, 4,  0, "LD A, H"},
    {OC7D, 4,  0, "LD A, L"},
    {OC7E, 8,  0, "LD A, (HL)"},
    {OC7F, 4,  0, "LD A, A"},
    {OC80, 4,  0, "ADD A, B"},
    {OC81, 4,  0, "ADD A, C"},
    {OC82, 4,  0, "ADD A, D"},
    {OC83, 4,  0, "ADD A, E"},
    {OC84, 4,  0, "ADD A, H"},
    {OC85, 4,  0, "ADD A, L"},
    {OC86, 8,  0, "ADD A, (HL)"},
    {OC87, 4,  0, "ADD A, A"},
    {OC88, 4,  1, "ADC A, B"},
    {OC89, 4,  1, "ADC A, C"},
    {OC8A, 4,  1, "ADC A, D"},
    {OC8B, 4,  1, "ADC A, E"},
    {OC8C, 4,  1, "ADC A, H"},
    {OC8D, 4,  1, "ADC A, L"},
    {OC8E, 8,  1, "ADC A, (HL)"},
    {OC8F, 4,  1, "ADC A, A"},
    {OC90, 4,  0, "SUB A, B"},
    {OC91, 4,  0, "SUB A, C"},
    {OC92, 4,  0, "SUB A, D"},
    {OC93, 4,  0, "SUB A, E"},
    {OC94, 4,  0, "SUB A, H"},
    {OC95, 4,  0, "SUB A, L"},
    {OC96, 8,  0, "SUB A, (HL)"},
    {OC97, 4,  0, "SUB A, A"},
    {OC98, 4,  1, "SBC A, B"},
    {OC99, 4,  1, "SBC A, C"},
    {OC9A, 4,  1, "SBC A, D"},
    {OC9B, 4,  1, "SBC A, E"},
    {OC9C, 4,  1, "SBC A, H"},
    {OC9D, 4,  1, "SBC A, L"},
    {OC9E, 8,  1, "SBC A, (HL)"},
    {OC9F, 4,  1, "SBC A, A"},
    {OCA0, 4,  0, "AND A, B"},
    {OCA1, 4,  0, "AND A, C"},
    {OCA2, 4,  0, "AND A, D"},
    {OCA3, 4,  0, "AND A, E"},
    {OCA4, 4,  0, "AND A, H"},
    {OCA5, 4,  0, "AND A, L"},
    {OCA6, 8,  0, "AND A, (HL)"},
    {OCA7, 4,  0, "AND A, A"},
    {OCA8, 4,  0, "XOR A, B"},
    {OCA9, 4,  0, "XOR A, C"},
    {OCAA, 4,  0, "XOR A, D"},
    {OCAB, 4,  0, "XOR A, E"},
    {OCAC, 4,  0, "XOR A, H"},
    {OCAD, 4,  0, "XOR A, L"},
    {OCAE, 8,  0, "XOR A, (HL)"},
    {OCAF, 4,  0, "XOR A, A"},
    {OCB0, 4,  0, "OR A, B"},
    {OCB1, 4,  0, "OR A, C"},
    {OCB2, 4,  0, "OR A, D"},
    {OCB3, 4,  0, "OR A, E"},
    {OCB4, 4,  0, "OR A, H"},
    {OCB5, 4,  0, "OR A, L"},
    {OCB6, 8,  0, "OR A, (HL)"},
    {OCB7, 4,  0, "OR A, A"},
    {OCB8, 4,  0, "CP A, B"},
    {OCB9, 4,  0, "CP A, C"},
    {OCBA, 4,  0, "CP A, D"},
    {OCBB, 4,  0, "CP A, E"},
    {OCBC, 4,  0, "CP A, H"},
    {OCBD, 4,  0, "CP A, L"},
    {OCBE, 8,  0, "CP A, (HL)"},
    {OCBF, 4,  0, "CP A, A"},
    {OCC0, 8,  0, "RET NZ"},
    {OCC1, 12, 0, "POP BC"},
    {OCC2, 12, 2, "JP NZ, nn"},
    {OCC3, 16, 2, "JP, nn"},
    {OCC4, 12, 2, "CALL NZ, nn"},
    {OCC5, 16, 0, "PUSH BC"},
    {OCC6, 8,  1, "ADD A, n"},
    {OCC7, 16, 0, "RST 0x00"},
    {OCC8, 8,  0, "RET Z"},
    {OCC9, 16, 0, "RET"},
    {OCCA, 12, 2, "JP Z, nn"},
    {nil, 4,  0, "N/A"},
    {OCCC, 12, 2, "CALL Z, nn"},
    {OCCD, 24, 2, "CALL, nn"},
    {OCCE, 8 , 1, "ADC A, n"},
    {OCCF, 16, 0, "RST 0x08"},
    {OCD0, 8,  0, "RET NC"},
    {OCD1, 12, 0, "POP DE"},
    {OCD2, 12, 2, "JP NC, nn"},
    {nil, 4,  0, "N/A"},
    {OCD4, 12, 2, "CALL NC, nn"},
    {OCD5, 16, 0, "PUSH DE"},
    {OCD6, 8,  1, "SUB n"},
    {OCD7, 16, 0, "RST 0x10"},
    {OCD8, 8,  0, "RET C"},
    {OCD9, 16, 0, "RETI"},
    {OCDA, 12, 2, "JP C, nn"},
    {nil, 4,  0, "N/A"},
    {OCDC, 12, 2, "CALL C, nn"},
    {nil, 4,  0, "N/A"},
    {OCDE, 8,  1, "SBC A, n"},
    {OCDF, 16, 0, "RST 0x18"},
    {OCE0, 12, 1, "LDH 0xFFn, A"},
    {OCE1, 12, 0, "POP HL"},
    {OCE2, 8,  0, "LD 0xFF00 + C, A"},
    {nil, 4,  0, "N/A"},
    {nil, 4,  0, "N/A"},
    {OCE5, 16, 0, "PUSH HL"},
    {OCE6, 8,  1, "AND A, n"},
    {OCE7, 16, 0, "RST 0x20"},
    {OCE8, 16, 1, "ADD SP, n"},
    {OCE9, 4,  0, "JP (HL)"},
    {OCEA, 16, 2, "LD nn, A"},
    {nil, 4,  0, "N/A"},
    {nil, 4,  0, "N/A"},
    {nil, 4,  0, "N/A"},
    {OCEE, 8,  1, "XOR A, n"},
    {OCEF, 16, 0, "RST 0x28"},
    {OCF0, 12, 1, "LD A, 0xFFn"},
    {OCF1, 12, 0, "POP AF"},
    {OCF2, 8,  0, "LD A, 0xFF00 + C"},
    {OCF3, 4,  0, "DI"},
    {nil, 4,  0, "N/A"},
    {OCF5, 16, 0, "PUSH AF"},
    {OCF6, 8,  1, "OR A, n"},
    {OCF7, 16, 0, "RST 0x30"},
    {OCF8, 12, 1, "LD HL, SP + n"},
    {OCF9, 8,  0, "LD SP, HL"},
    {OCFA, 16, 2, "LD A, nn"},
    {OCFB, 4,  0, "EI"},
    {nil, 4,  0, "N/A"},
    {nil, 4,  0, "N/A"},
    {OCFE, 8,  1, "CP A, n"},
    {OCFF, 16, 0, "RST 0x38"},
}

//NOP
OC00 :: proc() {
}

//LD BC, nn
OC01 :: proc() {
	reg.C = bus_read8(PC)
    reg.B = bus_read8(PC + 1)
    PC += 2
}

//LD (BC), A
OC02 :: proc() {
    bus_write(reg.BC, reg.A)
}

//INC BC
OC03 :: proc() {
    bus_dummy()
    reg.BC += 1
}

//RLCA
OC07 :: proc() {
    msb := bit_get(reg.A, 7) //MSB ends up in LSB
    reg.A = (reg.A << 1) //Shift
    reg.A |= msb

    reg.F.N = false
    reg.F.H = false
    reg.F.C = (msb != 0)
    reg.F.Z = false
}

//LD nn, SP
OC08 :: proc() {
    addr := u16(bus_read8(PC))
    addr += u16(bus_read8(PC + 1)) << 8
    bus_write(addr, u8(SP))
    bus_write(addr + 1, u8(SP >> 8))
    PC += 2
}

//ADD HL, BC
OC09 :: proc() {
    bus_dummy()
    reg.F.N = false
    cpu_setHalfAdd16(reg.HL, reg.BC)
    cpu_setCarryAdd16(reg.HL, reg.BC)
    reg.HL += reg.BC
}

//LD A, (BC)
OC0A :: proc() {
    reg.A = bus_read8(reg.BC)
}

//DEC BC
OC0B :: proc() {
    bus_dummy()
    reg.BC -= 1
}

//RRCA
OC0F :: proc() {
    lsb := bit_get(reg.A, 0)
    reg.A = (reg.A >> 1) //Shift
    reg.A |= (lsb << 7)

    reg.F.N = false
    reg.F.H = false
    reg.F.C = (lsb != 0)
    reg.F.Z = false
}

//STOP
OC10 :: proc() {
    bus_dummy()
    bus_dummy()
    //TODO Stop
    //fmt.println("STOP")
}

//LD DE, nn
OC11 :: proc() {
    reg.E = bus_read8(PC)
    reg.D = bus_read8(PC + 1)
    PC += 2
}

//LD (DE), A
OC12 :: proc() {
    bus_write(reg.DE, reg.A)
}

//INC DE
OC13 :: proc() {
    bus_dummy()
    reg.DE += 1
}

//RLA
OC17 :: proc() {
    value := reg.A
    newValue := (value << 1) //Shift
    newValue |= (reg.F.C?1:0) //Add carry
    reg.A = newValue

    reg.F.N = false
    reg.F.H = false
    reg.F.C = bit_test(value, 7)
    reg.F.Z = false
}

//JR n
OC18 :: proc() {
    pc := PC
    PC = u16(i16(PC) + i16(i8(bus_read8(pc))) + 1)
    bus_dummy()
}

//ADD HL, DE
OC19 :: proc() {
    bus_dummy()
    reg.F.N = false
    cpu_setHalfAdd16(reg.HL, reg.DE)
    cpu_setCarryAdd16(reg.HL, reg.DE)
    reg.HL += reg.DE
}

//LD A, (DE)
OC1A :: proc() {
    reg.A = bus_read8(reg.DE)
}

//DEC DE
OC1B :: proc() {
    bus_dummy()
    reg.DE -= 1
}

//RRA
OC1F :: proc() {
    value := reg.A
    newValue := (value >> 1) //Shift
    newValue |= (reg.F.C?0x80:0) //Add carry
    reg.A = newValue

    reg.F.N = false
    reg.F.H = false
    reg.F.C = bit_test(value, 0)
    reg.F.Z = false
}

//JR NZ, n
OC20 :: proc() {
    if(reg.F.Z == false) {
        PC = u16(i16(PC) + i16(i8(bus_read8(PC))) + 1)
        bus_dummy()
        cycleMod = 4
    } else {
        bus_read8(PC)
        PC += 1
    }
}

//LD HL, nn
OC21 :: proc() {
    reg.L = bus_read8(PC)
    reg.H = bus_read8(PC + 1)
    PC += 2
}

//LD (HL+), A
OC22 :: proc() {
    bus_write(reg.HL, reg.A)
    reg.HL += 1
}

//INC HL
OC23 :: proc() {
    bus_dummy()
    reg.HL += 1
}

//DAA
OC27 :: proc() {
    if (!reg.F.N) {  // after an addition, adjust if (half-)carry occurred or if result is out of bounds
        if (reg.F.C || reg.A > 0x99) {
            reg.A += 0x60
            reg.F.C = true
        }
        if (reg.F.H || (reg.A & 0x0F) > 0x09) {
            reg.A += 0x6
        }
    } else {  // after a subtraction, only adjust if (half-)carry occurred
        if (reg.F.C) {
            reg.A -= 0x60
        }
        if (reg.F.H) {
            reg.A -= 0x6
        }
    }
    reg.F.Z = (reg.A == 0) // the usual z flag
    reg.F.H = false // h flag is always cleared
}

//JR Z, n
OC28 :: proc() {
    if(reg.F.Z == true) {
        PC = u16(i16(PC) + i16(i8(bus_read8(PC))) + 1)
        bus_dummy()
        cycleMod = 4
    } else {
        bus_read8(PC)
        PC += 1
    }
}

//ADD HL, HL
OC29 :: proc() {
    bus_dummy()
    reg.F.N = false
    cpu_setHalfAdd16(reg.HL, reg.HL)
    cpu_setCarryAdd16(reg.HL, reg.HL)
    reg.HL += reg.HL
}

//LD A, (HL+)
OC2A :: proc() {
    reg.A = bus_read8(reg.HL)
    reg.HL += 1
}

//DEC HL
OC2B :: proc() {
    bus_dummy()
    reg.HL -= 1
}

//CPL
OC2F :: proc() {
    reg.A = (~reg.A)
    reg.F.N = true
    reg.F.H = true
}

//JR NC, n
OC30 :: proc() {
    if(reg.F.C == false) {
        PC = u16(i16(PC) + i16(i8(bus_read8(PC))) + 1)
        bus_dummy()
        cycleMod = 4
    } else {
        bus_read8(PC)
        PC += 1
    }
}

//LD SP, nn
OC31 :: proc() {
    sp := u16(bus_read8(PC))
    sp += u16(bus_read8(PC + 1)) << 8
    SP = sp
    PC += 2
}

//LD (HL-), A
OC32 :: proc() {
    bus_write(reg.HL, reg.A)
    reg.HL -= 1
}

//INC SP
OC33 :: proc() {
    bus_dummy()
    SP += 1
}

//LD (HL), n
OC36 :: proc() {
    bus_write(reg.HL, bus_read8(PC))
    PC += 1
}

//SCF
OC37 :: proc() {
    reg.F.N = false
    reg.F.H = false
    reg.F.C = true
}

//JR C, n
OC38 :: proc() {
    if(reg.F.C == true) {
        PC = u16(i16(PC) + i16(i8(bus_read8(PC))) + 1)
        bus_dummy()
        cycleMod = 4
    } else {
        bus_read8(PC)
        PC += 1
    }
}

//ADD HL, SP
OC39 :: proc() {
    bus_dummy()
    reg.F.N = false
    cpu_setHalfAdd16(reg.HL, SP)
    cpu_setCarryAdd16(reg.HL, SP)
    reg.HL += SP
}

//LD A, (HL-)
OC3A :: proc() {
    reg.A = bus_read8(reg.HL)
    reg.HL -= 1
}

//DEC SP
OC3B :: proc() {
    bus_dummy()
    SP -= 1
}

//CCF
OC3F :: proc() {
    reg.F.C = !reg.F.C
    reg.F.N = false
    reg.F.H = false
}

//HALT
OC76 :: proc() {
    bus_dummy()
    bus_dummy()
    halt = true
}

//POP BC
OCC1 :: proc() {
    reg.C = bus_read8(SP)
    reg.B = bus_read8(SP + 1)
    SP += 2
}

//JP NZ, nn
OCC2 :: proc() {
    if(reg.F.Z == false) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        bus_dummy()
        PC = pc
        cycleMod = 4
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//JP nn
OCC3 :: proc() {
    pc := u16(bus_read8(PC))
    pc += u16(bus_read8(PC + 1)) << 8
    bus_dummy()
    PC = pc
}

//CALL NZ, nn
OCC4 :: proc() {
    if(reg.F.Z == false) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        Push(u16(PC + 2))
        PC = pc
        cycleMod = 12
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//PUSH BC
OCC5 :: proc() {
    Push(reg.BC)
}

//RET NZ
OCC0 :: proc() {
    bus_dummy() //Dummy
    if(reg.F.Z == false) {
        pc := u16(bus_read8(SP))
        pc += u16(bus_read8(SP + 1)) << 8
        PC = pc
        SP += 2
        bus_dummy()
        cycleMod = 12
    }
}

//RET Z
OCC8 :: proc() {
    if(reg.F.Z == true) {
        bus_dummy()
        pc := u16(bus_read8(SP))
        pc += u16(bus_read8(SP + 1)) << 8
        bus_dummy()
        PC = pc
        SP += 2
        cycleMod = 12
    } else {
        bus_dummy()
    }
}

//RET
OCC9 :: proc() {
    pc := u16(bus_read8(SP))
    pc += u16(bus_read8(SP + 1)) << 8
    bus_dummy()
    PC = pc
    SP += 2
}

//JP Z, nn
OCCA :: proc() {
    if(reg.F.Z == true) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        bus_dummy()
        PC = pc
        cycleMod = 4
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//CALL Z, nn
OCCC :: proc() {
    if(reg.F.Z == true) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        Push(PC + 2)
        PC = pc
        cycleMod = 12
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//CALL nn
OCCD :: proc() {
    pc := u16(bus_read8(PC))
    pc += u16(bus_read8(PC + 1)) << 8
    Push(PC + 2)
    PC = pc
}

//RET NC
OCD0 :: proc() {
    if(reg.F.C == false) {
        bus_dummy()
        pc := u16(bus_read8(SP))
        pc += u16(bus_read8(SP + 1)) << 8
        bus_dummy()
        PC = pc
        SP += 2
        cycleMod = 12
    } else {
        bus_dummy()
    }
}

//POP DE
OCD1 :: proc() {
    reg.E = bus_read8(SP)
    reg.D = bus_read8(SP + 1)
    SP += 2
}

//JP NC, nn
OCD2 :: proc() {
    if(reg.F.C == false) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        bus_dummy()
        PC = pc
        cycleMod = 4
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//CALL NC, nn
OCD4 :: proc() {
    if(reg.F.C == false) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        Push(PC + 2)
        PC = pc
        cycleMod = 12
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//PUSH DE
OCD5 :: proc() {
    Push(reg.DE)
}

//RET C
OCD8 :: proc() {
    if(reg.F.C == true) {
        bus_dummy()
        pc := u16(bus_read8(SP))
        pc += u16(bus_read8(SP + 1)) << 8
        bus_dummy()
        PC = pc
        SP += 2
        cycleMod = 12
    } else {
        bus_read8(PC - 1)
    }
}

//RETI
OCD9 :: proc() {
    pc := u16(bus_read8(SP))
    pc += u16(bus_read8(SP + 1)) << 8
    bus_dummy()
    PC = pc
    SP += 2
    cpu_setInterrupt(true)
}

//JP C, nn
OCDA :: proc() {
    if(reg.F.C == true) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        bus_dummy()
        PC = pc
        cycleMod = 4
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//CALL C, nn
OCDC :: proc() {
    if(reg.F.C == true) {
        pc := u16(bus_read8(PC))
        pc += u16(bus_read8(PC + 1)) << 8
        Push(PC + 2)
        PC = pc
        cycleMod = 12
    } else {
        bus_read8(PC)
        bus_read8(PC + 1)
        PC += 2
    }
}

//LDH FF00+n, A
OCE0 :: proc() {
    bus_write(0xFF00 + u16(bus_read8(PC)), reg.A)
    PC += 1
}

//POP HL
OCE1 :: proc() {
    reg.L = bus_read8(SP)
    reg.H = bus_read8(SP + 1)
    SP += 2
}

//LD FF00+C, A
OCE2 :: proc() {
    bus_write(0xFF00 + u16(reg.C), reg.A)
}

//PUSH HL
OCE5 :: proc() {
    Push(reg.HL)
}

//ADD SP, n
OCE8 :: proc() {
    orgSP := SP
    par := i16(i8(bus_read8(PC)))
    reg.F.Z = false
    reg.F.N = false

    bus_dummy()
    bus_dummy()
    SP = u16(i16(SP) + par)
    reg.F.H = bool(((orgSP & 0xF) + (u16(par) & 0xF)) & 0x10)
    _, ovf := intrinsics.overflow_add(u8(orgSP), par)
    reg.F.C = ovf
    PC += 1
}

//JP (HL)
OCE9 :: proc() {
    PC = reg.HL
}

//LD nn, A
OCEA :: proc() {
    pc := u16(bus_read8(PC))
    pc += u16(bus_read8(PC + 1)) << 8
    bus_write(pc, reg.A)
    PC += 2
}

//LDH A, FF00+n
OCF0 :: proc() {
    reg.A = bus_read8(0xFF00 + u16(bus_read8(PC)))
    PC += 1
}

//POP AF
OCF1 :: proc() {
    reg.F = Flags(bus_read8(SP))
    reg.A = bus_read8(SP + 1)
    SP += 2
    reg.F.unused = 0
}

//LD A, FF00+C
OCF2 :: proc() {
    reg.A = bus_read8(0xFF00 + u16(reg.C))
}

//DI
OCF3 :: proc() {
    cpu_setInterrupt(false)
}

//PUSH AF
OCF5 :: proc() {
    Push(reg.AF)
}

//LD HL, SP+n
OCF8 :: proc() {
    n := u16(i16(i8(bus_read8(PC))))
    newValue := u16(i16(SP) + i16(n))
    reg.F.Z = false
    reg.F.N = false
    if(n > 0) {
        reg.F.H = bool(((SP & 0xF) + (u16(n) & 0xF)) & 0x10)
        _, ovf := intrinsics.overflow_add(u8(SP), n)
        reg.F.C = ovf
    } else {
        reg.F.H = bool(((SP & 0xF) + (u16(n) & 0xF)) & 0x10)
        reg.F.C = u16(n) > SP
    }
    bus_dummy()
    reg.HL = newValue
    PC += 1
}

//LD SP, HL
OCF9 :: proc() {
    bus_dummy()
    SP = reg.HL
}

//LD A, nn
OCFA :: proc() {
    addr := u16(bus_read8(PC))
    addr += u16(bus_read8(PC + 1)) << 8
    reg.A = bus_read8(addr)
    PC += 2
}

//EI
OCFB :: proc() {
    EI = true
}

OCA7 :: proc() {
    ANDx(Index.A)
}
OCA0 :: proc() {
    ANDx(Index.B)
}
OCA1 :: proc() {
    ANDx(Index.C)
}
OCA2 :: proc() {
    ANDx(Index.D)
}
OCA3 :: proc() {
    ANDx(Index.E)
}
OCA4 :: proc() {
    ANDx(Index.H)
}
OCA5 :: proc() {
    ANDx(Index.L)
}
OCA6 :: proc() {
    ANDx(Index.HL)
}
OCE6 :: proc() {
    ANDx(Index.n)
}

OCB7 :: proc() {
    ORx(Index.A)
}
OCB0 :: proc() {
    ORx(Index.B)
}
OCB1 :: proc() {
    ORx(Index.C)
}
OCB2 :: proc() {
    ORx(Index.D)
}
OCB3 :: proc() {
    ORx(Index.E)
}
OCB4 :: proc() {
    ORx(Index.H)
}
OCB5 :: proc() {
    ORx(Index.L)
}
OCB6 :: proc() {
    ORx(Index.HL)
}
OCF6 :: proc() {
    ORx(Index.n)
}

OCAF :: proc() {
    XORx(Index.A)
}
OCA8 :: proc() {
    XORx(Index.B)
}
OCA9 :: proc() {
    XORx(Index.C)
}
OCAA :: proc() {
    XORx(Index.D)
}
OCAB :: proc() {
    XORx(Index.E)
}
OCAC :: proc() {
    XORx(Index.H)
}
OCAD :: proc() {
    XORx(Index.L)
}
OCAE :: proc() {
    XORx(Index.HL)
}
OCEE :: proc() {
    XORx(Index.n)
}

OCBF :: proc() {
    CPx(Index.A)
}
OCB8 :: proc() {
    CPx(Index.B)
}
OCB9 :: proc() {
    CPx(Index.C)
}
OCBA :: proc() {
    CPx(Index.D)
}
OCBB :: proc() {
    CPx(Index.E)
}
OCBC :: proc() {
    CPx(Index.H)
}
OCBD :: proc() {
    CPx(Index.L)
}
OCBE :: proc() {
    CPx(Index.HL)
}
OCFE :: proc() {
    CPx(Index.n)
}

OC3E :: proc() {
    LDxn(Index.A)
}
OC06 :: proc() {
    LDxn(Index.B)
}
OC0E :: proc() {
    LDxn(Index.C)
}
OC16 :: proc() {
    LDxn(Index.D)
}
OC1E :: proc() {
    LDxn(Index.E)
}
OC26 :: proc() {
    LDxn(Index.H)
}
OC2E :: proc() {
    LDxn(Index.L)
}

OC47 :: proc() {
    LDxx(Index.B, Index.A)
}
OC4F :: proc() {
    LDxx(Index.C, Index.A)
}
OC57 :: proc() {
    LDxx(Index.D, Index.A)
}
OC5F :: proc() {
    LDxx(Index.E, Index.A)
}
OC67 :: proc() {
    LDxx(Index.H, Index.A)
}
OC6F :: proc() {
    LDxx(Index.L, Index.A)
}

OC7F :: proc() {
    LDxx(Index.A, Index.A)
}
OC78 :: proc() {
    LDxx(Index.A, Index.B)
}
OC79 :: proc() {
    LDxx(Index.A, Index.C)
}
OC7A :: proc() {
    LDxx(Index.A, Index.D)
}
OC7B :: proc() {
    LDxx(Index.A, Index.E)
}
OC7C :: proc() {
    LDxx(Index.A, Index.H)
}
OC7D :: proc() {
    LDxx(Index.A, Index.L)
}

OC40 :: proc() {
    LDxx(Index.B, Index.B)
}
OC41 :: proc() {
    LDxx(Index.B, Index.C)
}
OC42 :: proc() {
    LDxx(Index.B, Index.D)
}
OC43 :: proc() {
    LDxx(Index.B, Index.E)
}
OC44 :: proc() {
    LDxx(Index.B, Index.H)
}
OC45 :: proc() {
    LDxx(Index.B, Index.L)
}
OC48 :: proc() {
    LDxx(Index.C, Index.B)
}

OC49 :: proc() {
    LDxx(Index.C, Index.C)
}
OC4A :: proc() {
    LDxx(Index.C, Index.D)
}
OC4B :: proc() {
    LDxx(Index.C, Index.E)
}
OC4C :: proc() {
    LDxx(Index.C, Index.H)
}
OC4D :: proc() {
    LDxx(Index.C, Index.L)
}

OC50 :: proc() {
    LDxx(Index.D, Index.B)
}
OC51 :: proc() {
    LDxx(Index.D, Index.C)
}
OC52 :: proc() {
    LDxx(Index.D, Index.D)
}
OC53 :: proc() {
    LDxx(Index.D, Index.E)
}
OC54 :: proc() {
    LDxx(Index.D, Index.H)
}
OC55 :: proc() {
    LDxx(Index.D, Index.L)
}

OC58 :: proc() {
    LDxx(Index.E, Index.B)
}
OC59 :: proc() {
    LDxx(Index.E, Index.C)
}
OC5A :: proc() {
    LDxx(Index.E, Index.D)
}
OC5B :: proc() {
    LDxx(Index.E, Index.E)
}
OC5C :: proc() {
    LDxx(Index.E, Index.H)
}
OC5D :: proc() {
    LDxx(Index.E, Index.L)
}

OC60 :: proc() {
    LDxx(Index.H, Index.B)
}
OC61 :: proc() {
    LDxx(Index.H, Index.C)
}
OC62 :: proc() {
    LDxx(Index.H, Index.D)
}
OC63 :: proc() {
    LDxx(Index.H, Index.E)
}
OC64 :: proc() {
    LDxx(Index.H, Index.H)
}
OC65 :: proc() {
    LDxx(Index.H, Index.L)
}

OC68 :: proc() {
    LDxx(Index.L, Index.B)
}
OC69 :: proc() {
    LDxx(Index.L, Index.C)
}
OC6A :: proc() {
    LDxx(Index.L, Index.D)
}
OC6B :: proc() {
    LDxx(Index.L, Index.E)
}
OC6C :: proc() {
    LDxx(Index.L, Index.H)
}
OC6D :: proc() {
    LDxx(Index.L, Index.L)
}

OC77 :: proc() {
    LDHLx(Index.A)
}
OC70 :: proc() {
    LDHLx(Index.B)
}
OC71 :: proc() {
    LDHLx(Index.C)
}
OC72 :: proc() {
    LDHLx(Index.D)
}
OC73 :: proc() {
    LDHLx(Index.E)
}
OC74 :: proc() {
    LDHLx(Index.H)
}
OC75 :: proc() {
    LDHLx(Index.L)
}

OC7E :: proc() {
    LDxx(Index.A, Index.HL)
}
OC46 :: proc() {
    LDxx(Index.B, Index.HL)
}
OC4E :: proc() {
    LDxx(Index.C, Index.HL)
}
OC56 :: proc() {
    LDxx(Index.D, Index.HL)
}
OC5E :: proc() {
    LDxx(Index.E, Index.HL)
}
OC66 :: proc() {
    LDxx(Index.H, Index.HL)
}
OC6E :: proc() {
    LDxx(Index.L, Index.HL)
}

OC3C :: proc() {
    INCx(Index.A)
}
OC04 :: proc() {
    INCx(Index.B)
}
OC0C :: proc() {
    INCx(Index.C)
}
OC14 :: proc() {
    INCx(Index.D)
}
OC1C :: proc() {
    INCx(Index.E)
}
OC24 :: proc() {
    INCx(Index.H)
}
OC2C :: proc() {
    INCx(Index.L)
}
OC34 :: proc() {
    INCx(Index.HL)
}

OC3D :: proc() {
    DECx(Index.A)
}
OC05 :: proc() {
    DECx(Index.B)
}
OC0D :: proc() {
    DECx(Index.C)
}
OC15 :: proc() {
    DECx(Index.D)
}
OC1D :: proc() {
    DECx(Index.E)
}
OC25 :: proc() {
    DECx(Index.H)
}
OC2D :: proc() {
    DECx(Index.L)
}
OC35 :: proc() {
    DECx(Index.HL)
}

OC87 :: proc() {
    ADDx(Index.A)
}
OC80 :: proc() {
    ADDx(Index.B)
}
OC81 :: proc() {
    ADDx(Index.C)
}
OC82 :: proc() {
    ADDx(Index.D)
}
OC83 :: proc() {
    ADDx(Index.E)
}
OC84 :: proc() {
    ADDx(Index.H)
}
OC85 :: proc() {
    ADDx(Index.L)
}
OC86 :: proc() {
    ADDx(Index.HL)
}
OCC6 :: proc() {
    ADDx(Index.n)
}

OC97 :: proc() {
    SUBx(Index.A)
}
OC90 :: proc() {
    SUBx(Index.B)
}
OC91 :: proc() {
    SUBx(Index.C)
}
OC92 :: proc() {
    SUBx(Index.D)
}
OC93 :: proc() {
    SUBx(Index.E)
}
OC94 :: proc() {
    SUBx(Index.H)
}
OC95 :: proc() {
    SUBx(Index.L)
}
OC96 :: proc() {
    SUBx(Index.HL)
}
OCD6 :: proc() {
    SUBx(Index.n)
}

OC8F :: proc() {
    ADCx(Index.A)
}
OC88 :: proc() {
    ADCx(Index.B)
}
OC89 :: proc() {
    ADCx(Index.C)
}
OC8A :: proc() {
    ADCx(Index.D)
}
OC8B :: proc() {
    ADCx(Index.E)
}
OC8C :: proc() {
    ADCx(Index.H)
}
OC8D :: proc() {
    ADCx(Index.L)
}
OC8E :: proc() {
    ADCx(Index.HL)
}
OCCE :: proc() {
    ADCx(Index.n)
}

OC9F :: proc() {
    SBCx(Index.A)
}
OC98 :: proc() {
    SBCx(Index.B)
}
OC99 :: proc() {
    SBCx(Index.C)
}
OC9A :: proc() {
    SBCx(Index.D)
}
OC9B :: proc() {
    SBCx(Index.E)
}
OC9C :: proc() {
    SBCx(Index.H)
}
OC9D :: proc() {
    SBCx(Index.L)
}
OC9E :: proc() {
    SBCx(Index.HL)
}
OCDE :: proc() {
    SBCx(Index.n)
}

OCC7 :: proc() {
    RST(0x0000)
}
OCCF :: proc() {
    RST(0x0008)
}
OCD7 :: proc() {
    RST(0x0010)
}
OCDF :: proc() {
    RST(0x0018)
}
OCE7 :: proc() {
    RST(0x0020)
}
OCEF :: proc() {
    RST(0x0028)
}
OCF7 :: proc() {
    RST(0x0030)
}
OCFF :: proc() {
    RST(0x0038)
}

ADCx :: proc(index: Index) {
    value := getReg(index)
    flag := u8(reg.F.C)
    par := (value + flag)
    newValue := (reg.A + par)
    reg.F.Z = newValue == 0
    reg.F.N = false
    cpu_setHalfAdd8(value, flag)
    cpu_setCarryAdd8(value, flag)
    if(!reg.F.H) {
        cpu_setHalfAdd8(reg.A, par)
    }
    if(!reg.F.C) {
        cpu_setCarryAdd8(reg.A, par)
    }
    reg.A = newValue
}

//SBC A, x
SBCx :: proc(index: Index) {
    value := getReg(index)
    flag := u8(reg.F.C)
    par := (value + flag)
    newValue := (reg.A - par)
    reg.F.Z = newValue == 0
    reg.F.N = true
    cpu_setHalfAdd8(value, flag)
    cpu_setCarryAdd8(value, flag)
    if(!reg.F.H) {
        cpu_setHalfSub8(reg.A, par)
    }
    if(!reg.F.C) {
        cpu_setCarrySub8(reg.A, par)
    }
    reg.A = newValue
}

//AND A, x
ANDx :: proc(index: Index) {
    reg.A &= getReg(index)
    reg.F.Z = reg.A == 0
    reg.F.N = false
    reg.F.H = true
    reg.F.C = false
}

//OR A, x
ORx :: proc(index: Index) {
    reg.A |= getReg(index)
    reg.F.Z = reg.A == 0
    reg.F.N = false
    reg.F.H = false
    reg.F.C = false
}

//XOR A, x
XORx :: proc(index: Index) {
    reg.A ~= getReg(index)
    reg.F.Z = reg.A == 0
    reg.F.N = false
    reg.F.H = false
    reg.F.C = false
}

//CP A, x
CPx :: proc(index: Index) {
    par := getReg(index)
    reg.F.Z = (reg.A - par) == 0
    reg.F.N = true
    cpu_setHalfSub8(reg.A, par)
    cpu_setCarrySub8(reg.A, par)
}

//LD x, n
LDxn :: proc(index: Index) {
    setReg(index, bus_read8(PC))
    PC += 1
}

//LD x, x
LDxx :: proc(index1: Index, index2: Index) {
    setReg(index1, getReg(index2))
}

//LD HL, x
LDHLx :: proc(index: Index) {
    bus_write(reg.HL, getReg(index))
}

//INC x
INCx :: proc(index: Index) {
    value := getReg(index)
    newValue := value + 1
    setReg(index, newValue)
    reg.F.Z = newValue == 0
    reg.F.N = false
    cpu_setHalfAdd8(value, 1)
}

//DEC x
DECx :: proc(index: Index) {
    value := getReg(index)
    newValue := value - 1
    setReg(index, newValue)
    reg.F.Z = newValue == 0
    reg.F.N = true
    cpu_setHalfSub8(value, 1)
}

//ADD A, x
ADDx :: proc(index: Index) {
    par := getReg(index)
    newValue := reg.A + par
    reg.F.Z = newValue == 0
    reg.F.N = false
    cpu_setHalfAdd8(reg.A, par)
    cpu_setCarryAdd8(reg.A, par)
    reg.A = newValue
}

//SUB A, x
SUBx :: proc(index: Index) {
    par := getReg(index)
    newValue := reg.A - par
    reg.F.Z = newValue == 0
    reg.F.N = true
    cpu_setHalfSub8(reg.A, par)
    cpu_setCarrySub8(reg.A, par)
    reg.A = newValue
}

//RST
RST :: proc(address: u16) {
    Push(PC)
    PC = address
}

Push :: proc(value: u16) {
    bus_dummy()
    SP -= 1
    bus_write(SP, u8(value >> 8))
    SP -= 1
    bus_write(SP, u8(value))
}