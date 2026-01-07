import fixed_point::*;

//Reflection equation implementation R = I - 2*(N·I)*N
module reflect_calc (
    input  fixed_t ray_dir_x,
    input  fixed_t ray_dir_y,
    input  fixed_t ray_dir_z,
    input  fixed_t normal_x,
    input  fixed_t normal_y,
    input  fixed_t normal_z,
    output fixed_t reflect_dir_x,
    output fixed_t reflect_dir_y,
    output fixed_t reflect_dir_z
);

    //dot product N·I
    logic signed [33:0] ni_dp;
    assign ni_dp = (((normal_x * ray_dir_x) >>> 9) + ((normal_y * ray_dir_y) >>> 9) + ((normal_z * ray_dir_z) >>> 9));

    //     R             = I         - (N·I)  * 2      * N           
    assign reflect_dir_x = ray_dir_x - (((ni_dp * 17'sd2 * normal_x) >>> 9));
    assign reflect_dir_y = ray_dir_y - (((ni_dp * 17'sd2 * normal_y) >>> 9));
    assign reflect_dir_z = ray_dir_z - (((ni_dp * 17'sd2 * normal_z) >>> 9));

endmodule   
