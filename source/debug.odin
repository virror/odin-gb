package main

import "core:fmt"
import sdl "vendor:sdl3"
import sdlttf "vendor:sdl3/ttf"
when(DEBUG) {
font: ^sdlttf.Font

debug_init :: proc() {
    font = sdlttf.OpenFont("SpaceMono-Regular.ttf", 18)
}

debug_draw :: proc() {
    sdl.RenderClear(debug_render)
    
    debug_draw_reg("PC  ", PC,     10, 10)
    debug_draw_reg("SP  ", SP,     10, 35)
    debug_draw_reg("AF  ", reg.AF, 10, 60)
    debug_draw_reg("BC  ", reg.BC, 10, 85)
    debug_draw_reg("DE  ", reg.DE, 10, 110)
    debug_draw_reg("HL  ", reg.HL, 10, 135)

    debug_draw_flag("Z  ", reg.F.Z, 150, 10)
    debug_draw_flag("N  ", reg.F.N, 150, 35)
    debug_draw_flag("H  ", reg.F.H, 150, 60)
    debug_draw_flag("C  ", reg.F.C, 150, 85)

    debug_draw_op("->", PC, 10, 210)

    sdl.RenderPresent(debug_render)
}

debug_draw_op :: proc(opText: cstring, pc: u16, posX: f32, posY: f32) {
    op := state.op
    line := fmt.caprintf("%x %s", state.number, op.desc)
    debug_text(line, posX, posY, {230, 230, 230, 230})
}

debug_draw_reg :: proc(regText: cstring, reg: u16, posX: f32, posY: f32) {
    line := fmt.caprintf("%s %4x", regText, reg)
    debug_text(line, posX, posY, {230, 230, 230, 230})
}

debug_draw_flag :: proc(flagText: cstring, flag: bool, posX: f32, posY: f32) {
    line := fmt.caprintf("%s %d", flagText, u8(flag))
    debug_text(line, posX, posY, {230, 230, 230, 230})
}

debug_quit :: proc() {
    sdlttf.CloseFont(font)
}

debug_text :: proc(text: cstring, posX: f32, posY: f32, color: sdl.Color) {
    surface := sdlttf.RenderText_Solid(font, text, len(text), color)
    texture := sdl.CreateTextureFromSurface(debug_render, surface)
   
    texW :f32= 0
    texH :f32= 0
    sdl.GetTextureSize(texture, &texW, &texH)
   
    text_rect: sdl.FRect
    text_rect.x = posX
    text_rect.y = posY
    text_rect.w = texW
    text_rect.h = texH

    sdl.RenderTexture(debug_render, texture, nil, &text_rect)
    sdl.DestroySurface(surface)
    sdl.DestroyTexture(texture)
}
} else {
    debug_draw :: proc() {}
}