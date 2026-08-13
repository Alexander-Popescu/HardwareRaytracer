import fixed_point::*;

//pipeline stage 1 casts a ray per pixel and finds what it hits
//entry reg + PIPE_LATENCY intersectors + hit reg + output reg = PIPE_LATENCY+3 cycles
module intersection_stage #(
    parameter SPHERE_CENTER_X = 0,
    parameter SPHERE_CENTER_Y = 0,
    parameter SPHERE_CENTER_Z = -128,
    parameter SPHERE_RADIUS = 288,
    parameter PLANE_Y = -768,
    parameter H_RES = 640,
    parameter V_RES = 480
)(
    input  logic clk,
    input  logic rst,
    input  logic [9:0] rt_h_count,
    input  logic [9:0] rt_v_count,
    input  logic rt_enable,

    output logic out_enable,
    output fixed_t out_hit_x,
    output fixed_t out_hit_y,
    output fixed_t out_hit_z,
    output fixed_t out_normal_x,
    output fixed_t out_normal_y,
    output fixed_t out_normal_z,
    output fixed_t out_ray_dir_x,
    output fixed_t out_ray_dir_y,
    output fixed_t out_ray_dir_z,
    output logic out_is_sphere,
    output fixed_t out_hit_reflectivity,
    output logic [7:0] out_hit_r,
    output logic [7:0] out_hit_g,
    output logic [7:0] out_hit_b
);
    localparam fixed_t RAY_ORIGIN_X = 17'sd0;
    localparam fixed_t RAY_ORIGIN_Y = 17'sd0;
    localparam fixed_t RAY_ORIGIN_Z = 17'sd1024;

    fixed_t ray_dir_x, ray_dir_y, ray_dir_z;
    ray_generator #(.H_RES(H_RES), .V_RES(V_RES)) ray_dir_inst (
        .h_count(rt_h_count),
        .v_count(rt_v_count),
        .dir_x(ray_dir_x),
        .dir_y(ray_dir_y),
        .dir_z(ray_dir_z)
    );

    //entry register cuts between the ray_generator multiply and the intersector multiplies
    fixed_t rd_x_r, rd_y_r, rd_z_r;
    logic enable_r;
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_x_r <= 0; rd_y_r <= 0; rd_z_r <= 0; enable_r <= 0;
        end else begin
            rd_x_r <= ray_dir_x; rd_y_r <= ray_dir_y; rd_z_r <= ray_dir_z;
            enable_r <= rt_enable;
        end
    end

    //both intersectors take PIPE_LATENCY cycles so results arrive together
    fixed_t sphere_t;
    logic sphere_hit;
    sphere_intersect sphere_inst (
        .clk(clk),
        .rst(rst),
        .ray_origin_x(RAY_ORIGIN_X),
        .ray_origin_y(RAY_ORIGIN_Y),
        .ray_origin_z(RAY_ORIGIN_Z),
        .ray_dir_x(rd_x_r),
        .ray_dir_y(rd_y_r),
        .ray_dir_z(rd_z_r),
        .sphere_center_x(SPHERE_CENTER_X),
        .sphere_center_y(SPHERE_CENTER_Y),
        .sphere_center_z(SPHERE_CENTER_Z),
        .sphere_radius(SPHERE_RADIUS),
        .t(sphere_t),
        .hit(sphere_hit)
    );

    fixed_t plane_t;
    logic plane_hit;
    plane_intersect plane_inst (
        .clk(clk),
        .rst(rst),
        .ray_origin_y(RAY_ORIGIN_Y),
        .ray_dir_y(rd_y_r),
        .plane_y(PLANE_Y),
        .t(plane_t),
        .hit(plane_hit)
    );

    //delay the ray so it lines up with the intersect results
    fixed_t ray_dir_x_pipe [0:PIPE_LATENCY-1];
    fixed_t ray_dir_y_pipe [0:PIPE_LATENCY-1];
    fixed_t ray_dir_z_pipe [0:PIPE_LATENCY-1];
    logic enable_pipe [0:PIPE_LATENCY-1];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < PIPE_LATENCY; i++) begin
                ray_dir_x_pipe[i] <= 0;
                ray_dir_y_pipe[i] <= 0;
                ray_dir_z_pipe[i] <= 0;
                enable_pipe[i] <= 0;
            end
        end else begin
            ray_dir_x_pipe[0] <= rd_x_r;
            ray_dir_y_pipe[0] <= rd_y_r;
            ray_dir_z_pipe[0] <= rd_z_r;
            enable_pipe[0] <= enable_r;

            for (int i = 0; i < PIPE_LATENCY-1; i++) begin
                ray_dir_x_pipe[i+1] <= ray_dir_x_pipe[i];
                ray_dir_y_pipe[i+1] <= ray_dir_y_pipe[i];
                ray_dir_z_pipe[i+1] <= ray_dir_z_pipe[i];
                enable_pipe[i+1] <= enable_pipe[i];
            end
        end
    end

    fixed_t t;
    logic hit_sphere;
    hit_selector hit_sel_inst (
        .sphere_t(sphere_t),
        .plane_t(plane_t),
        .sphere_hit(sphere_hit),
        .plane_hit(plane_hit),
        .t(t),
        .hit_sphere(hit_sphere)
    );

    fixed_t hit_x, hit_y, hit_z;
    hit_point hit_pt_inst (
        .origin_x(RAY_ORIGIN_X),
        .origin_y(RAY_ORIGIN_Y),
        .origin_z(RAY_ORIGIN_Z),
        .dir_x(ray_dir_x_pipe[PIPE_LATENCY-1]),
        .dir_y(ray_dir_y_pipe[PIPE_LATENCY-1]),
        .dir_z(ray_dir_z_pipe[PIPE_LATENCY-1]),
        .t(t),
        .point_x(hit_x),
        .point_y(hit_y),
        .point_z(hit_z)
    );

    //hit register cuts between the hit_point multiply and the normal multiply
    fixed_t hit_x_r, hit_y_r, hit_z_r;
    fixed_t rd_x_b, rd_y_b, rd_z_b;
    logic hit_sphere_r, plane_hit_r, enable_b;

    always_ff @(posedge clk) begin
        if (rst) begin
            hit_x_r <= 0; hit_y_r <= 0; hit_z_r <= 0;
            rd_x_b <= 0; rd_y_b <= 0; rd_z_b <= 0;
            hit_sphere_r <= 0; plane_hit_r <= 0; enable_b <= 0;
        end else begin
            hit_x_r <= hit_x; hit_y_r <= hit_y; hit_z_r <= hit_z;
            rd_x_b <= ray_dir_x_pipe[PIPE_LATENCY-1];
            rd_y_b <= ray_dir_y_pipe[PIPE_LATENCY-1];
            rd_z_b <= ray_dir_z_pipe[PIPE_LATENCY-1];
            hit_sphere_r <= hit_sphere; plane_hit_r <= plane_hit;
            enable_b <= enable_pipe[PIPE_LATENCY-1];
        end
    end

    logic [7:0] checker_r, checker_g, checker_b;
    checkerboard_color checker_inst (
        .hit_x(hit_x_r),
        .hit_z(hit_z_r),
        .r(checker_r),
        .g(checker_g),
        .b(checker_b)
    );

    localparam SPHERE_COLOR_R = 8'd200;
    localparam SPHERE_COLOR_G = 8'd0;
    localparam SPHERE_COLOR_B = 8'd0;
    localparam fixed_t SPHERE_REFLECTIVITY = 17'sd256;
    localparam fixed_t PLANE_REFLECTIVITY = 17'sd100;
    localparam logic signed [33:0] INV_SPHERE_RADIUS_34 = (34'sd1 << 18) / SPHERE_RADIUS;
    localparam fixed_t INV_SPHERE_RADIUS = INV_SPHERE_RADIUS_34[16:0];

    //34 bit so the products dont wrap before the shift
    logic signed [33:0] normal_x_full, normal_y_full, normal_z_full;
    assign normal_x_full = ((hit_x_r - SPHERE_CENTER_X) * INV_SPHERE_RADIUS) >>> 9;
    assign normal_y_full = ((hit_y_r - SPHERE_CENTER_Y) * INV_SPHERE_RADIUS) >>> 9;
    assign normal_z_full = ((hit_z_r - SPHERE_CENTER_Z) * INV_SPHERE_RADIUS) >>> 9;

    always_ff @(posedge clk) begin
        if (rst) begin
            out_enable <= 0;
            out_hit_x <= 0; out_hit_y <= 0; out_hit_z <= 0;
            out_normal_x <= 0; out_normal_y <= 0; out_normal_z <= 0;
            out_ray_dir_x <= 0; out_ray_dir_y <= 0; out_ray_dir_z <= 0;
            out_is_sphere <= 0; out_hit_reflectivity <= 0;
            out_hit_r <= 0; out_hit_g <= 0; out_hit_b <= 0;
        end else begin
            out_enable <= enable_b;
            out_hit_x <= hit_x_r; out_hit_y <= hit_y_r; out_hit_z <= hit_z_r;
            out_ray_dir_x <= rd_x_b;
            out_ray_dir_y <= rd_y_b;
            out_ray_dir_z <= rd_z_b;

            if (hit_sphere_r) begin
                out_normal_x <= normal_x_full[16:0];
                out_normal_y <= normal_y_full[16:0];
                out_normal_z <= normal_z_full[16:0];
                out_is_sphere <= 1;
                out_hit_reflectivity <= SPHERE_REFLECTIVITY;
                out_hit_r <= SPHERE_COLOR_R; out_hit_g <= SPHERE_COLOR_G; out_hit_b <= SPHERE_COLOR_B;
            end else if (plane_hit_r) begin
                out_normal_x <= 17'sd0; out_normal_y <= 17'sd256; out_normal_z <= 17'sd0;
                out_is_sphere <= 0;
                out_hit_reflectivity <= PLANE_REFLECTIVITY;
                out_hit_r <= checker_r; out_hit_g <= checker_g; out_hit_b <= checker_b;
            end else begin
                out_normal_x <= 0; out_normal_y <= 0; out_normal_z <= 0;
                out_is_sphere <= 0; out_hit_reflectivity <= 0;
                out_hit_r <= 0; out_hit_g <= 0; out_hit_b <= 0;
            end
        end
    end
endmodule
