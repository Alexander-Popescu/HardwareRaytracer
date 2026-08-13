import fixed_point::*;

//tells you which object was hit this pixel
module hit_selector (
    input  fixed_t sphere_t,
    input  fixed_t plane_t,
    input  logic  sphere_hit,
    input  logic  plane_hit,
    output fixed_t t,
    output logic  hit_sphere
);

    always_comb begin
        if (sphere_hit && plane_hit) begin
            //select smaller
            if (sphere_t < plane_t) begin
                t = sphere_t;
                hit_sphere = 1'b1;
            end else begin
                t = plane_t;
                hit_sphere = 1'b0;
            end
        end else if (sphere_hit) begin
            t = sphere_t;
            hit_sphere = 1'b1;
        end else if (plane_hit) begin
            t = plane_t;
            hit_sphere = 1'b0;
        end else begin
            //max distance
            t = FIXED_MAX;
            hit_sphere = 1'b0;
        end
    end
endmodule
