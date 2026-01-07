import fixed_point::*;

//calculates color for reflected rays
module reflection_shading (
    input fixed_t hit_x,
    input fixed_t hit_y,
    input fixed_t hit_z,
    input fixed_t normal_x,
    input fixed_t normal_y,
    input fixed_t normal_z,
    input fixed_t ray_dir_x,
    input fixed_t ray_dir_y,
    input fixed_t ray_dir_z,
    input logic is_sphere,
    input fixed_t PLANE_Y,
    output logic [7:0] reflect_r,
    output logic [7:0] reflect_g,
    output logic [7:0] reflect_b
);

    fixed_t reflect_dir_x, reflect_dir_y, reflect_dir_z;

    reflect_calc reflect_calc (
        .ray_dir_x(ray_dir_x),
        .ray_dir_y(ray_dir_y),
        .ray_dir_z(ray_dir_z),
        .normal_x(normal_x),
        .normal_y(normal_y),
        .normal_z(normal_z),
        .reflect_dir_x(reflect_dir_x),
        .reflect_dir_y(reflect_dir_y),
        .reflect_dir_z(reflect_dir_z)
    );

    fixed_t ref_plane_t;
    logic ref_plane_hit;

    plane_intersect ref_plane (
        .ray_origin_y(hit_y + (normal_y >>> 4)),
        .ray_dir_y(reflect_dir_y),
        .plane_y(PLANE_Y),
        .t(ref_plane_t),
        .hit(ref_plane_hit)
    );

    //reflection as normal ray
    fixed_t ref_hit_x, ref_hit_z;

    assign ref_hit_x = hit_x + (normal_x >>> 4) + ((34'(reflect_dir_x) * ref_plane_t) >>> 9);
    assign ref_hit_z = hit_z + (normal_z >>> 4) + ((34'(reflect_dir_z) * ref_plane_t) >>> 9);

    //calcualte color same as ray from camera, it will get blended later
    logic [7:0] r_temp, g_temp, b_temp;
    checkerboard_color color_inst (
        .hit_x(ref_hit_x),
        .hit_z(ref_hit_z),
        .r(r_temp),
        .g(g_temp),
        .b(b_temp)
    );

    always_comb begin
        if (ref_plane_hit && is_sphere) begin
            reflect_r = r_temp;
            reflect_g = g_temp;
            reflect_b = b_temp;
        end else begin
            //blend nothing
            reflect_r = 8'd0;
            reflect_g = 8'd0;
            reflect_b = 8'd0;
        end
    end

endmodule
