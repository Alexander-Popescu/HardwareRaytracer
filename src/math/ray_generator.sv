import fixed_point::*;

//generate rays toward each pixel for projection
//camera is at (0, 0, 1024) looking toward -Z direction
module ray_generator #(
    parameter H_RES = 640,
    parameter V_RES = 480
)(
    //position on resolution grid
    input  logic [9:0] h_count,
    input  logic [9:0] v_count,
    output fixed_t   dir_x,
    output fixed_t   dir_y,
    output fixed_t   dir_z
);

    //shift so (0,0) is at screen center
    logic signed [16:0] h_offset;
    logic signed [16:0] v_offset;

    assign h_offset = h_count - (H_RES / 2);
    assign v_offset = (V_RES / 2) - v_count;

    //scale to normalized device coords with a multiply instead of a divide
    //512*512/320 = 819 and y matches because the 0.75 aspect fix cancels
    localparam fixed_t NDC_SCALE = 17'sd819;

    //34 bit so the products dont wrap before the shift
    logic signed [33:0] u_full, v_full;
    assign u_full = h_offset * NDC_SCALE;
    assign v_full = v_offset * NDC_SCALE;

    assign dir_x = u_full >>> 9;
    assign dir_y = v_full >>> 9;
    assign dir_z = -FIXED_ONE;

endmodule
