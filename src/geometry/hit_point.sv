import fixed_point::*;

//just move down ray the specified distance
module hit_point (
    input  fixed_t origin_x,
    input  fixed_t origin_y,
    input  fixed_t origin_z,
    input  fixed_t dir_x,
    input  fixed_t dir_y,
    input  fixed_t dir_z,
    input  fixed_t t,
    output fixed_t point_x,
    output fixed_t point_y,
    output fixed_t point_z
);

    //displacements per axis
    logic signed [33:0] disp_x;
    logic signed [33:0] disp_y;
    logic signed [33:0] disp_z;

    assign disp_x = dir_x * t;
    assign disp_y = dir_y * t;
    assign disp_z = dir_z * t;

    //walk down the ray
    assign point_x = origin_x + (disp_x >>> 9);
    assign point_y = origin_y + (disp_y >>> 9);
    assign point_z = origin_z + (disp_z >>> 9);

endmodule
