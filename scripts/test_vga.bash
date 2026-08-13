#!/bin/bash
set -e

mkdir -p build output

echo "Compiling simulation: "
iverilog -g2012 -o build/vga_sim \
    src/math/fixed_point.sv \
    src/math/int_sqrt.sv \
    src/math/div_pipe.sv \
    src/math/ray_generator.sv \
    src/intersection/sphere_intersect.sv \
    src/intersection/plane_intersect.sv \
    src/geometry/hit_point.sv \
    src/geometry/hit_selector.sv \
    src/shading/diffuse_shading.sv \
    src/shading/checkerboard_color.sv \
    src/shading/color_output.sv \
    src/shading/color_extractor.sv \
    src/shading/shadow_test.sv \
    src/reflection/reflection_shading.sv \
    src/display/intersection_stage.sv \
    src/display/shading_stage.sv \
    src/display/graphics_renderer.sv \
    src/display/vga_controller.sv \
    scripts/vga_tb.sv

echo "Running simulation: "
vvp build/vga_sim

echo "Building frame:"
python3 scripts/vga_sim.py output/vga_out.txt
