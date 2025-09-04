package main

import sdl "vendor:sdl3"
import "base:runtime"
import "core:math/linalg"
import "core:strings"
import "core:log"
import "core:mem"
import "core:fmt"

Vertex_Data :: struct {
    pos: Vector2f,
    col: Vector3f,
    tex: Vector2f,
}

resolution: Vector2f = {WIN_WIDTH, WIN_HEIGHT}
@(private="file")
gpu: ^sdl.GPUDevice
@(private="file")
win: ^sdl.Window
@(private="file")
pipeline_game: ^sdl.GPUGraphicsPipeline
@(private="file")
vertex_buf: ^sdl.GPUBuffer
@(private="file")
index_buf: ^sdl.GPUBuffer
@(private="file")
texture: sdl.GPUTextureSamplerBinding
@(private="file")
cmd_buf: ^sdl.GPUCommandBuffer
@(private="file")
render_pass: ^sdl.GPURenderPass

default_context: runtime.Context

render_init :: proc(window: ^sdl.Window) {
    context.logger = log.create_console_logger()
    default_context = context

    sdl.SetLogPriorities(.VERBOSE)
    sdl.SetLogOutputFunction(proc "c" (userdata: rawptr, category: sdl.LogCategory, priority: sdl.LogPriority, message: cstring) {
        context = default_context
        log.debugf("SDL {} [{}] {}", category, priority, message)
    }, nil)

    gpu = sdl.CreateGPUDevice({.SPIRV, .METALLIB}, false, nil)
    if !sdl.ClaimWindowForGPUDevice(gpu, window) {
        panic("GPU failed to claim window")
    }
    win = window

    create_quad()

    when ODIN_OS == .Darwin {
        vert_shader := shader_create(#load("../shaders/shader_vert.metal"), .VERTEX, 1, 0, {.MSL}, "main0")
        frag_shader := shader_create(#load("../shaders/shader_frag.metal"), .FRAGMENT, 2, 1, {.MSL}, "main0")
        pipeline_game = pipeline_create(vert_shader, frag_shader)
    } else {
        vert_shader := shader_create(#load("../shaders/shader.spv.vert"), .VERTEX, 0, 0, {.SPIRV})
        frag_shader := shader_create(#load("../shaders/shader.spv.frag"), .FRAGMENT, 0, 1, {.SPIRV})
        pipeline_game = pipeline_create(vert_shader, frag_shader)
    }
    render_set_shader()
}

@(private="file")
pipeline_create :: proc(vert_shader: ^sdl.GPUShader, frag_shader: ^sdl.GPUShader, ) -> ^sdl.GPUGraphicsPipeline {
    vert_attrs := []sdl.GPUVertexAttribute {
        {
            location = 0,
            buffer_slot = 0,
            format = .FLOAT2,
            offset = u32(offset_of(Vertex_Data, pos)),
        },
        {
            location = 1,
            buffer_slot = 0,
            format = .FLOAT3,
            offset = u32(offset_of(Vertex_Data, col)),
        },{
            location = 2,
            buffer_slot = 0,
            format = .FLOAT2,
            offset = u32(offset_of(Vertex_Data, tex)),
        },
    }

    pipeline := sdl.CreateGPUGraphicsPipeline(gpu, {
        vertex_shader = vert_shader,
        fragment_shader = frag_shader,
        primitive_type = .TRIANGLELIST,
        vertex_input_state = {
            num_vertex_buffers = 1,
            vertex_buffer_descriptions = &(sdl.GPUVertexBufferDescription {
                slot = 0,
                pitch = size_of(Vertex_Data),
            }),
            num_vertex_attributes = u32(len(vert_attrs)),
            vertex_attributes = raw_data(vert_attrs),
        },
        target_info = {
            num_color_targets = 1,
            color_target_descriptions = &(sdl.GPUColorTargetDescription {
                format = sdl.GetGPUSwapchainTextureFormat(gpu, win),
                blend_state = {
                    src_color_blendfactor = .SRC_ALPHA,
                    dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA,
                    color_blend_op = .ADD,
                    src_alpha_blendfactor = .ONE,
                    dst_alpha_blendfactor = .ZERO,
                    alpha_blend_op = .ADD,
                    enable_blend = true,
                },
            }),
        },
    })
    sdl.ReleaseGPUShader(gpu, vert_shader)
    sdl.ReleaseGPUShader(gpu, frag_shader)
    return pipeline
}

render_deinit :: proc() {
    sdl.ReleaseGPUBuffer(gpu, vertex_buf)
    sdl.ReleaseGPUBuffer(gpu, index_buf)
    sdl.ReleaseGPUGraphicsPipeline(gpu, pipeline_game)
    sdl.ReleaseWindowFromGPUDevice(gpu, win)
    sdl.DestroyGPUDevice(gpu)
}

render_set_shader :: proc() {
    sdl.BindGPUGraphicsPipeline(render_pass, pipeline_game)
}

render_update_viewport :: proc(width, height: i32) {
    resolution = {f32(width), f32(height)}
}

@(private="file")
create_quad :: proc() {
    vertices := []Vertex_Data {
        {{-1, 1}, {1, 1, 1}, {0, 0}},
        {{1, 1},  {1, 1, 1}, {1, 0}},
        {{-1, -1},{1, 1, 1}, {0, 1}},
        {{1, -1}, {1, 1, 1}, {1, 1}},
    }

    indices := []u16 {
        0, 1, 2,
        2, 1, 3,
     }

    vert_size := u32(len(vertices) * size_of(vertices[0]))
    vertex_buf = sdl.CreateGPUBuffer(gpu, {
        usage = {.VERTEX},
        size = vert_size,
    })
    index_size := u32(len(indices) * size_of(indices[0]))
    index_buf = sdl.CreateGPUBuffer(gpu, {
        usage = {.INDEX},
        size = index_size,
    })
    trans_buf := sdl.CreateGPUTransferBuffer(gpu, {
        usage = .UPLOAD,
        size = vert_size + index_size,
    })
    trans_mem := transmute([^]byte)sdl.MapGPUTransferBuffer(gpu, trans_buf, false)
    mem.copy(trans_mem, raw_data(vertices), int(vert_size))
    mem.copy(trans_mem[vert_size:], raw_data(indices), int(index_size))
    sdl.UnmapGPUTransferBuffer(gpu, trans_buf)
    copy_cmd_buf := sdl.AcquireGPUCommandBuffer(gpu)
    copy_pass := sdl.BeginGPUCopyPass(copy_cmd_buf)
    sdl.UploadToGPUBuffer(copy_pass, {trans_buf, 0}, {vertex_buf, 0, vert_size}, false)
    sdl.UploadToGPUBuffer(copy_pass, {trans_buf, vert_size}, {index_buf, 0, index_size}, false)
    sdl.EndGPUCopyPass(copy_pass)
    if !sdl.SubmitGPUCommandBuffer(copy_cmd_buf) {
        panic("Cant submit GPU cmd buffer")
    }
    sdl.ReleaseGPUTransferBuffer(gpu, trans_buf)
}

@(private="file")
shader_create :: proc(shader_data: []u8, stage: sdl.GPUShaderStage, buffers: u32,
                      samplers: u32, format: sdl.GPUShaderFormat, entrypoint: cstring = "main") -> ^sdl.GPUShader {
    shader := sdl.CreateGPUShader(gpu, {
        code_size = len(shader_data),
        code = raw_data(shader_data),
        entrypoint = entrypoint,
        format = format,
        stage = stage,
        num_uniform_buffers = buffers,
        num_samplers = samplers,
    })
    return shader
}

texture_create :: proc(w: u32, h: u32, data: ^u16) -> sdl.GPUTextureSamplerBinding {
    texture.texture = sdl.CreateGPUTexture(gpu, {
        type = .D2,
        format = .B5G5R5A1_UNORM,
        usage = {.SAMPLER},
        width = w,
        height = h,
        layer_count_or_depth = 1,
        num_levels = 1,
    })
    tex_size := w * h * 2
    trans_buf := sdl.CreateGPUTransferBuffer(gpu, {
        usage = .UPLOAD,
        size = tex_size,
    })
    trans_mem := sdl.MapGPUTransferBuffer(gpu, trans_buf, false)
    mem.copy(trans_mem, data, int(tex_size))
    sdl.UnmapGPUTransferBuffer(gpu, trans_buf)
    copy_cmd_buf := sdl.AcquireGPUCommandBuffer(gpu)
    copy_pass := sdl.BeginGPUCopyPass(copy_cmd_buf)
    sdl.UploadToGPUTexture(copy_pass, {transfer_buffer = trans_buf},
        {
            texture = texture.texture,
            w = w,
            h = h,
            d = 1,
        }, false)
    sdl.EndGPUCopyPass(copy_pass)
    if !sdl.SubmitGPUCommandBuffer(copy_cmd_buf) {
        panic("Cant submit GPU cmd buffer")
    }
    sdl.ReleaseGPUTransferBuffer(gpu, trans_buf)
    texture.sampler = sdl.CreateGPUSampler(gpu, {})
    return texture
}

texture_destroy :: proc(texture: sdl.GPUTextureSamplerBinding) {
    sdl.ReleaseGPUSampler(gpu, texture.sampler)
    sdl.ReleaseGPUTexture(gpu, texture.texture)
}

render_pre :: proc() {
    cmd_buf = sdl.AcquireGPUCommandBuffer(gpu)
    swap_text: ^sdl.GPUTexture
    if !sdl.WaitAndAcquireGPUSwapchainTexture(cmd_buf, win, &swap_text, nil, nil) {
        panic("Failed to acquire swapchain texture")
    }

    if swap_text != nil {
        color_info := sdl.GPUColorTargetInfo {
            texture = swap_text,
            load_op = .CLEAR,
            clear_color = {0.098, 0.07, 0.059, 1.0},
            store_op = .STORE,
        }
        render_pass = sdl.BeginGPURenderPass(cmd_buf, &color_info, 1, nil)
        sdl.BindGPUVertexBuffers(render_pass, 0, &(sdl.GPUBufferBinding {buffer = vertex_buf}), 1)
        sdl.BindGPUIndexBuffer(render_pass, {buffer = index_buf}, ._16BIT)
    } else {
        render_pass = nil
    }
}

render_quad :: proc() {
    if render_pass != nil {
        sdl.BindGPUFragmentSamplers(render_pass, 0, &texture, 1)
        sdl.DrawGPUIndexedPrimitives(render_pass, 6, 1, 0, 0, 0)
    }
}

render_post :: proc() {
    sdl.EndGPURenderPass(render_pass)
    if !sdl.SubmitGPUCommandBuffer(cmd_buf) {
        panic("Cant submit GPU cmd buffer")
    }
}
