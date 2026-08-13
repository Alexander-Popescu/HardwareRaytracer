import fixed_point::*;

//pipeline stage 2 lights the hit point and produces the final pixel
//PIPE_LATENCY engines + 3 cycles of color math = PIPE_LATENCY+3 cycles
module shading_stage #(
    parameter SPHERE_CENTER_X = 0,
    parameter SPHERE_CENTER_Y = 0,
    parameter SPHERE_CENTER_Z = -128,
    parameter SPHERE_RADIUS = 288,
    parameter PLANE_Y = -768
)(
    input  logic clk,
    input  logic rst,
    input  logic in_enable,
    input  fixed_t hit_x,
    input  fixed_t hit_y,
    input  fixed_t hit_z,
    input  fixed_t normal_x,
    input  fixed_t normal_y,
    input  fixed_t normal_z,
    input  fixed_t ray_dir_x,
    input  fixed_t ray_dir_y,
    input  fixed_t ray_dir_z,
    input  logic is_sphere,
    input  fixed_t hit_reflectivity,
    input  logic [7:0] hit_r,
    input  logic [7:0] hit_g,
    input  logic [7:0] hit_b,

    output logic out_enable,
    output logic [31:0] pixel_data
);

    //shadow and reflection run side by side for PIPE_LATENCY cycles
    logic in_shadow;
    shadow_test shadow_inst (
        .clk(clk),
        .rst(rst),
        .hit_x(hit_x),
        .hit_y(hit_y),
        .hit_z(hit_z),
        .normal_x(normal_x),
        .normal_y(normal_y),
        .normal_z(normal_z),
        .sphere_center_x(SPHERE_CENTER_X),
        .sphere_center_y(SPHERE_CENTER_Y),
        .sphere_center_z(SPHERE_CENTER_Z),
        .sphere_radius(SPHERE_RADIUS),
        .in_shadow(in_shadow)
    );

    logic [7:0] reflect_r, reflect_g, reflect_b;
    reflection_shading reflection_inst (
        .clk(clk),
        .rst(rst),
        .hit_x(hit_x),
        .hit_y(hit_y),
        .hit_z(hit_z),
        .normal_x(normal_x),
        .normal_y(normal_y),
        .normal_z(normal_z),
        .ray_dir_x(ray_dir_x),
        .ray_dir_y(ray_dir_y),
        .ray_dir_z(ray_dir_z),
        .is_sphere(is_sphere),
        .PLANE_Y(PLANE_Y),
        .reflect_r(reflect_r),
        .reflect_g(reflect_g),
        .reflect_b(reflect_b)
    );

    //delay everything else to line up with shadow and reflection
    fixed_t normal_x_pipe [0:PIPE_LATENCY-1];
    fixed_t normal_y_pipe [0:PIPE_LATENCY-1];
    fixed_t normal_z_pipe [0:PIPE_LATENCY-1];
    logic is_sphere_pipe [0:PIPE_LATENCY-1];
    fixed_t hit_reflectivity_pipe [0:PIPE_LATENCY-1];
    logic [7:0] hit_r_pipe [0:PIPE_LATENCY-1];
    logic [7:0] hit_g_pipe [0:PIPE_LATENCY-1];
    logic [7:0] hit_b_pipe [0:PIPE_LATENCY-1];
    logic enable_pipe [0:PIPE_LATENCY-1];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < PIPE_LATENCY; i++) begin
                normal_x_pipe[i] <= 0; normal_y_pipe[i] <= 0; normal_z_pipe[i] <= 0;
                is_sphere_pipe[i] <= 0; hit_reflectivity_pipe[i] <= 0;
                hit_r_pipe[i] <= 0; hit_g_pipe[i] <= 0; hit_b_pipe[i] <= 0;
                enable_pipe[i] <= 0;
            end
        end else begin
            normal_x_pipe[0] <= normal_x; normal_y_pipe[0] <= normal_y; normal_z_pipe[0] <= normal_z;
            is_sphere_pipe[0] <= is_sphere; hit_reflectivity_pipe[0] <= hit_reflectivity;
            hit_r_pipe[0] <= hit_r; hit_g_pipe[0] <= hit_g; hit_b_pipe[0] <= hit_b;
            enable_pipe[0] <= in_enable;

            for (int i = 0; i < PIPE_LATENCY-1; i++) begin
                normal_x_pipe[i+1] <= normal_x_pipe[i]; normal_y_pipe[i+1] <= normal_y_pipe[i]; normal_z_pipe[i+1] <= normal_z_pipe[i];
                is_sphere_pipe[i+1] <= is_sphere_pipe[i]; hit_reflectivity_pipe[i+1] <= hit_reflectivity_pipe[i];
                hit_r_pipe[i+1] <= hit_r_pipe[i]; hit_g_pipe[i+1] <= hit_g_pipe[i]; hit_b_pipe[i+1] <= hit_b_pipe[i];
                enable_pipe[i+1] <= enable_pipe[i];
            end
        end
    end

    fixed_t diffuse_intensity_raw;
    diffuse_shading diffuse_inst (
        .normal_x(normal_x_pipe[PIPE_LATENCY-1]),
        .normal_y(normal_y_pipe[PIPE_LATENCY-1]),
        .normal_z(normal_z_pipe[PIPE_LATENCY-1]),
        .intensity(diffuse_intensity_raw)
    );

    fixed_t diffuse_intensity;
    assign diffuse_intensity = (in_shadow && !is_sphere_pipe[PIPE_LATENCY-1]) ? FIXED_AMBIENT : diffuse_intensity_raw;

    logic [7:0] red, green, blue;
    color_output color_inst (
        .clk(clk),
        .rst(rst),
        .base_r(hit_r_pipe[PIPE_LATENCY-1]),
        .base_g(hit_g_pipe[PIPE_LATENCY-1]),
        .base_b(hit_b_pipe[PIPE_LATENCY-1]),
        .reflect_r(reflect_r),
        .reflect_g(reflect_g),
        .reflect_b(reflect_b),
        .reflectivity(hit_reflectivity_pipe[PIPE_LATENCY-1]),
        .diffuse_intensity(diffuse_intensity),
        .red(red),
        .green(green),
        .blue(blue)
    );

    //delay enable to match the 2 cycles inside color_output
    logic enable_d1, enable_d2;
    always_ff @(posedge clk) begin
        if (rst) begin
            enable_d1 <= 0;
            enable_d2 <= 0;
            pixel_data <= 0;
            out_enable <= 0;
        end else begin
            enable_d1 <= enable_pipe[PIPE_LATENCY-1];
            enable_d2 <= enable_d1;
            pixel_data <= {red, green, blue, 8'd0};
            out_enable <= enable_d2;
        end
    end

endmodule
