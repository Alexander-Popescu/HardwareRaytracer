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

    //offset from center to move coordinate system to something nicer, (0,0) at center
    logic signed [16:0] h_offset;
    logic signed [16:0] v_offset;


    assign h_offset = h_count - (H_RES / 2);
    assign v_offset = (V_RES / 2) - v_count;

    //normalized device coordinates
    fixed_t u;
    fixed_t v;

    logic signed [33:0] h_scaled;
    logic signed [33:0] v_scaled;

    assign u = (h_offset * FIXED_ONE) / (H_RES / 2);
    assign v = (v_offset * FIXED_ONE) / (V_RES / 2);

    //correct for the aspect ratio so the sphere actually looks round
    logic signed [33:0] v_fov_scaled;
    assign v_fov_scaled = (v * 17'sd384) >>> 9; //v * 0.75

    assign dir_x = u;
    assign dir_y = v_fov_scaled[16:0];
    assign dir_z = -FIXED_ONE; //cam direction

endmodule
