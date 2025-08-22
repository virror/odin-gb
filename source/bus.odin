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
romBanks: [][]byte
ramBanks: [][]byte
ramEnabled: bool
ramChanged: bool
ramSize: u8
romBankNr: u8
ramBankNr: u8
mbc: Mbc
mbc1Mode: u8

bus_init :: proc() {
    file, err := os.open("Bootloader.bin", os.O_RDONLY)
    assert(err == nil, "Failed to open bios")
    _, err2 := os.read(file, memory[0:0x100])
    assert(err2 == nil, "Failed to read bios data")
    os.close(file)
}

bus_read8 :: proc(address: u16) -> u8 {
    when TEST_ENABLE {
        return bus_get(address)
    } else {
        /*if address == breakReadAddress)
            Debug.Break()*/
        switch (address) {
        case 0xA000..<0xC000:	//RAM
            if ramEnabled && (ramSize == 1 && address < 0xA800) || ramSize > 1 {
                return ramBanks[ramBankNr][address - 0xA000]
            } else {
                return 0xFF
            }
        case 0xFF0F:
            return memory[address] | 0xE0
        case:
            return memory[address]
        }
    }
}

bus_read16 :: proc(address: u16) -> u16 {
	return (u16(bus_read8(address + 1)) << 8) + u16(bus_read8(address))
}

bus_write :: proc(address: u16, data: u8) {
    when TEST_ENABLE {
        bus_set(address, data)
    } else {
        /*if address == breakWriteAddress {
            fmt.println("a")
        }*/
        switch (address) {
        case 0x0000..<0x8000:	//ROM
            BankSwitch(address, data)
        case 0xA000..<0xC000:   //RAM
            if ramEnabled {
                if (ramSize == 1 && address < 0xA800) || ramSize > 1 {
                    ramBanks[ramBankNr][address - 0xA000] = data
                }
            }
        case 0xE000..<0xFE00:   //Echo RAM?
            memory[address] = data
            bus_write(u16(address - 0x2000), data)
        case 0xFEA0..<0xFEFF:   //Restricted memory
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
            /*if serialDebug {
                fmt.print(data)
            }*/
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
            //Array.Copy(romBanks[0], memory, 0x4000)
            //mem.copy(&romBanks[0], &memory[0], 0x4000)
            break
        case:
            memory[address] = data
            break
        }
    }
}

bus_set :: proc(address: u16, data: u8) {
    memory[address] = data
}

bus_get :: proc(address: u16) -> u8 {
    return memory[address]
}

bus_dma_transfer :: proc(data: u8) {
    startAddr := u16(data) << 8
    //Array.Copy(memory, startAddr, memory, 0xFE00, 0xA0)
    mem.copy(&memory[0xFE00], &memory[startAddr], 0xA0)
}

LoadROM :: proc(rom: string) {
    //romName = Path.GetFileNameWithoutExtension(rom)

    file, err := os.open(rom, os.O_RDONLY)
    assert(err == nil, "Failed to open rom")
    
    //os.close(file)
    
    /*bankSize, _ := os.file_size(file)
    bankSize /= 0x4000
    romBanks := [bankSize]u8*/

    /*for i :u8= 0; i < bankSize; i += 1 {
        romBanks[i] = [0x4000]byte
        //fs.Read(romBanks[i], 0, 0x4000)
        _, err2 := os.read(file, memory[0:0x4000])
        assert(err2 == nil, "Failed to read rom data")
    }*/
    //Array.Copy(romBanks[0], memory, 0x4000)
    _, _ = os.seek(file, 0x100, 1)
    _, err2 := os.read_at_least(file, memory[0x100:], 0x4000)
    //fmt.println(n)
    assert(err2 == nil, "Failed to read rom data")
    //Array.Copy(romBanks[1], 0, memory, 0x4000, 0x4000)
    //mbc = Mbc(memory[0x0147])
    

    /*ramSize = memory[0x0149]
    banks := math.pow(4, (ramSize - 2))
    ramBanks = [banks][]byte
    if(ramSize == 0 && (mbc == Mbc.MBC2_BAT || mbc == Mbc.MBC2)) {
        ramBanks = byte[1][]
        ramBanks[0] = byte[0x200]
        ramSize = 1
    }
    else if(ramSize == 1) {
        ramBanks[0] = new byte[0x800]
    } else if(ramSize > 1) {
        for i :u8= 0; i < banks; i += 1 {
            ramBanks[i] = [0x2000]u8
        }
    }
    if(bus_has_battery()) {
        LoadRam()
    }*/
    //Array.Copy(bootrom, memory, bootrom.Length)
}

BankSwitch :: proc(address: u16, data: u8) {
    switch(address) {
    case 0x0000..<0x2000:	//RAM Enable
        ramEnabled = ((data & 0x0F) == 0x0A)
        ramChanged = !ramEnabled
    case 0x2000..<0x4000:	//ROM Switch
        ROMSwitch(address, data)
    case 0x4000..<0x6000:	//RAM Switch
        RAMSwitch(data)
    case 0x6000..<0x8000:	//MBC1 Mode
        if(bit_test(data, 0)) {
            mbc1Mode = 1
        } else {
            mbc1Mode = 0
        }
    }
}

ROMSwitch :: proc(address: u16, data: u8) {
    /*switch (mbc)
    {
        case Mbc.MBC1:
        case Mbc.MBC1_RAM:
        case Mbc.MBC1_RAM_BAT:
            data &= 0x1F;
            romBankNr &= 0xE0;
            romBankNr |= data;
            if(romBankNr == 0 || romBankNr == 0x20 || romBankNr == 0x40 || romBankNr == 0x60)
                romBankNr++;
            Array.Copy(romBanks[romBankNr], 0, memory, 0x4000, 0x4000);
            break;
        case Mbc.MBC2:
        case Mbc.MBC2_BAT:
            data &= 0x0F;
            romBankNr = data;
            if(romBankNr == 0 || romBankNr == 0x20 || romBankNr == 0x40 || romBankNr == 0x60)
                romBankNr++;
            Array.Copy(romBanks[romBankNr], 0, memory, 0x4000, 0x4000);
            break;
        case Mbc.MBC3:
        case Mbc.MBC3_RAM:
        case Mbc.MBC3_RAM_BAT:
        case Mbc.MBC3_TIM_BAT:
        case Mbc.MBC3_TIM_RAM_BAT:
            data &= 0x7F;
            romBankNr = data;
            if(romBankNr == 0)
                romBankNr++;
            Array.Copy(romBanks[romBankNr], 0, memory, 0x4000, 0x4000);
            break;
        case Mbc.MBC5:
        case Mbc.MBC5_RAM:
        case Mbc.MBC5_RAM_BAT:
            if(address > 0x2000 && address < 0x2000)
            {
                romBankNr |= data;
                Array.Copy(romBanks[romBankNr], 0, memory, 0x4000, 0x4000);
            }
            else
            {
                data &= 0x01;
                romBankNr |= (ushort)(data << 8);
            }
            break;
    }*/
}

RAMSwitch :: proc(data: u8) {
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
            romBankNr |= data
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

SaveRam :: proc() {
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

LoadRam :: proc() {
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