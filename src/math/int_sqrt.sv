import fixed_point::*;

//integer square root with binary search type thing 
module int_sqrt (
    input  logic signed [33:0] in,
    output logic signed [16:0] out
);

    //negatives round to zero
    logic [33:0] in_pos;
    always_comb begin
        in_pos = (in < 0) ? 34'd0 : in;
    end

    logic [16:0] result;
    logic [16:0] test_val;
    logic [33:0] test_squared;
    
    always_comb begin
        result = 17'd0;
        
        //for each bit, MSB -> LSB:
        for (int i = 15; i >= 0; i--) begin
            //set bit as test
            test_val = result | (17'd1 << i);
            test_squared = test_val * test_val;
            //if squared test hasnt gone over, we can further approach the value
            if (test_squared <= in_pos) begin
                result = test_val;
            end
        end
        
        //if we are stuck between two values, choose closer
        if (in_pos - (result * result) >= ((result + 17'd1) * (result + 17'd1)) - in_pos) begin
            result = result + 17'd1;
        end
    end
    
    assign out = (in < 0) ? 17'sd0 : result;

endmodule
