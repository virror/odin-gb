package main

import "core:fmt"
import "core:os"
import "core:encoding/json"

TEST_ENABLE :: false
TEST_ALL :: true
TEST_FILE :: "tests/json/f8.json"
TEST_BREAK_ERROR :: false

@(private="file")
Registers :: struct {
    pc: u16,
    sp: u16,
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    f: u8,
    h: u8,
    l: u8,
    ime: u8,
    ei: u8,
    ram: [dynamic][2]u16,
}

@(private="file")
Json_data :: struct {
    name: string,
    initial: Registers,
    final: Registers,
    cycles: [][]union{ int, string },
}

@(private="file")
test_fail: bool
@(private="file")
fail_cnt: int
@(private="file")
ram_mem: [0x1000000]u8

test_all :: proc() {
    when TEST_ALL {
        fd: os.Handle
        err: os.Errno
        info: []os.File_Info
        fd, err = os.open("tests/json")
        info, err = os.read_dir(fd, -1)
        length := len(info)
        for i := 0; i < length; i += 1 {
            test_fail = false
            fail_cnt = 0
            fmt.println(info[i].fullpath)
            test_file(info[i].fullpath)
            if test_fail == true {
                break
            }
        }
    } else {
        fmt.println(TEST_FILE)
        test_file(TEST_FILE)
    }
}

test_file :: proc(filename: string) {
    //Setup
    data, err := os.read_entire_file_from_filename(filename)
    assert(err == true, "Could not load test file")
    json_data: [dynamic]Json_data
    error := json.unmarshal(data, &json_data)
    if error != nil {
        fmt.println(error)
        return
    }
    delete(data)
    test_length := len(json_data)
    for i:= 0; i < test_length; i += 1 {
        if !test_fail {
            test_run(json_data[i])
        }
    }
    fmt.printf("Failed: %d\n", fail_cnt)
}

@(private="file")
test_run :: proc(json_data: Json_data) {
    error_string: string
    PC = json_data.initial.pc
    SP = json_data.initial.sp
    reg.A = json_data.initial.a
    reg.B = json_data.initial.b
    reg.C = json_data.initial.c
    reg.D = json_data.initial.d
    reg.E = json_data.initial.e
    reg.F = Flags(json_data.initial.f)
    reg.H = json_data.initial.h
    reg.L = json_data.initial.l

    ram_length := len(json_data.initial.ram)
    for i:= 0; i < ram_length; i += 1 {
        mem_val := json_data.initial.ram[i]
        bus_set(mem_val[0], u8(mem_val[1]))
    }

    //Run opcode
    halt = false
    cpu_step()

    //Compare results
    if reg.A != json_data.final.a {
        error_string = fmt.aprintf("Fail: A is %d should be %d", reg.A, json_data.final.a)
    }
    if reg.B != json_data.final.b {
        error_string = fmt.aprintf("Fail: B is %d should be %d", reg.B, json_data.final.b)
    }
    if reg.C != json_data.final.c {
        error_string = fmt.aprintf("Fail: C is %d should be %d", reg.C, json_data.final.c)
    }
    if reg.D != json_data.final.d {
        error_string = fmt.aprintf("Fail: D is %d should be %d", reg.D, json_data.final.d)
    }
    if reg.E != json_data.final.e {
        error_string = fmt.aprintf("Fail: E is %d should be %d", reg.E, json_data.final.e)
    }
    if reg.F != Flags(json_data.final.f) {
        error_string = fmt.aprintf("Fail: F is %d\n should be %d", reg.F, Flags(json_data.final.f))
    }
    if reg.H != json_data.final.h {
        error_string = fmt.aprintf("Fail: H is %d should be %d", reg.H, json_data.final.h)
    }
    if reg.L != json_data.final.l {
        error_string = fmt.aprintf("Fail: L is %d should be %d", reg.L, json_data.final.l)
    }
    if PC != json_data.final.pc {
        error_string = fmt.aprintf("Fail: PC is %d should be %d", PC, json_data.final.pc)
    }
    if SP != json_data.final.sp {
        error_string = fmt.aprintf("Fail: SP is %d should be %d", SP, json_data.final.sp)
    }

    if error_string != "" {
        when TEST_BREAK_ERROR {
            fmt.println(json_data.name)
            fmt.println(error_string)
            test_fail = true
            exit = true
        }
        fail_cnt += 1
    }
    exit = true
}

test_read :: proc(size: u8, addr: u32) -> u32 {
    switch size {
    case 8:
        return u32(ram_mem[addr])
    case 16:
        return u32(ram_mem[addr + 1]) | (u32(ram_mem[addr]) << 8)
    case 32:
        return u32(ram_mem[addr + 3]) | (u32(ram_mem[addr + 2]) << 8) |
            (u32(ram_mem[addr + 1]) << 16) | (u32(ram_mem[addr]) << 24)
    }
    return 0
}

test_write :: proc(size: u8, addr: u32, value: u32) {
    switch size {
    case 8:
        ram_mem[addr] = u8(value)
    case 16:
        ram_mem[addr + 1] = u8(value & 0xFF)
        ram_mem[addr + 0] = u8((value >> 8) & 0xFF)
    case 32:
        ram_mem[addr + 3] = u8(value & 0xFF)
        ram_mem[addr + 2] = u8((value >> 8) & 0xFF)
        ram_mem[addr + 1] = u8((value >> 16) & 0xFF)
        ram_mem[addr + 0] = u8((value >> 24) & 0xFF)
    }
}
