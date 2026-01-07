import fixed_point::*;

//tests if hit point is obscured from the light, we can just walk a ray from hit to lightsource
module shadow_test (
    input  fixed_t hit_x,
    input  fixed_t hit_y,
    input  fixed_t hit_z,
    input  fixed_t normal_x,
    input  fixed_t normal_y,
    input  fixed_t normal_z,
    input  fixed_t sphere_center_x,
    input  fixed_t sphere_center_y,
    input  fixed_t sphere_center_z,
    input  fixed_t sphere_radius,
    output logic   in_shadow
);

    //TODO match this with the one in diffuse but just make sure they are the same probably should define in graphics actually
    localparam fixed_t LIGHT_DIR_X = 17'sd200;
    localparam fixed_t LIGHT_DIR_Y = 17'sd325;
    localparam fixed_t LIGHT_DIR_Z = 17'sd200;

    fixed_t shadow_origin_x;
    fixed_t shadow_origin_y;
    fixed_t shadow_origin_z;

    //self intersection fix, whoops
    assign shadow_origin_x = hit_x + (normal_x >>> 4);
    assign shadow_origin_y = hit_y + (normal_y >>> 4);
    assign shadow_origin_z = hit_z + (normal_z >>> 4);

    fixed_t shadow_t;
    logic shadow_hit;

    sphere_intersect shadow_sphere_inst (
        .ray_origin_x(shadow_origin_x),
        .ray_origin_y(shadow_origin_y),
        .ray_origin_z(shadow_origin_z),
        .ray_dir_x(LIGHT_DIR_X),
        .ray_dir_y(LIGHT_DIR_Y),
        .ray_dir_z(LIGHT_DIR_Z),
        .sphere_center_x(sphere_center_x),
        .sphere_center_y(sphere_center_y),
        .sphere_center_z(sphere_center_z),
        .sphere_radius(sphere_radius),
        .t(shadow_t),
        .hit(shadow_hit)
    );

    //purge far off shadows from artifacting
    logic signed [33:0] hit_dist;
    assign hit_dist = ((hit_x - sphere_center_x) * (hit_x - sphere_center_x)) + ((hit_z - sphere_center_z) * (hit_z - sphere_center_z));

    always_comb begin
        if (shadow_hit) begin
            if (hit_dist < sphere_radius * sphere_radius * 17'sd24) begin
                in_shadow = 1'b1;
            end else begin
                in_shadow = 1'b0;
            end
        end else begin
            in_shadow = 1'b0;
        end
    end

endmodule
