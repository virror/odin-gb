package main

import "core:fmt"

scanlineCounter :i32= 204
screenRow: [160]u8
screen_buffer: [WIN_WIDTH * WIN_HEIGHT]u16

ppu_reset :: proc() {
    scanlineCounter = 204
    /*apa :[]Color= screen.GetPixels()
    for i :u32= 0 i < apa.Length i += 1 {
        apa[i] = Color.white
    }
    screen.SetPixels(apa)
    screen.Apply()*/
}

ppu_step :: proc(cycle: u16) -> bool {
    lcdc := bus_read8(u16(IO.LCDC))
    stat := bus_read8(u16(IO.STAT))
    status := bus_get(u16(IO.STAT))
    ly := bus_read8(u16(IO.LY))
    reqIntr: bool
    mode := status & 3
    
    if(bit_test(lcdc, 7) == false) {	//LCD is off, dont draw, reset display
        ppu_reset_LCD(stat)
        return false
    }
    scanlineCounter -= i32(cycle)

    switch mode {
    case 0:		// H-blank
        if(scanlineCounter < 0) {
            scanlineCounter += 456
            if(ly >= 144) {	// -> Mode 1 - V-blank
                status = bit_set1(status, 0)
                status = bit_clear(status, 1)
                reqIntr = bit_test(status, 4)
                iFlags := bus_get(u16(IO.IF))
                bus_write(u16(IO.IF), bit_set1(iFlags, 0))
                //fmt.println("Draw")
                return true // Draw screen
            } else {		// -> Mode 2 - OAM
                status = bit_clear(status, 0)
                status = bit_set1(status, 1)
                reqIntr = bit_test(status, 5)
            }
            ly += 1
            ppu_set_ly(ly)
        }
        break
    case 1:		// V-blank
        if(scanlineCounter < 0) {
            scanlineCounter += 456
            ly += 1
            if(ly > 153) {	// -> Mode 2 - OAM
                ly = 0
                status = bit_clear(status, 0)
                status = bit_set1(status, 1)
                reqIntr = bit_test(status, 5)
            }
            ppu_set_ly(ly)
        }
        break
    case 2:		// OAM
        if(scanlineCounter < 376) {	// -> Mode 3 - OAM + RAM
            status = bit_set1(status, 1)
            status = bit_set1(status, 0)
        }
        break
    case 3:		// OAM + RAM
        if(scanlineCounter < 204) {	// -> Mode 0 - H-blank
            status = bit_clear(status, 1)
            status = bit_clear(status, 0)
            ppu_draw_scanline(lcdc, ly)
            reqIntr = bit_test(status, 3)
        }
        break
    }

    if(reqIntr) {
        iFlags := bus_get(u16(IO.IF))
        bus_write(u16(IO.IF), bit_set1(iFlags, 1))
    }
    bus_write(u16(IO.STAT), status)
    return false
}

ppu_reset_LCD :: proc(stat: u8) {
    scanlineCounter = 204
    bus_set(u16(IO.LY), 0)
    stat1 := stat & 0xFC
    bus_write(u16(IO.STAT), stat1)
}

ppu_set_ly :: proc(ly: u8) {
    status := bus_get(u16(IO.STAT))

    if (ly == bus_get(u16(IO.LYC))) {
        status = bit_set1(status, 2)
        if(bit_test(status, 6)) {
            iFlags := bus_get(u16(IO.IF))
            bus_write(u16(IO.IF), bit_set1(iFlags, 1))
        }
    } else {
        status = bit_clear(status, 2)    
    }

    bus_set(u16(IO.STAT), status)
    bus_set(u16(IO.LY), ly)
}

ppu_draw_scanline :: proc(lcdc: u8, ly: u8) {
    if(bit_test(lcdc, 0)) {
        ppu_draw_background(lcdc, ly)
    }
    if(bit_test(lcdc, 1)) {
        ppu_drawSprites(lcdc, ly)
    }
    ppu_convert_row(ly)
}

ppu_drawSprites :: proc(lcdc: u8, ly: u8) {
    /*for(int i = 39; i >= 0; i--)
    {
        int yPos = memory.Read(0xFE00 + (i * 4));
        byte index = (byte)(memory.Read(0xFE00 + (i * 4 + 2)));

        if(yPos == 0 || yPos >= 160)
            continue;

        yPos -= 16;
        byte ySize;
        if(Bit.Test(lcdc, 2))
        {
            index = Bit.Clear(index, 0);
            ySize = 16;
        }
        else
            ySize = 8;

        if(yPos <= ly && (yPos + ySize) > ly)
        {
            int xPos = memory.Read(0xFE00 + (i * 4 + 1)) - 8;
            byte flags = memory.Read(0xFE00 + (i * 4 + 3));
            bool xFlip = Bit.Test(flags, 5);
            bool yFlip = Bit.Test(flags, 6);
            int line = ly - yPos;
            if(yFlip)
                line = ((ySize - 1) - line);
            
            ushort address = (ushort)(0x8000 + (index * 16) + (line * 2));
            byte line1 = memory.Read(address);
            byte line2 = memory.Read(address + 1);
        
            for(int j = 7; j >= 0; j--)
            {
                int colorBit = j;
                if(xFlip)
                    colorBit = (7 - colorBit);

                byte colorNum = Bit.Get(line2, (byte)colorBit);
                colorNum <<= 1;
                colorNum |= Bit.Get(line1, (byte)colorBit);

                int xPix = 0 - j;
                xPix += 7;
                int pixPos = xPix + xPos;

                if(pixPos >= 160 || pixPos < 0)
                    continue;

                if(Bit.Test(flags, 7) && screenRow[pixPos] != 0)
                    continue;

                if(colorNum == 0)
                    continue;

                ushort obp = (ushort)(Bit.Test(flags, 4)?IO.OBP1:IO.OBP0);
                Color color = GetColor(colorNum, obp);
                
                screenRow[pixPos] = (byte)(Bit.Test(flags, 4)?colorNum + 8:colorNum + 4);
            }
        }
    }*/
}

ppu_draw_background :: proc(lcdc: u8, ly: u8) {
    scy := bus_read8(u16(IO.SCY))
    scx := bus_read8(u16(IO.SCX))
    wy := bus_read8(u16(IO.WY))
    wx := bus_read8(u16(IO.WX)) - 7
    yPos: u8
    backMem: u16
    window: bool

    tileData: u16
    if(bit_test(lcdc, 4)) {
        tileData = 0x8000
    } else {
        tileData = 0x8800
    }

    if (bit_test(lcdc, 5)) {
        if (wy <= ly) {
            window = true
        }
    }

    if (!window) {
        if (bit_test(lcdc, 3)) {
            backMem = 0x9C00
        } else {
            backMem = 0x9800
        }
        yPos = scy + ly
    } else {
        if (bit_test(lcdc, 6)) {
            backMem = 0x9C00
        } else {
            backMem = 0x9800
        }
        yPos = ly - wy
    }

    tileRow := (u16(yPos / 8) * 32)

    for pixel :u8= 0; pixel < 160; pixel += 1 {
        xPos := scx + pixel
        if (window) {
            if (pixel >= wx) {
                xPos = pixel - wx
            }
        } 

        tileCol := u16(xPos / 8)
        tileAddress := backMem + tileRow + tileCol
        tileNum: u8
        tileLocation := tileData

        tileNum = bus_read8(tileAddress)
        if(tileData == 0x8000) {
            tileLocation += u16(tileNum) * 16
        } else {
            tileLocation = u16(i16(tileLocation) + (i16(i8(tileNum)) + 128) * 16)
        }

        line := u16(yPos % 8)
        line *= 2
        data1 := bus_read8(tileLocation + line)
        data2 := bus_read8(tileLocation + line + 1)
        colorBit := i8(xPos % 8)
        colorBit -= 7
        colorBit *= -1

        colorNum := bit_get(data2, u8(colorBit))
        colorNum <<= 1
        colorNum |= bit_get(data1, u8(colorBit))

        screenRow[pixel] = colorNum
    }
}

ppu_convert_row :: proc(ly: u8) {
    for x :u8= 0; x < 160; x += 1 {
        color: u16
        pixelColor := screenRow[x]
        if(pixelColor < 4) {
            color = ppu_get_color(pixelColor, IO.BGP)
        } else if(pixelColor < 8) {
            color = ppu_get_color((pixelColor - 4), IO.OBP0)
        } else {
            color = ppu_get_color((pixelColor - 8), IO.OBP1)
        }
        screen_buffer[x + (ly * WIN_WIDTH)] = color
    }
}

ppu_get_color :: proc(colorNum: u8, address: IO) -> u16 {
    bgp := bus_read8(u16(address))
    hi: u8
    lo: u8

    switch (colorNum) {
    case 0:
        hi = 1; lo = 0
        break
    case 1:
        hi = 3; lo = 2
        break
    case 2:
        hi = 5; lo = 4
        break
    case 3:
        hi = 7; lo = 6
        break
    }

    // use the palette to get the colour
    colour := bit_get(bgp, hi) << 1
    colour |= bit_get(bgp, lo)

    res: u16
    switch (colour) {
    case 0:
        res = 0
        break
    case 1:
        res = 0x294A
        break
    case 2:
        res = 0x5294
        break
    case 3:
        res = 0xFFFF
        break
    }
    return res
}

ppu_get_pixels :: proc() -> []u16 {
    return screen_buffer[:]
}