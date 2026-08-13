import fixed_point::*;

//hit flag and distance for ray vs plane
//pipelined divider inside with PIPE_LATENCY cycle latency
module plane_intersect (
    input  logic clk,
    input  logic rst,
    //we only care about y
    input  fixed_t ray_origin_y,
    input  fixed_t ray_dir_y,
    input  fixed_t plane_y,
    output fixed_t t,
    output logic hit
);

    //height above plane
    logic signed [33:0] y_distance;
    assign y_distance = (plane_y - ray_origin_y) * FIXED_ONE;

    //entry register keeps this in lockstep with sphere_intersect
    logic signed [33:0] y_distance_r;
    fixed_t ray_dir_y_r;
    always_ff @(posedge clk) begin
        if (rst) begin
            y_distance_r <= 0; ray_dir_y_r <= 0;
        end else begin
            y_distance_r <= y_distance; ray_dir_y_r <= ray_dir_y;
        end
    end

    logic [16:0] q_mag;
    logic q_neg, ovf;

    div_pipe div_inst (
        .clk(clk),
        .rst(rst),
        .dividend(y_distance_r),
        .divisor(ray_dir_y_r),
        .q_mag(q_mag),
        .q_neg(q_neg),
        .ovf(ovf)
    );

    //two result registers keep this in step with sphere_intersect's divide by 2a
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

    //hit needs t positive and small enough to fit
    always_comb begin
        if (!ovf_d2 && !neg_d2 && !q_d2[16] && q_d2 != 0) begin
            t = q_d2;
            hit = 1'b1;
        end else begin
            t = FIXED_MAX;
            hit = 1'b0;
        end
    end
endmodule
