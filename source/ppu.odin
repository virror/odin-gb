package main

import "core:fmt"
import "core:slice"

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

Attrs :: bit_field u8 {
    cgb_palette: bool   | 3,
    bank: bool          | 1,
    gb_palette: bool    | 1,
    xflip: bool         | 1,
    yflip: bool         | 1,
    prio: bool          | 1,
}

Sprite :: struct {
    ypos: u8,
    xpos: u8,
    index: u8,
    flags: Attrs,
    ipos: u8,
}

scanlineCounter :i32= 204
screenRow: [160]u8
screen_buffer: [WIN_WIDTH * WIN_HEIGHT]u16
window_line: u8
sprites: [10]Sprite

ppu_reset :: proc() {
    scanlineCounter = 204
}

ppu_step :: proc() -> bool {
    retval: bool
    lcdc := Llcd(bus_get(IO_LCDC))
    status := Status(bus_get(IO_STAT))
    iFlags := IRQ(bus_get(IO_IF))
    ly := bus_get(IO_LY)
    
    if(!lcdc.lcd_enable) {	//LCD is off, dont draw, reset display
        ppu_reset_LCD(status)
        return false
    }
    scanlineCounter -= 4

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
                window_line = 0
                status.mode = .OAM
                iFlags.lcdc = status.oam
            }
            ppu_set_ly(ly, &status, &iFlags)
        }
        break
    case .OAM:		// OAM
        if(scanlineCounter < 376) {	// -> Mode 3 - OAM + RAM
            ppu_get_sprites(ly, lcdc)
            slice.sort_by(sprites[:], sort_func)
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

    bus_write(IO_STAT, u8(status))
    bus_write(IO_IF, u8(iFlags))
    return retval
}

ppu_reset_LCD :: proc(stat: Status) {
    scanlineCounter = 204
    bus_set(IO_LY, 0)
    stat1 := u8(stat) & 0xFC
    bus_write(IO_STAT, stat1)
}

ppu_set_ly :: proc(ly: u8, status: ^Status, iflags: ^IRQ) {
    if(ly == bus_get(IO_LYC)) {
        status.lyc_ly = true
        if(status.lyc) {
            iflags.lcdc = true
        }
    } else {
        status.lyc_ly = false
    }
    bus_set(IO_LY, ly)
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

ppu_get_sprites :: proc(ly: u8, lcdc: Llcd) {
    sprite_idx: u8
    ySize :u8= 8
    sprites = {}
    if(lcdc.obj_size) {
        ySize = 16
    }
    for i :u8= 0; i < 40; i += 1 {
        yPos := bus_read(0xFE00 + u16(i * 4))
        if(yPos == 0 || yPos >= 160) {
            continue
        }
        if(yPos <= ly + 16 && (yPos + ySize) > ly + 16) {
            sprites[sprite_idx].xpos = bus_read(0xFE00 + u16(i * 4 + 1)) - 8
            sprites[sprite_idx].ypos = yPos
            index := bus_read(0xFE00 + u16(i * 4 + 2))
            if(ySize == 16) {
                index = index & 0xFE //Clear bit 0
            }
            sprites[sprite_idx].index = index
            sprites[sprite_idx].flags = Attrs(bus_read(0xFE00 + u16(i * 4 + 3)))
            sprites[sprite_idx].ipos = i
            sprite_idx += 1
        }
        if(sprite_idx == 10) {
            break
        }
    }
}

sort_func :: proc(i: Sprite, j: Sprite) -> bool {
    if(i.xpos == j.xpos) {
        return i.ipos > j.ipos
    } else {
        return i.xpos > j.xpos
    }
}

ppu_drawSprites :: proc(lcdc: Llcd, ly: u8) {
    ySize :u8= 8
    if(lcdc.obj_size) {
        ySize = 16
    }
    for sprite in sprites {
        if(sprite.ypos == 0 || sprite.ypos >= 160) {
            continue
        }
        xFlip := sprite.flags.xflip
        yFlip := sprite.flags.yflip
        line := ly + 16 - sprite.ypos
        if(yFlip) {
            line = (ySize - 1 - line)
        }

        address :u16= 0x8000 + u16(sprite.index) * 16 + u16(line) * 2
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
            pixPos := xPix + sprite.xpos

            if(pixPos >= 160 || pixPos < 0) {
                continue
            }
            if(sprite.flags.prio && screenRow[pixPos] != 0) {
                continue
            }
            if(colorNum == 0) {
                continue
            }
            screenRow[pixPos] = (sprite.flags.gb_palette?colorNum + 8:colorNum + 4)
        }
    }
}

ppu_draw_background :: proc(lcdc: Llcd, ly: u8) {
    scy := bus_read(IO_SCY)
    scx := bus_read(IO_SCX)
    wy := bus_read(IO_WY)
    wx := bus_read(IO_WX)
    yPos: u8
    backMem: u16
    window: bool

    tileData: u16
    if(lcdc.bg_tiles) {
        tileData = 0x8000
    } else {
        tileData = 0x8800
    }

    if(lcdc.window_enable) {
        if(wy <= ly && wx < WIN_WIDTH) {
            window = true
        }
    }

    for pixel :u8= 0; pixel < 160; pixel += 1 {
        xPos := scx + pixel
        yPos = scy + ly
        if(lcdc.bg_map) {
            backMem = 0x9C00
        } else {
            backMem = 0x9800
        }
        if(window) {
            if(pixel + 7 >= wx) {
                xPos = pixel + 7 - wx
                yPos = window_line
                if(lcdc.window_map) {
                    backMem = 0x9C00
                } else {
                    backMem = 0x9800
                }
            }
        }
        tileRow := (u16(yPos / 8) * 32)
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
    if(window) {
        window_line += 1
    }
}

ppu_convert_row :: proc(ly: u8) {
    for x :u8= 0; x < 160; x += 1 {
        color: u16
        pixelColor := screenRow[x]
        if(pixelColor < 4) {
            color = ppu_get_color(pixelColor, IO_BGP)
        } else if(pixelColor < 8) {
            color = ppu_get_color((pixelColor - 4), IO_OBP0)
        } else {
            color = ppu_get_color((pixelColor - 8), IO_OBP1)
        }
        screen_buffer[u16(x) + (u16(ly) * u16(WIN_WIDTH))] = color
    }
}

ppu_get_color :: proc(colorNum: u8, address: u16) -> u16 {
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