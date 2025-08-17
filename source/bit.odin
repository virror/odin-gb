package main

import "core:fmt"

bit_get :: proc(value: u8, bit: u8) -> u8 {
    return u8((bit_test(value, bit)) ? 1 : 0)
}

bit_test :: proc(value: u8, bit: u8) -> bool{
    return (value & (1 << bit)) != 0
}

bit_set1 :: proc(value: u8, bit: u8) -> u8 {
    return u8(value | (1 << bit))
}

bit_clear :: proc(value: u8, bit: u8) -> u8 {
    return u8(value & ~(1 << bit))
}