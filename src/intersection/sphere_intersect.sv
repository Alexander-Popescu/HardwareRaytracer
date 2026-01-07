import fixed_point::*;

//plane intersect but for sphere, true false and distance.
module sphere_intersect (
    input  fixed_t ray_origin_x,
    input  fixed_t ray_origin_y,
    input  fixed_t ray_origin_z,
    input  fixed_t ray_dir_x,
    input  fixed_t ray_dir_y,
    input  fixed_t ray_dir_z,
    input  fixed_t sphere_center_x,
    input  fixed_t sphere_center_y,
    input  fixed_t sphere_center_z,
    input  fixed_t sphere_radius,
    output fixed_t t,
    output logic  hit
);

    //solve quadratic for intersections

    //origin - center
    fixed_t oc_x;
    fixed_t oc_y;
    fixed_t oc_z;

    assign oc_x = ray_origin_x - sphere_center_x;
    assign oc_y = ray_origin_y - sphere_center_y;
    assign oc_z = ray_origin_z - sphere_center_z;

    //a coefficient (dir . dir)
    logic signed [33:0] dir_dp;
    assign dir_dp = ray_dir_x * ray_dir_x + ray_dir_y * ray_dir_y + ray_dir_z * ray_dir_z;

    fixed_t a;
    assign a = dir_dp >>> 9;

    //b coefficient 2 * (oc . dir)
    logic signed [33:0] bt2;
    assign bt2 = (oc_x * ray_dir_x + oc_y * ray_dir_y + oc_z * ray_dir_z) << 1;
    fixed_t b;
    assign b = bt2 >>> 9;

    //c coefficient (oc . oc) - r^2
    logic signed [33:0] oc_dp;
    assign oc_dp = oc_x * oc_x + oc_y * oc_y + oc_z * oc_z;

    logic signed [33:0] r_sq;
    assign r_sq = sphere_radius * sphere_radius;

    fixed_t c;
    assign c = (oc_dp - r_sq) >>> 9;

    //discriminant for detecting hit
    logic signed [33:0] b_sq;
    logic signed [33:0] four_a_c;
    logic signed [33:0] discriminant;

    assign b_sq = b * b;
    assign four_a_c = 17'sd4 * a * c;
    assign discriminant = b_sq - four_a_c;

    logic signed [16:0] sqrt_disc;

    int_sqrt sqrt_inst (
        .in(discriminant),
        .out(sqrt_disc)
    );

    //solve with neg sqrt becuase its closer
    logic signed [33:0] numerator;
    assign numerator = (-b - sqrt_disc) * FIXED_ONE;

    always_comb begin
        if (discriminant >= 0 && a != 0) begin
            t = numerator / (17'sd2 * a);

            hit = t > 0 ? 1'b1 : 1'b0;
        end else begin
            //no hit
            t = FIXED_MAX;
            hit = 1'b0;
        end
    end
endmodule
