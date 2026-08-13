import fixed_point::*;

//reflect R = I - 2*(N.I)*N and bounce to the floor for color
//entry register + 18 cycle divider + 2 lockstep registers = PIPE_LATENCY cycles
module reflection_shading (
    input logic clk,
    input logic rst,
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

    //dot product N.I is one multiply level
    logic signed [33:0] ni_dp;
    assign ni_dp = ((normal_x * ray_dir_x) >>> 9) + ((normal_y * ray_dir_y) >>> 9) + ((normal_z * ray_dir_z) >>> 9);

    //bounce origin nudged off the surface to avoid self intersection
    fixed_t ref_origin_x, ref_origin_y, ref_origin_z;
    assign ref_origin_x = hit_x + (normal_x >>> 4);
    assign ref_origin_y = hit_y + (normal_y >>> 4);
    assign ref_origin_z = hit_z + (normal_z >>> 4);

    //entry register so the bounce direction multiply waits a cycle
    //|N.I| stays well under 2^16
    fixed_t ni_r;
    fixed_t nx_r, ny_r, nz_r;
    fixed_t rdx_r, rdy_r, rdz_r;
    fixed_t ox_r, oy_r, oz_r;
    logic is_sphere_r;

    always_ff @(posedge clk) begin
        if (rst) begin
            ni_r <= 0; nx_r <= 0; ny_r <= 0; nz_r <= 0;
            rdx_r <= 0; rdy_r <= 0; rdz_r <= 0;
            ox_r <= 0; oy_r <= 0; oz_r <= 0;
            is_sphere_r <= 0;
        end else begin
            ni_r <= ni_dp[16:0];
            nx_r <= normal_x; ny_r <= normal_y; nz_r <= normal_z;
            rdx_r <= ray_dir_x; rdy_r <= ray_dir_y; rdz_r <= ray_dir_z;
            ox_r <= ref_origin_x; oy_r <= ref_origin_y; oz_r <= ref_origin_z;
            is_sphere_r <= is_sphere;
        end
    end

    //R = I - 2*(N.I)*N at 34 bit so nothing wraps
    logic signed [33:0] refl_x_full, refl_y_full, refl_z_full;
    assign refl_x_full = rdx_r - ((ni_r * 17'sd2 * nx_r) >>> 9);
    assign refl_y_full = rdy_r - ((ni_r * 17'sd2 * ny_r) >>> 9);
    assign refl_z_full = rdz_r - ((ni_r * 17'sd2 * nz_r) >>> 9);

    fixed_t reflect_dir_x, reflect_dir_y, reflect_dir_z;
    assign reflect_dir_x = refl_x_full[16:0];
    assign reflect_dir_y = refl_y_full[16:0];
    assign reflect_dir_z = refl_z_full[16:0];

    //where does the bounce meet the floor
    logic signed [33:0] y_distance;
    assign y_distance = (PLANE_Y - oy_r) * FIXED_ONE;

    logic [16:0] q_mag;
    logic q_neg, ovf;
    div_pipe div_inst (
        .clk(clk),
        .rst(rst),
        .dividend(y_distance),
        .divisor(reflect_dir_y),
        .q_mag(q_mag),
        .q_neg(q_neg),
        .ovf(ovf)
    );

    //two result registers keep the bounce in step with sphere_intersect's divide by 2a
    logic [16:0] q_d1, q_d2;
    logic neg_d1, neg_d2, ovf_d1, ovf_d2;
    always_ff @(posedge clk) begin
        if (rst) begin
            q_d1 <= 0; q_d2 <= 0;
            neg_d1 <= 0; neg_d2 <= 0; ovf_d1 <= 0; ovf_d2 <= 0;
        end else begin
            q_d1 <= q_mag; neg_d1 <= q_neg; ovf_d1 <= ovf;
            q_d2 <= q_d1; neg_d2 <= neg_d1; ovf_d2 <= ovf_d1;
        end
    end

    //same hit rule as plane_intersect
    fixed_t ref_plane_t;
    logic ref_plane_hit;
    always_comb begin
        if (!ovf_d2 && !neg_d2 && !q_d2[16] && q_d2 != 0) begin
            ref_plane_t = q_d2;
            ref_plane_hit = 1'b1;
        end else begin
            ref_plane_t = FIXED_MAX;
            ref_plane_hit = 1'b0;
        end
    end

    //delay the rest of the bounce ray to line up with the divider
    fixed_t ox_pipe [0:19];
    fixed_t oz_pipe [0:19];
    fixed_t rdx_pipe [0:19];
    fixed_t rdz_pipe [0:19];
    logic is_sphere_pipe [0:19];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 20; i++) begin
                ox_pipe[i] <= 0; oz_pipe[i] <= 0;
                rdx_pipe[i] <= 0; rdz_pipe[i] <= 0;
                is_sphere_pipe[i] <= 0;
            end
        end else begin
            ox_pipe[0] <= ox_r;
            oz_pipe[0] <= oz_r;
            rdx_pipe[0] <= reflect_dir_x;
            rdz_pipe[0] <= reflect_dir_z;
            is_sphere_pipe[0] <= is_sphere_r;
            for (int i = 0; i < 19; i++) begin
                ox_pipe[i+1] <= ox_pipe[i];
                oz_pipe[i+1] <= oz_pipe[i];
                rdx_pipe[i+1] <= rdx_pipe[i];
                rdz_pipe[i+1] <= rdz_pipe[i];
                is_sphere_pipe[i+1] <= is_sphere_pipe[i];
            end
        end
    end

    //reflection as normal ray
    fixed_t ref_hit_x, ref_hit_z;
    assign ref_hit_x = ox_pipe[19] + ((34'(rdx_pipe[19]) * ref_plane_t) >>> 9);
    assign ref_hit_z = oz_pipe[19] + ((34'(rdz_pipe[19]) * ref_plane_t) >>> 9);

    //calcualte color same as a camera ray for color_output to blend
    logic [7:0] r_temp, g_temp, b_temp;
    checkerboard_color color_inst (
        .hit_x(ref_hit_x),
        .hit_z(ref_hit_z),
        .r(r_temp),
        .g(g_temp),
        .b(b_temp)
    );

    always_comb begin
        if (ref_plane_hit && is_sphere_pipe[19]) begin
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
