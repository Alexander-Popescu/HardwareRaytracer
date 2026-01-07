import fixed_point::*;

//True / False if ray intersects plane, and distnace
module plane_intersect (
    input  fixed_t ray_origin_y, //we only care about y
    input  fixed_t ray_dir_y,
    input  fixed_t plane_y,
    output fixed_t t,
    output logic hit
);

    //height above plane
    logic signed [33:0] y_distance;
    assign y_distance = (plane_y - ray_origin_y) * FIXED_ONE;

    always_comb begin
        if (ray_dir_y != 0) begin
            //t > 0 or we intersect behind
            if ((y_distance > 0 && ray_dir_y > 0) || (y_distance < 0 && ray_dir_y < 0)) begin
                t = y_distance / ray_dir_y;
                hit = t > 0 ? 1'b1 : 1'b0;
            end else begin
                //behind
                t = FIXED_MAX;
                hit = 1'b0;
            end
        end else begin
            //parallel ray
            t = FIXED_MAX;
            hit = 1'b0;
        end
    end
endmodule
