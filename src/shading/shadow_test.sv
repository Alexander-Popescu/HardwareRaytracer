import fixed_point::*;

//walk a ray from hit point to lightsource to test if its obscured
module shadow_test (
    input  logic clk,
    input  logic rst,
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

    fixed_t shadow_origin_x;
    fixed_t shadow_origin_y;
    fixed_t shadow_origin_z;

    //self intersection fix whoops
    assign shadow_origin_x = hit_x + (normal_x >>> 4);
    assign shadow_origin_y = hit_y + (normal_y >>> 4);
    assign shadow_origin_z = hit_z + (normal_z >>> 4);

    fixed_t shadow_t;
    logic shadow_hit;

    sphere_intersect shadow_sphere_inst (
        .clk(clk),
        .rst(rst),
        .ray_origin_x(shadow_origin_x),
        .ray_origin_y(shadow_origin_y),
        .ray_origin_z(shadow_origin_z),
        //explicit scope or iverilog makes a bogus 1 bit wire
        .ray_dir_x(fixed_point::LIGHT_DIR_X),
        .ray_dir_y(fixed_point::LIGHT_DIR_Y),
        .ray_dir_z(fixed_point::LIGHT_DIR_Z),
        .sphere_center_x(sphere_center_x),
        .sphere_center_y(sphere_center_y),
        .sphere_center_z(sphere_center_z),
        .sphere_radius(sphere_radius),
        .t(shadow_t),
        .hit(shadow_hit)
    );

    //delay hit_x/hit_z to line up with shadow_hit for the artifact purge below
    fixed_t hit_x_pipe [0:PIPE_LATENCY-1];
    fixed_t hit_z_pipe [0:PIPE_LATENCY-1];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < PIPE_LATENCY; i++) begin
                hit_x_pipe[i] <= 0;
                hit_z_pipe[i] <= 0;
            end
        end else begin
            hit_x_pipe[0] <= hit_x;
            hit_z_pipe[0] <= hit_z;
            for (int i = 0; i < PIPE_LATENCY-1; i++) begin
                hit_x_pipe[i+1] <= hit_x_pipe[i];
                hit_z_pipe[i+1] <= hit_z_pipe[i];
            end
        end
    end

    //purge far off shadows from artifacting
    logic signed [33:0] hit_dist;
    assign hit_dist = ((hit_x_pipe[PIPE_LATENCY-1] - sphere_center_x) * (hit_x_pipe[PIPE_LATENCY-1] - sphere_center_x)) + ((hit_z_pipe[PIPE_LATENCY-1] - sphere_center_z) * (hit_z_pipe[PIPE_LATENCY-1] - sphere_center_z));

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
