//pixel color is calculated in 3 stages, queue them for timing alignment
module pixel_queue #(
    parameter N_STAGES = 3
) (
    input  logic clk,
    input  logic rst,
    input  logic push_en,
    input  logic [31:0] push_data,
    output logic [31:0] pop_data
);
    logic [31:0] queue [0:N_STAGES-1];

    //clk -> shift
    always_ff @(posedge clk) begin
        if (rst) begin
            queue[0] <= 32'd0;
            queue[1] <= 32'd0;
            queue[2] <= 32'd0;
        end else if (push_en) begin
            queue[2] <= queue[1];
            queue[1] <= queue[0];
            queue[0] <= push_data;
        end
    end
    assign pop_data = queue[N_STAGES-1];

endmodule
