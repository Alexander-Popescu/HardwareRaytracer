import fixed_point::*;

//integer square root with binary search type thing
module int_sqrt (
    input  logic clk,
    input  logic rst,
    input  logic signed [33:0] in,
    output logic signed [16:0] out
);

    logic [33:0] in_pipe [0:17];
    logic [16:0] res_pipe [0:17];

    always_ff @(posedge clk) begin
        if (rst) begin
            in_pipe[0] <= 0;
            res_pipe[0] <= 17'd0;
        end else begin
            //negatives clamp to 0
            in_pipe[0] <= (in < 0) ? 34'd0 : in;
            res_pipe[0] <= 17'd0;
        end
    end

    genvar i;
    generate
        for (i = 15; i >= 0; i--) begin : sqrt_stages
            localparam stage_idx = 16 - i;
            logic [16:0] test_val;
            logic [33:0] test_sq;

            assign test_val = res_pipe[stage_idx-1] | (17'd1 << i);
            assign test_sq = test_val * test_val;

            always_ff @(posedge clk) begin
                if (rst) begin
                    in_pipe[stage_idx] <= 0;
                    res_pipe[stage_idx] <= 0;
                end else begin
                    in_pipe[stage_idx] <= in_pipe[stage_idx-1];

                    if (test_sq <= in_pipe[stage_idx-1]) begin
                        res_pipe[stage_idx] <= test_val;
                    end else begin
                        res_pipe[stage_idx] <= res_pipe[stage_idx-1];
                    end
                end
            end
        end
    endgenerate

    //round to nearest
    always_ff @(posedge clk) begin
        if (rst) begin
            in_pipe[17] <= 0;
            res_pipe[17] <= 0;
        end else begin
            in_pipe[17] <= in_pipe[16];
            if (in_pipe[16] - (res_pipe[16] * res_pipe[16]) >= ((res_pipe[16] + 17'd1) * (res_pipe[16] + 17'd1)) - in_pipe[16]) begin
                res_pipe[17] <= res_pipe[16] + 17'd1;
            end else begin
                res_pipe[17] <= res_pipe[16];
            end
        end
    end

    assign out = res_pipe[17];

endmodule
