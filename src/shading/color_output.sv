import fixed_point::*;

//generates the final color with all parameters it needs
module color_output (
    input  logic [7:0] base_r, //base refers to the object this ray hit
    input  logic [7:0] base_g,
    input  logic [7:0] base_b,
    input  logic [7:0] reflect_r,//reflection, again, visible on the hit surface
    input  logic [7:0] reflect_g,
    input  logic [7:0] reflect_b,
    input  fixed_t  reflectivity,
    input  fixed_t  diffuse_intensity,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    //default color when no hits
    localparam SKY_R = 8'd173;
    localparam SKY_G = 8'd216;
    localparam SKY_B = 8'd230;

    //mix colors, this isnt physically based so im just going on vibes mostly

    logic signed [33:0] final_r_fp;
    logic signed [33:0] final_g_fp;
    logic signed [33:0] final_b_fp;

    // FIXED_ONE prevents precision losses during truncation and stuff
    //                          diffuse lighting                            reflection                       reflection shading
    assign final_r_fp = (((base_r * FIXED_ONE) * diffuse_intensity) >>> 9) + (((((reflect_r * FIXED_ONE) * reflectivity) >>> 9) * diffuse_intensity) >>> 9);
    assign final_g_fp = (((base_g * FIXED_ONE) * diffuse_intensity) >>> 9) + (((((reflect_g * FIXED_ONE) * reflectivity) >>> 9) * diffuse_intensity) >>> 9);
    assign final_b_fp = (((base_b * FIXED_ONE) * diffuse_intensity) >>> 9) + (((((reflect_b * FIXED_ONE) * reflectivity) >>> 9) * diffuse_intensity) >>> 9);

    //clamp output for going back to 8 bit color
    localparam logic [33:0] COLOR_MAX = 34'd65280;
    
    logic signed [33:0] final_r_clamped;
    logic signed [33:0] final_g_clamped;
    logic signed [33:0] final_b_clamped;

    assign final_r_clamped = (final_r_fp > COLOR_MAX) ? COLOR_MAX : final_r_fp;
    assign final_g_clamped = (final_g_fp > COLOR_MAX) ? COLOR_MAX : final_g_fp;
    assign final_b_clamped = (final_b_fp > COLOR_MAX) ? COLOR_MAX : final_b_fp;

    //check if we should render sky
    logic no_hit;
    assign no_hit = (final_r_clamped == 0) && (final_g_clamped == 0) && (final_b_clamped == 0);

    //finally determine pixel
    always_comb begin
        if (no_hit) begin
            red = SKY_R;
            green = SKY_G;
            blue = SKY_B;
        end else begin
            red = final_r_clamped[15:8];
            green = final_g_clamped[15:8];
            blue = final_b_clamped[15:8];
        end
    end

endmodule
