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

    logic stage1_enable;
    fixed_t hit_x_stage1, hit_y_stage1, hit_z_stage1;
    fixed_t normal_x_stage1, normal_y_stage1, normal_z_stage1;
    fixed_t ray_dir_x_stage1, ray_dir_y_stage1, ray_dir_z_stage1;
    logic is_sphere_stage1;
    fixed_t hit_reflectivity_stage1;
    logic [7:0] hit_r_stage1, hit_g_stage1, hit_b_stage1;

    intersection_stage #(
        .SPHERE_CENTER_X(SPHERE_CENTER_X),
        .SPHERE_CENTER_Y(SPHERE_CENTER_Y),
        .SPHERE_CENTER_Z(SPHERE_CENTER_Z),
        .SPHERE_RADIUS(SPHERE_RADIUS),
        .PLANE_Y(PLANE_Y),
        .H_RES(H_RES),
        .V_RES(V_RES)
    ) intersection_inst (
        .clk(clk),
        .rst(rst),
        .rt_h_count(rt_h_count),
        .rt_v_count(rt_v_count),
        .rt_enable(rt_enable),
        
        .out_enable(stage1_enable),
        .out_hit_x(hit_x_stage1),
        .out_hit_y(hit_y_stage1),
        .out_hit_z(hit_z_stage1),
        .out_normal_x(normal_x_stage1),
        .out_normal_y(normal_y_stage1),
        .out_normal_z(normal_z_stage1),
        .out_ray_dir_x(ray_dir_x_stage1),
        .out_ray_dir_y(ray_dir_y_stage1),
        .out_ray_dir_z(ray_dir_z_stage1),
        .out_is_sphere(is_sphere_stage1),
        .out_hit_reflectivity(hit_reflectivity_stage1),
        .out_hit_r(hit_r_stage1),
        .out_hit_g(hit_g_stage1),
        .out_hit_b(hit_b_stage1)
    );

    shading_stage #(
        .SPHERE_CENTER_X(SPHERE_CENTER_X),
        .SPHERE_CENTER_Y(SPHERE_CENTER_Y),
        .SPHERE_CENTER_Z(SPHERE_CENTER_Z),
        .SPHERE_RADIUS(SPHERE_RADIUS),
        .PLANE_Y(PLANE_Y)
    ) shading_inst (
        .clk(clk),
        .rst(rst),
        .in_enable(stage1_enable),
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
        .hit_reflectivity(hit_reflectivity_stage1),
        .hit_r(hit_r_stage1),
        .hit_g(hit_g_stage1),
        .hit_b(hit_b_stage1),

        .out_enable(),
        .pixel_data(pixel_data)
    );

endmodule
