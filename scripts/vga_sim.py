#!/usr/bin/env python3

#from https://github.com/ARC-Lab-UF/vga-simulator and I modified it a little I think honestly I dont remember

import argparse 
from io import TextIOWrapper
#this error is better than a traceback
try:
    from PIL import Image
except ImportError:
    print("Error: Run `pip install Pillow` and try again.")
    exit(1)


def time_conversion(value: int, unit_from: str, unit_to: str) -> float:
    """Convert a value between units of time"""
    seconds_to = {
        "fs": 1e-15,
        "ps": 1e-12,
        "ns": 1e-9,
        "us": 1e-6,
        "ms": 1e-3,
        "s": 1,
        "sec": 1,
        "min": 60,
        "hr": 3600,
    }
    return seconds_to[unit_from] / seconds_to[unit_to] * value


def map_binary_width(value: int, from_width: int, to_width=8) -> int:
    """Map a number to `new_width` bits (0.. 2 ** new_width - 1).
    Basically the same as a typical arduino-style `map()` function,
    except you can specify the width in bits here instead of min/max values. 
    """
    old_max_val = 2 ** from_width - 1
    new_max_val = 2 ** to_width - 1

    #mult by new_max_val first or integer division rounds to zero
    return new_max_val * value // old_max_val


def parse_line(line: str):
    """Parses a line from vga text file.
    Lines tend to look like this:
    `50 ns: 1 1 000 000 00`
    The function returns a tuple of each of these in appropriate data types (see below).
    """
    time, unit, hsync, vsync, r, g, b = line.replace(':', '').split()

    def safe_int_bin(bin_str: str) -> int:
        """Convert binary string to int, treating 'x' and 'z' as 0"""
        clean_str = bin_str.replace('x', '0').replace('z', '0').replace('X', '0').replace('Z', '0')
        return int(clean_str, 2)

    def safe_int(bin_str: str) -> int:
        """Convert binary/decimal string to int, treating 'x' and 'z' as 0"""
        clean_str = bin_str.replace('x', '0').replace('z', '0').replace('X', '0').replace('Z', '0')
        return int(clean_str, 10 if clean_str not in ['0', '1'] else 2)

    return (
        time_conversion(int(time), unit, "sec"),
        safe_int(hsync),
        safe_int(vsync),
        safe_int_bin(r) if len(r) == 8 else map_binary_width(safe_int_bin(r), len(r)),
        safe_int_bin(g) if len(g) == 8 else map_binary_width(safe_int_bin(g), len(g)),
        safe_int_bin(b) if len(b) == 8 else map_binary_width(safe_int_bin(b), len(b))
    )


def render_vga(file: TextIOWrapper, width: int, height: int, pixel_freq_MHz: float, hbp: int, vbp: int, max_frames: int) -> Image.Image | None:
    #timings from http://tinyvga.com/vga-timing/
    pixel_clk = 1e-6 / pixel_freq_MHz

    h_counter = 0
    v_counter = 0

    back_porch_x_count = 0
    back_porch_y_count = 0

    last_hsync = -1
    last_vsync = -1

    time_last_line = 0
    time_last_pixel = 0

    frame_count = 0

    vga_output = None

    print('[ ] VGA Simulator')
    print('[ ] Resolution:', width, '×', height)

    for vga_line in file:

        if 'U' in vga_line:
            print("Warning: Undefined values")
            continue

        time, hsync, vsync, red, green, blue = parse_line(vga_line)

        time_last_pixel += time - time_last_line

        if last_hsync == 0 and hsync == 1:
            h_counter = 0

            #move to the next row if past back porch
            if back_porch_y_count >= vbp:
                v_counter += 1

            #track distance after the vsync pulse
            back_porch_y_count += 1

            #reset the back porch count
            back_porch_x_count = 0

            #sync on sync pulse
            time_last_pixel = 0

        if last_vsync == 0 and vsync == 1:

            #show frame or create new frame
            if vga_output:
                vga_output.show("VGA Output")
            else:
                vga_output = Image.new('RGB', (width, height), (0, 0, 0))

            if frame_count < max_frames or max_frames == -1:
                print("[+] VSYNC: Decoding frame", frame_count)

                frame_count += 1
                h_counter = 0
                v_counter = 0

                #reset the back porch count
                back_porch_y_count = 0

                #sync on sync pulse
                time_last_pixel = 0

            else:
                print("[ ]", max_frames, "frames decoded")
                exit(0)

        if vga_output and vsync:

            #tolerance so the timing doesnt have to be bang on
            tolerance = 5e-9
            if time_last_pixel >= (pixel_clk - tolerance) and \
                time_last_pixel <= (pixel_clk + tolerance):
                #track distance after the hsync pulse
                back_porch_x_count += 1

                #start drawing once past the back porch
                if back_porch_x_count >= hbp and \
                    back_porch_y_count >= vbp:

                    if h_counter < width and v_counter < height:
                        vga_output.putpixel((h_counter, v_counter),
                                            (red, green, blue))

                #move to the next pixel if past back porch
                if back_porch_x_count >= hbp:
                    h_counter += 1

                time_last_pixel = 0

        last_hsync = hsync
        last_vsync = vsync
        time_last_line = time

    return vga_output

def main():
    parser = argparse.ArgumentParser("VGA Simulator", "Draws images from a corresponding HDL simulation file.", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("filename", help="Output file from your testbench", type=str)
    parser.add_argument("width", help="Screen width in pixels", type=int, nargs='?', default=640)
    parser.add_argument("height", help="Screen height in pixels", type=int, nargs='?', default=480)
    parser.add_argument("px_clk", help="Pixel clock frequency in MHz", type=float, nargs='?', default=25.175)
    parser.add_argument("hbp", help="Length of horizontal back porch in pixels", type=int, nargs='?', default=48)
    parser.add_argument("vbp", help="Length of vertical back porch in pixels", type=int, nargs='?', default=33)
    parser.add_argument("--max-frames", help="Maximum number of frames to draw. Default: Draw all frames", type=int, required=False, default=-1)

    args = parser.parse_args()
    
    #filename base from the input filename
    filename_base = args.filename.rsplit('.', 1)[0]
    
    with open(args.filename) as file:
        vga_output = render_vga(file, args.width, args.height, args.px_clk, args.hbp, args.vbp, args.max_frames)

    #save the last frame
    if vga_output is not None:
        output_filename = args.filename.replace('.txt', '.png')
        vga_output.save(output_filename)
        print(f"[+] Image saved to {output_filename}")

    print("Goodbye.")

if __name__ == "__main__":
    main()

