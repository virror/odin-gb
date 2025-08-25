package main

import "core:fmt"

Mode :: enum u8 {
    HBlank = 0,
    VBlank = 1,
    OAM = 2,
    Draw = 3,
}

IRQ :: bit_field u8 {
    VBlank: bool    | 1,
    lcdc: bool      | 1,
    Timer: bool     | 1,
    Serial: bool    | 1,
    Joypad: bool    | 1,
    Unused: u8      | 3,
}

Status :: bit_field u8 {
    mode: Mode      | 2,
    lyc_ly: bool    | 1,
    hblank: bool    | 1,
    vblank: bool    | 1,
    oam: bool       | 1,
    lyc: bool       | 1,
    unused: bool    | 1,
}

Llcd :: bit_field u8 {
    bg_enable: bool     | 1,
    obj_enable: bool    | 1,
    obj_size: bool      | 1,
    bg_map: bool        | 1,
    bg_tiles: bool      | 1,
    window_enable: bool | 1,
    window_map: bool    | 1,
    lcd_enable: bool    | 1,
}

scanlineCounter :i32= 204
screenRow: [160]u8
screen_buffer: [WIN_WIDTH * WIN_HEIGHT]u16

ppu_reset :: proc() {
    scanlineCounter = 204
}

ppu_step :: proc(cycle: u16) -> bool {
    retval: bool
    lcdc := Llcd(bus_get(u16(IO.LCDC)))
    status := Status(bus_get(u16(IO.STAT)))
    iFlags := IRQ(bus_get(u16(IO.IF)))
    ly := bus_get(u16(IO.LY))
    
    if(!lcdc.lcd_enable) {	//LCD is off, dont draw, reset display
        ppu_reset_LCD(status)
        return false
    }
    scanlineCounter -= i32(cycle)

    switch status.mode {
    case .HBlank:		// H-blank
        if(scanlineCounter < 0) {
            scanlineCounter += 456
            if(ly >= 143) {	// -> Mode 1 - V-blank
                status.mode = .VBlank
                iFlags.lcdc = status.vblank
                iFlags.VBlank = true
                retval = true // Draw screen
            } else {		// -> Mode 2 - OAM
                status.mode = .OAM
                iFlags.lcdc = status.oam
            }
            ly += 1
            ppu_set_ly(ly, &status, &iFlags)
        }
        break
    case .VBlank:		// V-blank
        if(scanlineCounter < 0) {
            scanlineCounter += 456
            ly += 1
            if(ly > 153) {	// -> Mode 2 - OAM
                ly = 0
                status.mode = .OAM
                iFlags.lcdc = status.oam
            }
            ppu_set_ly(ly, &status, &iFlags)
        }
        break
    case .OAM:		// OAM
        if(scanlineCounter < 376) {	// -> Mode 3 - OAM + RAM
            status.mode = .Draw
        }
        break
    case .Draw:		// OAM + RAM
        if(scanlineCounter < 204) {	// -> Mode 0 - H-blank
            status.mode = .HBlank
            ppu_draw_scanline(lcdc, ly)
            iFlags.lcdc = status.hblank
        }
        break
    }

    bus_write(u16(IO.STAT), u8(status))
    bus_write(u16(IO.IF), u8(iFlags))
    return retval
}

ppu_reset_LCD :: proc(stat: Status) {
    scanlineCounter = 204
    bus_set(u16(IO.LY), 0)
    stat1 := u8(stat) & 0xFC
    bus_write(u16(IO.STAT), stat1)
}

ppu_set_ly :: proc(ly: u8, status: ^Status, iflags: ^IRQ) {
    if (ly == bus_get(u16(IO.LYC))) {
        status.lyc_ly = true
        if(status.lyc) {
            iflags.lcdc = true
        }
    } else {
        status.lyc_ly = false
    }
    bus_set(u16(IO.LY), ly)
}

ppu_draw_scanline :: proc(lcdc: Llcd, ly: u8) {
    if(lcdc.bg_enable) {
        ppu_draw_background(lcdc, ly)
    }
    if(lcdc.obj_enable) {
        ppu_drawSprites(lcdc, ly)
    }
    ppu_convert_row(ly)
}

ppu_drawSprites :: proc(lcdc: Llcd, ly: u8) {
    for i :i16= 39; i >= 0; i -= 1 {
        yPos := i16(bus_read(0xFE00 + u16(i * 4)))
        index := bus_read(0xFE00 + u16(i * 4 + 2))

        if(yPos == 0 || yPos >= 160) {
            continue
        }

        yPos -= 16
        ySize: u8
        if(lcdc.obj_size) {
            index = index & 0xFE //Clear bit 0
            ySize = 16
        } else {
            ySize = 8
        }

        if(yPos <= i16(ly) && (yPos + i16(ySize)) > i16(ly)) {
            xPos := bus_read(0xFE00 + u16(i * 4 + 1)) - 8
            flags := bus_read(0xFE00 + u16(i * 4 + 3))
            xFlip := bit_test(flags, 5)
            yFlip := bit_test(flags, 6)
            line := i16(ly) - yPos
            if(yFlip) {
                line = (i16(ySize - 1) - line)
            }

            address :u16= 0x8000 + u16(index) * 16 + u16(line) * 2
            line1 := bus_read(address)
            line2 := bus_read(address + 1)

            for j :i8= 7; j >= 0; j -= 1 {
                colorBit := u8(j)
                if(xFlip) {
                    colorBit = (7 - colorBit)
                }

                colorNum := bit_get(line2, colorBit)
                colorNum <<= 1
                colorNum |= bit_get(line1, colorBit)

                xPix :u8= 7
                xPix -= u8(j)
                pixPos := xPix + xPos

                if(pixPos >= 160 || pixPos < 0) {
                    continue
                }

                if(bit_test(flags, 7) && screenRow[pixPos] != 0) {
                    continue
                }
                if(colorNum == 0) {
                    continue
                }

                //obp := (bit_test(flags, 4)?IO.OBP1:IO.OBP0)
                //color := ppu_get_color(colorNum, obp)
                screenRow[pixPos] = (bit_test(flags, 4)?colorNum + 8:colorNum + 4)
            }
        }
    }
}

ppu_draw_background :: proc(lcdc: Llcd, ly: u8) {
    scy := bus_read(u16(IO.SCY))
    scx := bus_read(u16(IO.SCX))
    wy := bus_read(u16(IO.WY))
    wx := i16(i8(bus_read(u16(IO.WX)) - 7))
    yPos: u8
    backMem: u16
    window: bool

    tileData: u16
    if(lcdc.bg_tiles) {
        tileData = 0x8000
    } else {
        tileData = 0x8800
    }

    if (lcdc.window_enable) {
        if (wy <= ly) {
            window = true
        }
    }

    if (!window) {
        if (lcdc.bg_map) {
            backMem = 0x9C00
        } else {
            backMem = 0x9800
        }
        yPos = scy + ly
    } else {
        if (lcdc.window_map) {
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
            if (i16(pixel) >= wx) {
                xPos = u8(i16(pixel) - wx)
            }
        } 

        tileCol := u16(xPos / 8)
        tileAddress := backMem + tileRow + tileCol
        tileLocation := tileData

        tileNum := bus_read(tileAddress)
        if(tileData == 0x8000) {
            tileLocation += u16(tileNum) * 16
        } else {
            tileLocation = u16(i16(tileLocation) + (i16(i8(tileNum)) + 128) * 16)
        }

        line := u16(yPos % 8)
        line *= 2
        data1 := bus_read(tileLocation + line)
        data2 := bus_read(tileLocation + line + 1)
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
        screen_buffer[u16(x) + (u16(ly) * u16(WIN_WIDTH))] = color
    }
}

ppu_get_color :: proc(colorNum: u8, address: IO) -> u16 {
    bgp := bus_read(u16(address))
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
        res = 0xFFFF
        break
    case 1:
        res = 0x5294
        break
    case 2:
        res = 0x294A
        break
    case 3:
        res = 0
        break
    }
    return res
}

ppu_get_pixels :: proc() -> []u16 {
    return screen_buffer[:]
}