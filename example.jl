import MiniFB as MFB
import DataStructures as DS
import SimpleDraw as SD

function draw_lines!(image, lines, color)
    font = SD.TERMINUS_32_16
    height_font = 32

    for (i, text) in enumerate(lines)
        position = SD.Point(1 + (i - 1) * height_font, 1)
        SD.draw!(image, SD.TextLine(position, text, font), color)
    end

    return nothing
end

is_pressed(window, button::MFB.mfb_key) = !iszero(unsafe_load(MFB.mfb_get_key_buffer(window), button + 1))
is_pressed(window, button::MFB.mfb_mouse_button) = !iszero(unsafe_load(MFB.mfb_get_mouse_button_buffer(window), button + 1))

function start()
    height_image = 720
    width_image = 1280
    background_color = 0x00c0c0c0
    text_color = 0x00000000
    sliding_window_size = 100

    image = zeros(UInt32, height_image, width_image)

    frame_buffer = permutedims(image)

    window = MFB.mfb_open("Example", width_image, height_image)

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

    while MFB.mfb_wait_sync(window)
        t1 = time()

        mouse_x = MFB.mfb_get_mouse_x(window)
        mouse_y = MFB.mfb_get_mouse_y(window)
        mouse_scroll_x = MFB.mfb_get_mouse_scroll_x(window)
        mouse_scroll_y = MFB.mfb_get_mouse_scroll_y(window)
        empty!(lines)
        push!(lines, "previous frame number: $(i)")
        push!(lines, "time to draw previous frame (ms): $(delta_t * 1000)")
        push!(lines, "average time to draw previous $(sliding_window_size) frames (ms): $(average_delta_t_sliding_window * 1000)")
        push!(lines, "mouse_x: $(mouse_x)")
        push!(lines, "mouse_y: $(mouse_y)")
        push!(lines, "mouse_scroll_x: $(mouse_scroll_x)")
        push!(lines, "mouse_scroll_y: $(mouse_scroll_y)")

        push!(lines, "is_pressed(window, MFB.MOUSE_LEFT): $(is_pressed(window, MFB.MOUSE_LEFT))")
        push!(lines, "is_pressed(window, MFB.MOUSE_RIGHT): $(is_pressed(window, MFB.MOUSE_RIGHT))")
        push!(lines, "is_pressed(window, MFB.MOUSE_MIDDLE): $(is_pressed(window, MFB.MOUSE_MIDDLE))")

        push!(lines, "is_pressed(window, MFB.KB_KEY_A): $(is_pressed(window, MFB.KB_KEY_A))")
        push!(lines, "is_pressed(window, MFB.KB_KEY_B): $(is_pressed(window, MFB.KB_KEY_B))")
        push!(lines, "is_pressed(window, MFB.KB_KEY_C): $(is_pressed(window, MFB.KB_KEY_C))")
        push!(lines, "is_pressed(window, MFB.KB_KEY_0): $(is_pressed(window, MFB.KB_KEY_0))")
        push!(lines, "is_pressed(window, MFB.KB_KEY_1): $(is_pressed(window, MFB.KB_KEY_1))")
        push!(lines, "is_pressed(window, MFB.KB_KEY_2): $(is_pressed(window, MFB.KB_KEY_2))")

        SD.draw!(image, SD.Background(), background_color)
        draw_lines!(image, lines, text_color)

        frame_buffer = permutedims!(frame_buffer, image, (2, 1))

        state = MFB.mfb_update(window, frame_buffer)

        if state != MFB.STATE_OK
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

start()
