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
    cycles: [][]union{ u16, string },
}

@(private="file")
test_fail: bool
@(private="file")
fail_cnt: int
@(private="file")
ram_mem: [0x10000]u8
@(private="file")
cycle: u32
@(private="file")
json_data: [dynamic]Json_data
@(private="file")
test_idx: int
@(private="file")
error_string: string

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
    error := json.unmarshal(data, &json_data)
    if error != nil {
        fmt.println(error)
        return
    }
    delete(data)
    test_length := len(json_data)
    for i:= 0; i < test_length; i += 1 {
        if !test_fail {
            test_idx = i
            test_run(json_data[i])
        }
    }
    fmt.printf("Failed: %d\n", fail_cnt)
}

@(private="file")
test_run :: proc(json_data: Json_data) {
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
        ram_mem[mem_val[0]] = u8(mem_val[1])
    }

    //Run opcode
    halt = false
    cycle = 0
    error_string = ""
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

    cycle_cnt := u32(len(json_data.cycles))
    if(cycle != cycle_cnt) {
        error_string = fmt.aprintf("Fail: Cycle count is %d should be %d", cycle, cycle_cnt)
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

test_read :: proc(addr: u16) -> u8 {
    value := ram_mem[addr]
    test_check_cycle(addr, value, true)
    return value
}

test_write :: proc(addr: u16, value: u8) {
    test_check_cycle(addr, value, false)
    ram_mem[addr] = value
}

test_check_cycle :: proc(addr: u16, value: u8, read: bool) {
    ok_addr := json_data[test_idx].cycles[cycle][0].(u16)
    if(addr != ok_addr) {
        if(read) {
            error_string = fmt.aprintf("Fail cycle %d: Reading addr %d should be %d", cycle, addr, ok_addr)
        } else {
            error_string = fmt.aprintf("Fail cycle %d: Writing addr %d should be %d", cycle, addr, ok_addr)
        }
    }
    ok_data := u8(json_data[test_idx].cycles[cycle][1].(u16))
    if(value != ok_data) {
        if(read) {
            error_string = fmt.aprintf("Fail cycle %d: Reading data %d should be %d", cycle, value, ok_data)
        } else {
            error_string = fmt.aprintf("Fail cycle %d: Writing data %d should be %d", cycle, value, ok_data)
        }
    }
    cycle += 1
}