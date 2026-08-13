import fixed_point::*;

//phong diffuse without highlights
module diffuse_shading (
    input  fixed_t normal_x,
    input  fixed_t normal_y,
    input  fixed_t normal_z,
    output fixed_t intensity
);

    //dot product of normal and light
    logic signed [33:0] nl_dp;
    assign nl_dp = ((normal_x * LIGHT_DIR_X) >>> 9) + ((normal_y * LIGHT_DIR_Y) >>> 9) + ((normal_z * LIGHT_DIR_Z) >>> 9);

    logic background;
    //idk if this can occur otherwise
    assign background = (normal_x == 0) && (normal_y == 0) && (normal_z == 0);

    always_comb begin
        if (background) begin
            intensity = FIXED_ONE;
        end else begin
            if (nl_dp > 0) begin
                //facing light
                intensity = nl_dp + FIXED_AMBIENT;
            end else begin
                intensity = FIXED_AMBIENT;
            end
        end
    end

endmodule
