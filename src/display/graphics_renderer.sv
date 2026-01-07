import fixed_point::*;

module graphics_renderer #(
    parameter H_RES = 640,
    parameter V_RES = 480,
    parameter SPHERE_CENTER_X = 0,
    parameter SPHERE_CENTER_Y = 0,
    parameter SPHERE_CENTER_Z = -128,
    parameter SPHERE_RADIUS = 288,
    parameter PLANE_Y = -768
) (
    input logic clk,
    input logic rst,
    input logic [9:0] rt_h_count,
    input logic [9:0] rt_v_count,
    input logic rt_enable,
    output logic [31:0] pixel_data
);

    localparam SPHERE_COLOR_R = 8'd200;
    localparam SPHERE_COLOR_G = 8'd0;
    localparam SPHERE_COLOR_B = 8'd0;

    localparam fixed_t SPHERE_REFLECTIVITY = 17'sd256;
    localparam fixed_t PLANE_REFLECTIVITY = 17'sd100;

    localparam fixed_t FIXED_AMBIENT = 17'sd50;

    //intersection stage registers
    fixed_t ray_origin_x, ray_origin_y, ray_origin_z;
    fixed_t ray_dir_x, ray_dir_y, ray_dir_z;

    fixed_t sphere_t, plane_t;
    logic sphere_hit, plane_hit;

    fixed_t t;
    logic hit_sphere;

    fixed_t hit_x, hit_y, hit_z;

    logic [7:0] checker_r, checker_g, checker_b;
    logic in_shadow;

    //outputs
    fixed_t ray_origin_x_stage1, ray_origin_y_stage1, ray_origin_z_stage1;
    fixed_t ray_dir_x_stage1, ray_dir_y_stage1, ray_dir_z_stage1;

    fixed_t hit_x_stage1, hit_y_stage1, hit_z_stage1;
    fixed_t normal_x_stage1, normal_y_stage1, normal_z_stage1;
    logic is_sphere_stage1;
    fixed_t hit_reflectivity_stage1;
    logic [7:0] hit_r_stage1, hit_g_stage1, hit_b_stage1;
    fixed_t diffuse_intensity_stage1;
    logic in_shadow_stage1;

    //shading stage
    logic [7:0] reflect_r, reflect_g, reflect_b;
    fixed_t diffuse_intensity_raw;
    logic [7:0] red, green, blue;

    ray_generator #(
        .H_RES(H_RES),
        .V_RES(V_RES)
    ) ray_dir_inst (
        .h_count(rt_h_count),
        .v_count(rt_v_count),
        .dir_x(ray_dir_x),
        .dir_y(ray_dir_y),
        .dir_z(ray_dir_z)
    );

    assign ray_origin_x = 17'sd0;
    assign ray_origin_y = 17'sd0;
    assign ray_origin_z = 17'sd1024;

    sphere_intersect sphere_inst (
        .ray_origin_x(ray_origin_x),
        .ray_origin_y(ray_origin_y),
        .ray_origin_z(ray_origin_z),
        .ray_dir_x(ray_dir_x),
        .ray_dir_y(ray_dir_y),
        .ray_dir_z(ray_dir_z),
        .sphere_center_x(SPHERE_CENTER_X),
        .sphere_center_y(SPHERE_CENTER_Y),
        .sphere_center_z(SPHERE_CENTER_Z),
        .sphere_radius(SPHERE_RADIUS),
        .t(sphere_t),
        .hit(sphere_hit)
    );

    plane_intersect plane_inst (
        .ray_origin_y(ray_origin_y),
        .ray_dir_y(ray_dir_y),
        .plane_y(PLANE_Y),
        .t(plane_t),
        .hit(plane_hit)
    );

    hit_selector hit_sel_inst (
        .sphere_t(sphere_t),
        .plane_t(plane_t),
        .sphere_hit(sphere_hit),
        .plane_hit(plane_hit),
        .t(t),
        .hit_sphere(hit_sphere)
    );

    hit_point hit_pt_inst (
        .origin_x(ray_origin_x),
        .origin_y(ray_origin_y),
        .origin_z(ray_origin_z),
        .dir_x(ray_dir_x),
        .dir_y(ray_dir_y),
        .dir_z(ray_dir_z),
        .t(t),
        .point_x(hit_x),
        .point_y(hit_y),
        .point_z(hit_z)
    );

    checkerboard_color checker_inst (
        .hit_x(hit_x),
        .hit_z(hit_z),
        .r(checker_r),
        .g(checker_g),
        .b(checker_b)
    );

    shadow_test shadow_inst (
        .hit_x(hit_x),
        .hit_y(hit_y),
        .hit_z(hit_z),
        .normal_x(17'sd0),
        .normal_y(17'sd256),
        .normal_z(17'sd0),
        .sphere_center_x(SPHERE_CENTER_X),
        .sphere_center_y(SPHERE_CENTER_Y),
        .sphere_center_z(SPHERE_CENTER_Z),
        .sphere_radius(SPHERE_RADIUS),
        .in_shadow(in_shadow)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            normal_x_stage1 <= 0;
            normal_y_stage1 <= 0;
            normal_z_stage1 <= 0;
            is_sphere_stage1 <= 0;
            hit_reflectivity_stage1 <= 0;
            hit_r_stage1 <= 0;
            hit_g_stage1 <= 0;
            hit_b_stage1 <= 0;
            in_shadow_stage1 <= 0;
            ray_origin_x_stage1 <= 0;
            ray_origin_y_stage1 <= 0;
            ray_origin_z_stage1 <= 0;
            ray_dir_x_stage1 <= 0;
            ray_dir_y_stage1 <= 0;
            ray_dir_z_stage1 <= 0;
        end else if (rt_enable) begin
            //move registers
            in_shadow_stage1 <= in_shadow;
            hit_x_stage1 <= hit_x;
            hit_y_stage1 <= hit_y;
            hit_z_stage1 <= hit_z;

            ray_origin_x_stage1 <= ray_origin_x;
            ray_origin_y_stage1 <= ray_origin_y;
            ray_origin_z_stage1 <= ray_origin_z;
            ray_dir_x_stage1 <= ray_dir_x;
            ray_dir_y_stage1 <= ray_dir_y;
            ray_dir_z_stage1 <= ray_dir_z;

            if (hit_sphere) begin
                normal_x_stage1 <= ((hit_x - SPHERE_CENTER_X) * FIXED_ONE) / SPHERE_RADIUS;
                normal_y_stage1 <= ((hit_y - SPHERE_CENTER_Y) * FIXED_ONE) / SPHERE_RADIUS;
                normal_z_stage1 <= ((hit_z - SPHERE_CENTER_Z) * FIXED_ONE) / SPHERE_RADIUS;
                is_sphere_stage1 <= 1;
                hit_reflectivity_stage1 <= SPHERE_REFLECTIVITY;
                hit_r_stage1 <= SPHERE_COLOR_R;
                hit_g_stage1 <= SPHERE_COLOR_G;
                hit_b_stage1 <= SPHERE_COLOR_B;
            end else if (plane_hit) begin
                normal_x_stage1 <= 17'sd0;
                normal_y_stage1 <= 17'sd256;
                normal_z_stage1 <= 17'sd0;
                is_sphere_stage1 <= 0;
                hit_reflectivity_stage1 <= PLANE_REFLECTIVITY;
                hit_r_stage1 <= checker_r;
                hit_g_stage1 <= checker_g;
                hit_b_stage1 <= checker_b;
            end else begin
                normal_x_stage1 <= 0;
                normal_y_stage1 <= 0;
                normal_z_stage1 <= 0;
                is_sphere_stage1 <= 0;
                hit_reflectivity_stage1 <= 0;
                hit_r_stage1 <= 0;
                hit_g_stage1 <= 0;
                hit_b_stage1 <= 0;
            end
        end
    end

    diffuse_shading diffuse_inst (
        .normal_x(normal_x_stage1),
        .normal_y(normal_y_stage1),
        .normal_z(normal_z_stage1),
        .intensity(diffuse_intensity_raw)
    );

    assign diffuse_intensity_stage1 = (in_shadow_stage1 && !is_sphere_stage1) ? FIXED_AMBIENT : diffuse_intensity_raw;

    reflection_shading reflection_inst (
        .hit_x(hit_x_stage1),
        .hit_y(hit_y_stage1),
        .hit_z(hit_z_stage1),
        .normal_x(normal_x_stage1),
        .normal_y(normal_y_stage1),
        .normal_z(normal_z_stage1),
        .ray_dir_x(ray_dir_x_stage1),
        .ray_dir_y(ray_dir_y_stage1),
        .ray_dir_z(ray_dir_z_stage1),
        .is_sphere(is_sphere_stage1),
        .PLANE_Y(PLANE_Y),
        .reflect_r(reflect_r),
        .reflect_g(reflect_g),
        .reflect_b(reflect_b)
    );

    color_output color_inst (
        .base_r(hit_r_stage1),
        .base_g(hit_g_stage1),
        .base_b(hit_b_stage1),
        .reflect_r(reflect_r),
        .reflect_g(reflect_g),
        .reflect_b(reflect_b),
        .reflectivity(hit_reflectivity_stage1),
        .diffuse_intensity(diffuse_intensity_stage1),
        .red(red),
        .green(green),
        .blue(blue)
    );

    assign pixel_data = {red, green, blue, 8'd0};

endmodule
