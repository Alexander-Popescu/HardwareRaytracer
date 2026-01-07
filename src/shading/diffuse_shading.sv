import fixed_point::*;

//diffuse shading model, phong without highlights
module diffuse_shading (
    input  fixed_t normal_x,
    input  fixed_t normal_y,
    input  fixed_t normal_z,
    output fixed_t intensity
);

    //hardcode light direction TODO match with shadow
    localparam fixed_t LIGHT_DIR_X = 17'sd200;
    localparam fixed_t LIGHT_DIR_Y = 17'sd325;
    localparam fixed_t LIGHT_DIR_Z = 17'sd200;

    //everything is too dark add constant offset
    localparam fixed_t FIXED_AMBIENT = 17'sd50;

    //dot product of normal and light
    logic signed [33:0] nl_dp;
    assign nl_dp = ((normal_x * LIGHT_DIR_X) >>> 9) + ((normal_y * LIGHT_DIR_Y) >>> 9) + ((normal_z * LIGHT_DIR_Z) >>> 9);

    logic background;
    assign background = (normal_x == 0) && (normal_y == 0) && (normal_z == 0); //idk if this can occur otherwise, shouldnt though


    always_comb begin
        if (background) begin
            intensity = FIXED_ONE;//full
        end else begin
            if (nl_dp > 0) begin
                //facing light
                fixed_t diffuse;
                intensity = nl_dp + FIXED_AMBIENT;
            end else begin
                intensity = FIXED_AMBIENT;
            end
        end
    end

endmodule
