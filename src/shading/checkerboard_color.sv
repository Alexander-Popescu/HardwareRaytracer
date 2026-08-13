import fixed_point::*;

//color the plane hits to not be so dull
module checkerboard_color (
    input fixed_t hit_x,
    input fixed_t hit_z,
    output logic [7:0] r,
    output logic [7:0] g,
    output logic [7:0] b
);
    //white and gray squares
    localparam logic [7:0] ColorA_R = 8'd255;
    localparam logic [7:0] ColorA_G = 8'd255;
    localparam logic [7:0] ColorA_B = 8'd255;

    localparam logic [7:0] ColorB_R = 8'd128;
    localparam logic [7:0] ColorB_G = 8'd128;
    localparam logic [7:0] ColorB_B = 8'd128;
    
    //bit 8 of each coord xored makes the checkerboard
    logic is_A;
    assign is_A = hit_x[8] ^ hit_z[8];

    always_comb begin
        if (is_A) begin
            r = ColorA_R;
            g = ColorA_G;
            b = ColorA_B;
        end else begin
            r = ColorB_R;
            g = ColorB_G;
            b = ColorB_B;
        end
    end

endmodule
