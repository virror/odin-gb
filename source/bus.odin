package main

import "core:math"
import "core:mem"
import "core:fmt"
import "core:os"

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

IO :: enum u16 {
    P1 = 0xFF00,
	SB = 0xFF01,
	SC = 0xFF02,
	DIV = 0xFF04,
	TIMA = 0xFF05,
	TMA = 0xFF06,
	TAC = 0xFF07,
	IF = 0xFF0F,
	NR10 = 0xFF10,
	NR11 = 0xFF11,
	NR12 = 0xFF12,
	NR13 = 0xFF13,
	NR14 = 0xFF14,
	NR21 = 0xFF16,
	NR22 = 0xFF17,
	NR23 = 0xFF18,
	NR24 = 0xFF19,
	NR30 = 0xFF1A,
	NR31 = 0xFF1B,
	NR32 = 0xFF1C,
	NR33 = 0xFF1D,
	NR34 = 0xFF1E,
	NR41 = 0xFF20,
	NR42 = 0xFF21,
	NR43 = 0xFF22,
	NR44 = 0xFF23,
	NR50 = 0xFF24,
	NR51 = 0xFF25,
	NR52 = 0xFF26,
	LCDC = 0xFF40,
	STAT = 0xFF41,
	SCY = 0xFF42,
	SCX = 0xFF43,
	LY = 0xFF44,
	LYC = 0xFF45,
	DMA = 0xFF46,
	BGP = 0xFF47,
	OBP0 = 0xFF48,
	OBP1 = 0xFF49,
	WY = 0xFF4A,
	WX = 0xFF4B,
	BL = 0xFF50,
	IE = 0xFFFF,
}

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

bus_dummy :: proc() {
    when TEST_ENABLE {
        test_write(bus_address, bus_value)
    }
}

bus_read8 :: proc(address: u16) -> u8 {
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
        case 0xFF0F:
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
        case u16(IO.P1):
            if bit_test(data, 4) {
                memory[address] = keyState
            }
            if bit_test(data, 5) {
                memory[address] = keyState >> 4
            }
            break
        case u16(IO.SB):
            if SERIAL_DEBUG {
                fmt.print(rune(data))
            }
            break
        case u16(IO.LY):
            break
        case u16(IO.DIV):
            memory[address] = 0
            break
        case u16(IO.DMA):
            bus_dma_transfer(data)
            break
        case u16(IO.BL):
            mem.copy(&memory[0], &romBanks[0], 0x4000)
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
    //Array.Copy(memory, startAddr, memory, 0xFE00, 0xA0)
    mem.copy(&memory[0xFE00], &memory[startAddr], 0xA0)
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
         Mbc.MBC3_RAM,
         Mbc.MBC3_RAM_BAT,
         Mbc.MBC3_TIM_BAT,
         Mbc.MBC3_TIM_RAM_BAT:
        data &= 0x7F
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
         Mbc.MBC3_RAM,
         Mbc.MBC3_RAM_BAT,
         Mbc.MBC3_TIM_BAT,
         Mbc.MBC3_TIM_RAM_BAT:
        data &= 0x03
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
    /*if(ramChanged)
    {
        string loadName = "Roms/" + romName + ".sav";
        using (FileStream fs = new FileStream(loadName, FileMode.Create, FileAccess.Write))
        {
            for(int i = 0; i < ramBanks.Length; i++)
            {
                fs.Write(ramBanks[i], 0, ramBanks[i].Length);
            }
        }
    }
    ramChanged = false;*/
}

bus_load_ram :: proc() {
    /*string saveName = "Roms/" + romName + ".sav";
    if(File.Exists(saveName))
    {
        using (FileStream fs = new FileStream(saveName, FileMode.Open, FileAccess.Read))
        {
            for(int i = 0; i < ramBanks.Length; i++)
            {
                fs.Read(ramBanks[i], 0, ramBanks[i].Length);
            }
        }
    }*/
}