package main

import "core:math"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:path/filepath"

Mbc :: enum
{
    None = 0,
    MBC1 = 1,
    MBC1_RAM = 2,
    MBC1_RAM_BAT = 3,
    MBC2 = 5,
    MBC2_BAT = 6,
    None_RAM = 8,
    None_RAM_BAT = 9,
    MMM01 = 11,
    MMM01_SRAM = 12,
    MMM01_SRAM_BAT = 13,
    MBC3_TIM_BAT = 15,
    MBC3_TIM_RAM_BAT = 16,
    MBC3 = 17,
    MBC3_RAM = 18,
    MBC3_RAM_BAT = 19,
    MBC5 = 25,
    MBC5_RAM = 26,
    MBC5_RAM_BAT = 27,
    MBC5_RUM = 28,
    MBC5_RUM_SRAM = 29,
    MBC5_RUM_SRAM_BAT = 30,
    CAM = 31,
    TAMA5 = 253,
    HuC3 = 254,
    Huc1 = 255,
}

IO_P1 :u16: 0xFF00
IO_SB :u16: 0xFF01
IO_SC :u16: 0xFF02
IO_DIV :u16: 0xFF04
IO_TIMA :u16: 0xFF05
IO_TMA :u16: 0xFF06
IO_TAC :u16: 0xFF07
IO_IF :u16: 0xFF0F
IO_NR10 :u16: 0xFF10
IO_NR11 :u16: 0xFF11
IO_NR12 :u16: 0xFF12
IO_NR13 :u16: 0xFF13
IO_NR14 :u16: 0xFF14
IO_NR21 :u16: 0xFF16
IO_NR22 :u16: 0xFF17
IO_NR23 :u16: 0xFF18
IO_NR24 :u16: 0xFF19
IO_NR30 :u16: 0xFF1A
IO_NR31 :u16: 0xFF1B
IO_NR32 :u16: 0xFF1C
IO_NR33 :u16: 0xFF1D
IO_NR34 :u16: 0xFF1E
IO_NR41 :u16: 0xFF20
IO_NR42 :u16: 0xFF21
IO_NR43 :u16: 0xFF22
IO_NR44 :u16: 0xFF23
IO_NR50 :u16: 0xFF24
IO_NR51 :u16: 0xFF25
IO_NR52 :u16: 0xFF26
IO_LCDC :u16: 0xFF40
IO_STAT :u16: 0xFF41
IO_SCY :u16: 0xFF42
IO_SCX :u16: 0xFF43
IO_LY :u16: 0xFF44
IO_LYC :u16: 0xFF45
IO_DMA :u16: 0xFF46
IO_BGP :u16: 0xFF47
IO_OBP0 :u16: 0xFF48
IO_OBP1 :u16: 0xFF49
IO_WY :u16: 0xFF4A
IO_WX :u16: 0xFF4B
IO_BL :u16: 0xFF50
IO_IE :u16: 0xFFFF

bootrom: [0x100]u8
memory: [0x10000]u8
romBanks: [512][0x4000]byte
ramBanks: [16][0x2000]byte
ramEnabled: bool
ramChanged: bool
ramSize: u8
romBankNr: u16
ramBankNr: u8
mbc: Mbc
mbc1Mode: u8
bus_address: u16
bus_value: u8

bus_init :: proc() {
    file, err := os.open("Bootloader.bin", os.O_RDONLY)
    assert(err == nil, "Failed to open bios")
    _, err2 := os.read(file, memory[0:0x100])
    assert(err2 == nil, "Failed to read bios data")
    os.close(file)
}

bus_reset :: proc() {
    memory = {}
    romBanks = {}
    ramBanks = {}
    bus_init()
}

bus_dummy :: proc() {
    when TEST_ENABLE {
        test_write(bus_address, bus_value)
    }
}

bus_read :: proc(address: u16) -> u8 {
    value: u8
    bus_address = address
    when TEST_ENABLE {
        value = test_read(address)
    } else {
        switch (address) {
        case 0xA000..<0xC000:	//RAM
            if ramEnabled && (ramSize == 1 && address < 0xA800) || ramSize > 1 {
                value = ramBanks[ramBankNr][address - 0xA000]
            } else {
                value = 0xFF
            }
        case IO_SC:
            value = memory[address] | 0x7C
        case 0xFF04..=0xFF07:
            value = tmr_read(address)
        case IO_STAT:
            value = memory[address] | 0x10
        case IO_IF:
            value = memory[address] | 0xE0
        case:
            value = memory[address]
        }
    }
    bus_value = value
    return value
}

bus_write :: proc(address: u16, data: u8) {
    bus_address = address
    bus_value = bus_value
    when TEST_ENABLE {
        test_write(address, data)
    } else {
        switch (address) {
        case 0x0000..<0x8000:	//ROM
            bus_bank_switch(address, data)
        case 0xA000..<0xC000:   //RAM
            if ramEnabled {
                if (ramSize == 1 && address < 0xA800) || ramSize > 1 {
                    ramBanks[ramBankNr][address - 0xA000] = data
                }
            }
        case 0xE000..<0xFD00:   //Echo RAM
            memory[address - 0x2000] = data
        case 0xFEA0..<0xFF00:   //Restricted memory
            return
        case IO_P1:
            if bit_test(data, 4) {
                memory[address] = keyState
            }
            if bit_test(data, 5) {
                memory[address] = keyState >> 4
            }
            break
        case IO_SB:
            if SERIAL_DEBUG {
                fmt.print(rune(data))
            }
            break
        case IO_LY: //Read only
            break
        case IO_DMA:
            bus_dma_transfer(data)
            break
        case IO_BL:
            mem.copy(&memory[0], &romBanks[0], 0x4000)
            break
        case 0xFF04..=0xFF07:
            tmr_write(address, data)
        case 0xFF10..=0xFF26:
            apu_write(address, data)
            break
        case:
            memory[address] = data
            break
        }
    }
}

bus_set :: proc(address: u16, data: u8) {
    bus_address = address
    bus_value = bus_value
    when TEST_ENABLE {
        test_write(address, data)
    } else {
        memory[address] = data
    }
}

bus_get :: proc(address: u16) -> u8 {
    value: u8
    bus_address = address
    when TEST_ENABLE {
        value = test_read(address)
    } else {
        value = memory[address]
    }
    bus_value = value
    return value
}

bus_dma_transfer :: proc(data: u8) {
    startAddr := u16(data) << 8
    mem.copy(&memory[0xFE00], &memory[startAddr], 0xA0)
    operation = .Dma
    state.op.cycles = 140
}

bus_get_rom_size :: proc(rom_size: u8) -> u16 {
    switch (rom_size) {
    case 0: //32KB
        return 2
    case 1: //64KB
        return 4
    case 2: //128KB
        return 8
    case 3: //256KB
        return 16
    case 4: //512KB
        return 32
    case 5: //1MB
        return 64
    case 6: //2MB
        return 128
    case 7: //4MB
        return 256
    case 8: //8MB
        return 2
    case:
        fmt.println("Unsupported ROM size: ", rom_size)
        return 0x8000
    }
}

bus_load_ROM :: proc(rom: string) {
    file, err := os.open(rom, os.O_RDONLY)
    assert(err == nil, "Failed to open rom")

    //Load rambank 0 first so we can read the rom size
    _, err2 := os.read(file, romBanks[0][:])
    assert(err2 == nil, "Failed to read rom data")
    mem.copy(&memory[0x100], &romBanks[0][0x100], 0x3900)
    bankSize := bus_get_rom_size(memory[0x0148])

    //Then load the rest once we know the size
    for i :u16= 1; i < bankSize; i += 1 {
        _, err2 = os.read(file, romBanks[i][:])
        assert(err2 == nil, "Failed to read rom data")
    }
    os.close(file)
    file_name = filepath.short_stem(rom)
    
    mem.copy(&memory[0x4000], &romBanks[1][0], 0x4000)
    mbc = Mbc(memory[0x0147])
    ramSize = memory[0x0149]

    if(bus_has_battery()) {
        bus_load_ram()
    }
}

bus_bank_switch :: proc(address: u16, data: u8) {
    switch(address) {
    case 0x0000..<0x2000:	//RAM Enable
        ramEnabled = ((data & 0x0F) == 0x0A)
        ramChanged = !ramEnabled
    case 0x2000..<0x4000:	//ROM Switch
        bus_rom_switch(address, data)
    case 0x4000..<0x6000:	//RAM Switch
        bus_ram_switch(data)
    case 0x6000..<0x8000:	//MBC1 Mode
        if(bit_test(data, 0)) {
            mbc1Mode = 1
        } else {
            mbc1Mode = 0
        }
    }
}

bus_rom_switch :: proc(address: u16, data: u8) {
    data := data
    #partial switch (mbc) {
    case Mbc.None:
        break
    case Mbc.MBC1,
         Mbc.MBC1_RAM,
         Mbc.MBC1_RAM_BAT:
        data &= 0x1F
        romBankNr &= 0xE0
        romBankNr |= u16(data)
        if(romBankNr == 0 || romBankNr == 0x20 || romBankNr == 0x40 || romBankNr == 0x60) {
            romBankNr += 1
        }
        break
    case Mbc.MBC2,
         Mbc.MBC2_BAT:
        romBankNr = u16(data & 0x0F)
        if(romBankNr == 0 || romBankNr == 0x20 || romBankNr == 0x40 || romBankNr == 0x60) {
            romBankNr += 1
        }
        break
    case Mbc.MBC3,
         Mbc.MBC3_TIM_BAT:
        data &= 0x7F
        romBankNr = u16(data) 
    case Mbc.MBC3_RAM,
         Mbc.MBC3_RAM_BAT,
         Mbc.MBC3_TIM_RAM_BAT:
        romBankNr = u16(data)
        if(romBankNr == 0) {
            romBankNr += 1
        }
        break
    case Mbc.MBC5,
         Mbc.MBC5_RAM,
         Mbc.MBC5_RAM_BAT:
        if(address > 0x2000 && address < 0x2000) {
            romBankNr |= u16(data)
        } else {
            data &= 0x01
            romBankNr |= (u16(data) << 8)
            return
        }
        break
    case:
        fmt.println("Unsupported MBC type: ", mbc)
        return
    }
    mem.copy(&memory[0x4000], &romBanks[romBankNr][0], 0x4000)
}

bus_ram_switch :: proc(data: u8) {
    data := data
    #partial switch (mbc)
    {
    case Mbc.MBC1,
         Mbc.MBC1_RAM,
         Mbc.MBC1_RAM_BAT:
        data &= 0x03
        if(mbc1Mode == 0) { //Rom
            data = data << 5
            romBankNr &= 0x1F
            romBankNr |= u16(data)
        } else {	//Ram
            ramBankNr = data
        }
        break
    case Mbc.MBC2,
         Mbc.MBC2_BAT:
        //Do nothing, no switch supported
        break
    case Mbc.MBC3,
         Mbc.MBC3_TIM_BAT:
        data &= 0x03
        ramBankNr = data
        break
    case Mbc.MBC3_RAM,
         Mbc.MBC3_RAM_BAT,
         Mbc.MBC3_TIM_RAM_BAT:
        data &= 0x07
        ramBankNr = data
        break
    case Mbc.MBC5,
         Mbc.MBC5_RAM,
         Mbc.MBC5_RAM_BAT:
        data &= 0x0F
        ramBankNr = data
        break
    }
}

bus_has_battery :: proc() -> bool {
    return mbc == Mbc.MBC1_RAM_BAT || mbc == Mbc.MBC2_BAT || mbc == Mbc.MBC3_RAM_BAT || 
            mbc == Mbc.MBC5_RAM_BAT || mbc == Mbc.MBC5_RUM_SRAM_BAT
}

bus_save_ram :: proc() {
    if(ramChanged) {
        path := (filepath.dir(game_path))
        save_path := fmt.aprintf("%s/%s.sav", path, file_name)
        file, err := os.open(save_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
        if(err == nil) {
            for i :u16= 0; i < len(ramBanks); i += 1 {
                _, err2 := os.write(file, ramBanks[i][:])
                assert(err2 == nil, "Failed to read rom data")
            }
        }
        os.close(file)
    }
    ramChanged = false
}

bus_load_ram :: proc() {
    path := (filepath.dir(game_path))
    load_path := fmt.aprintf("%s/%s.sav", path, file_name)
    file, err := os.open(load_path, os.O_RDONLY)
    if(err == nil) {
        for i :u16= 0; i < len(ramBanks); i += 1 {
            _, err2 := os.read(file, ramBanks[i][:])
            assert(err2 == nil, "Failed to read rom data")
        }
    }
    os.close(file)
}