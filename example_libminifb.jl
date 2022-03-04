using CEnum
import DataStructures as DS
import SimpleDraw as SD

@cenum mfb_update_state::Int32 begin
    STATE_OK = 0
    STATE_EXIT = -1
    STATE_INVALID_WINDOW = -2
    STATE_INVALID_BUFFER = -3
    STATE_INTERNAL_ERROR = -4
end

const mfb_window = Cvoid
const mfb_timer = Cvoid
const mfb_active_func = Ptr{Cvoid}
const mfb_resize_func = Ptr{Cvoid}
const mfb_keyboard_func = Ptr{Cvoid}
const mfb_char_input_func = Ptr{Cvoid}
const mfb_mouse_button_func = Ptr{Cvoid}
const mfb_mouse_move_func = Ptr{Cvoid}
const mfb_mouse_scroll_func = Ptr{Cvoid}

const libminifb = "./build/products/lib/libminifb.so"

function mfb_open(title, width, height)
    ccall((:mfb_open, libminifb), Ptr{mfb_window}, (Cstring, UInt32, UInt32), title, width, height)
end

function mfb_update(window, buffer)
    ccall((:mfb_update, libminifb), mfb_update_state, (Ptr{mfb_window}, Ptr{Cvoid}), window, buffer)
end

function mfb_wait_sync(window)
    ccall((:mfb_wait_sync, libminifb), Bool, (Ptr{mfb_window},), window)
end

function mfb_get_mouse_x(window)
    ccall((:mfb_get_mouse_x, libminifb), Cint, (Ptr{mfb_window},), window)
end

function mfb_get_mouse_y(window)
    ccall((:mfb_get_mouse_y, libminifb), Cint, (Ptr{mfb_window},), window)
end

function mfb_get_mouse_scroll_x(window)
    ccall((:mfb_get_mouse_scroll_x, libminifb), Cfloat, (Ptr{mfb_window},), window)
end

function mfb_get_mouse_scroll_y(window)
    ccall((:mfb_get_mouse_scroll_y, libminifb), Cfloat, (Ptr{mfb_window},), window)
end

function mfb_get_mouse_button_buffer(window)
    ccall((:mfb_get_mouse_button_buffer, libminifb), Ptr{UInt8}, (Ptr{mfb_window},), window)
end

function mfb_get_key_buffer(window)
    ccall((:mfb_get_key_buffer, libminifb), Ptr{UInt8}, (Ptr{mfb_window},), window)
end

function draw_lines!(image, lines, color)
    font = SD.TERMINUS_32_16
    height_font = 32

    for (i, text) in enumerate(lines)
        position = SD.Point(1 + (i - 1) * height_font, 1)
        SD.draw!(image, SD.TextLine(position, text, font), color)
    end

    return nothing
end

function start(height_image, width_image, background_color, text_color, sliding_window_size)
    image = zeros(UInt32, height_image, width_image)

    frame_buffer = permutedims(image)

    window = mfb_open("Example", width_image, height_image)

    I = typeof(time())
    lines = String[]
    queue = DS.Queue{I}()

    t1 = zero(I)
    t2 = zero(I)
    delta_t = zero(I)
    average_delta_t = zero(I)
    delta_t_oldest = zero(I)
    average_delta_t_sliding_window = zero(I)

    i = 0

    while mfb_wait_sync(window)
        t1 = time()

        mouse_x = mfb_get_mouse_x(window)
        mouse_y = mfb_get_mouse_y(window)
        mouse_scroll_x = mfb_get_mouse_scroll_x(window)
        mouse_scroll_y = mfb_get_mouse_scroll_y(window)
        mouse_button_buffer = mfb_get_mouse_button_buffer(window)
        key_buffer = mfb_get_key_buffer(window)
        @show mouse_button_buffer
        @show unsafe_load(mouse_button_buffer)

        empty!(lines)
        push!(lines, "previous frame number: $(i)")
        push!(lines, "time to draw previous frame (ms): $(delta_t * 1000)")
        push!(lines, "average time to draw previous $(sliding_window_size) frames (ms): $(average_delta_t_sliding_window * 1000)")
        push!(lines, "mouse_x: $(mouse_x)")
        push!(lines, "mouse_y: $(mouse_y)")
        push!(lines, "mouse_scroll_x: $(mouse_scroll_x)")
        push!(lines, "mouse_scroll_y: $(mouse_scroll_y)")
        push!(lines, "key_buffer: $(key_buffer)")
        push!(lines, "unsafe_load(key_buffer): $(unsafe_load(key_buffer))")
        push!(lines, "mouse_button_buffer: $(mouse_button_buffer)")
        push!(lines, "unsafe_load(mouse_button_buffer): $(unsafe_load(mouse_button_buffer))")

        SD.draw!(image, SD.Background(), background_color)
        draw_lines!(image, lines, text_color)

        frame_buffer = permutedims!(frame_buffer, image, (2, 1))

        state = mfb_update(window, frame_buffer)

        if state != STATE_OK
            break;
        end

        t2 = time()

        delta_t = t2 - t1

        average_delta_t = average_delta_t + (delta_t - average_delta_t) / (i + 1)

        if i < sliding_window_size
            DS.enqueue!(queue, delta_t)
            average_delta_t_sliding_window = average_delta_t
        else
            delta_t_oldest = DS.dequeue!(queue)
            average_delta_t_sliding_window = average_delta_t_sliding_window + (delta_t - delta_t_oldest) / sliding_window_size
            DS.enqueue!(queue, delta_t)
        end

        i = i + 1
    end
end

start(720, 1280, 0x00c0c0c0, 0x00000000, 100)
