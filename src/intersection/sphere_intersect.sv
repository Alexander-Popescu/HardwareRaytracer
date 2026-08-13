import fixed_point::*;

//hit flag and distance for ray vs sphere
module sphere_intersect (
    input  logic clk,
    input  logic rst,
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

    //entry register cuts the quadratic to one multiply level per cycle
    fixed_t a_r, b_r, c_r;
    always_ff @(posedge clk) begin
        if (rst) begin
            a_r <= 0; b_r <= 0; c_r <= 0;
        end else begin
            a_r <= a; b_r <= b; c_r <= c;
        end
    end

    //discriminant for detecting hit
    logic signed [33:0] b_sq;
    logic signed [33:0] four_a_c;
    logic signed [33:0] discriminant;

    assign b_sq = b_r * b_r;
    assign four_a_c = 17'sd4 * a_r * c_r;
    assign discriminant = b_sq - four_a_c;

    logic signed [16:0] sqrt_disc;

    int_sqrt sqrt_inst (
        .clk(clk),
        .rst(rst),
        .in(discriminant),
        .out(sqrt_disc)
    );

    //reciprocal 2^22/2a runs beside the sqrt because ray dirs arent normalized
    logic [16:0] recip_mag;
    logic recip_neg, recip_ovf;
    div_pipe recip_inst (
        .clk(clk),
        .rst(rst),
        .dividend(34'sd4194304),
        .divisor(fixed_t'(a_r <<< 1)),
        .q_mag(recip_mag),
        .q_neg(recip_neg),
        .ovf(recip_ovf)
    );

    //delay b and the valid flags through the 18 cycle core
    fixed_t b_pipe [0:17];
    logic disc_valid_pipe [0:17];
    logic a_valid_pipe [0:17];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 18; i++) begin
                b_pipe[i] <= 0;
                disc_valid_pipe[i] <= 0;
                a_valid_pipe[i] <= 0;
            end
        end else begin
            b_pipe[0] <= b_r;
            disc_valid_pipe[0] <= (discriminant >= 0);
            a_valid_pipe[0] <= (a_r != 0);
            for (int i = 0; i < 17; i++) begin
                b_pipe[i+1] <= b_pipe[i];
                disc_valid_pipe[i+1] <= disc_valid_pipe[i];
                a_valid_pipe[i+1] <= a_valid_pipe[i];
            end
        end
    end

    //numerator lands with the sqrt and the reciprocal multiply waits a cycle
    logic signed [17:0] num_r;
    logic [16:0] recip_r;
    logic valid_r;

    always_ff @(posedge clk) begin
        if (rst) begin
            num_r <= 0; recip_r <= 0; valid_r <= 0;
        end else begin
            num_r <= -18'(b_pipe[17]) - 18'(sqrt_disc);
            recip_r <= recip_mag;
            valid_r <= disc_valid_pipe[17] && a_valid_pipe[17] && !recip_ovf && !recip_neg;
        end
    end

    //t = num * recip >> 13 back in fixed point
    logic signed [33:0] t_full_r;
    logic valid_r2;

    always_ff @(posedge clk) begin
        if (rst) begin
            t_full_r <= 0; valid_r2 <= 0;
        end else begin
            t_full_r <= (num_r * $signed({1'b0, recip_r})) >>> 13;
            valid_r2 <= valid_r;
        end
    end

    always_comb begin
        if (valid_r2 && t_full_r > 0) begin
            t = t_full_r[16:0];
            hit = 1'b1;
        end else begin
            //no hit
            t = FIXED_MAX;
            hit = 1'b0;
        end
    end

endmodule
