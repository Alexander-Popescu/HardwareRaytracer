import fixed_point::*;

//pipelined long division with one quotient bit per stage
module div_pipe (
    input  logic clk,
    input  logic rst,
    input  logic signed [33:0] dividend,
    input  logic signed [16:0] divisor,
    output logic [16:0] q_mag,
    output logic q_neg,
    //ovf covers quotient overflow and divide by zero
    output logic ovf
);

    logic [33:0] rem_pipe [0:17];
    logic [16:0] b_pipe [0:17];
    logic [16:0] quot_pipe [0:17];
    logic neg_pipe [0:17];
    logic ovf_pipe [0:17];

    //work on magnitudes and reapply the sign at the end
    logic [33:0] abs_a;
    logic [16:0] abs_b;
    assign abs_a = dividend[33] ? -dividend : dividend;
    assign abs_b = divisor[16] ? -divisor : divisor;

    always_ff @(posedge clk) begin
        if (rst) begin
            rem_pipe[0] <= 0; b_pipe[0] <= 0; quot_pipe[0] <= 0;
            neg_pipe[0] <= 0; ovf_pipe[0] <= 0;
        end else begin
            rem_pipe[0] <= abs_a;
            b_pipe[0] <= abs_b;
            quot_pipe[0] <= 0;
            neg_pipe[0] <= dividend[33] ^ divisor[16];
            ovf_pipe[0] <= (divisor == 0) || (abs_a[33:17] >= abs_b);
        end
    end

    genvar i;
    generate
        for (i = 16; i >= 0; i--) begin : div_stages
            localparam stage_idx = 17 - i;
            logic [33:0] shifted_b;
            assign shifted_b = 34'(b_pipe[stage_idx-1]) << i;

            always_ff @(posedge clk) begin
                if (rst) begin
                    rem_pipe[stage_idx] <= 0; b_pipe[stage_idx] <= 0;
                    quot_pipe[stage_idx] <= 0; neg_pipe[stage_idx] <= 0;
                    ovf_pipe[stage_idx] <= 0;
                end else begin
                    b_pipe[stage_idx] <= b_pipe[stage_idx-1];
                    neg_pipe[stage_idx] <= neg_pipe[stage_idx-1];
                    ovf_pipe[stage_idx] <= ovf_pipe[stage_idx-1];
                    if (rem_pipe[stage_idx-1] >= shifted_b) begin
                        rem_pipe[stage_idx] <= rem_pipe[stage_idx-1] - shifted_b;
                        quot_pipe[stage_idx] <= quot_pipe[stage_idx-1] | (17'd1 << i);
                    end else begin
                        rem_pipe[stage_idx] <= rem_pipe[stage_idx-1];
                        quot_pipe[stage_idx] <= quot_pipe[stage_idx-1];
                    end
                end
            end
        end
    endgenerate

    assign q_mag = quot_pipe[17];
    assign q_neg = neg_pipe[17];
    assign ovf = ovf_pipe[17];

endmodule
