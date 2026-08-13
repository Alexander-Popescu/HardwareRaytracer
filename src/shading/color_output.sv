import fixed_point::*;

//generates the final color with all parameters it needs
//two register banks so each cycle has one multiply level
module color_output (
    input  logic clk,
    input  logic rst,
    //base is the object this ray hit
    input  logic [7:0] base_r,
    input  logic [7:0] base_g,
    input  logic [7:0] base_b,
    //reflection visible on the hit surface
    input  logic [7:0] reflect_r,
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

    //input registers because arriving values are already one multiply deep
    logic [7:0] base_r_q, base_g_q, base_b_q;
    logic [7:0] reflect_r_q, reflect_g_q, reflect_b_q;
    fixed_t reflectivity_q, intensity_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            base_r_q <= 0; base_g_q <= 0; base_b_q <= 0;
            reflect_r_q <= 0; reflect_g_q <= 0; reflect_b_q <= 0;
            reflectivity_q <= 0; intensity_q <= 0;
        end else begin
            base_r_q <= base_r; base_g_q <= base_g; base_b_q <= base_b;
            reflect_r_q <= reflect_r; reflect_g_q <= reflect_g; reflect_b_q <= reflect_b;
            reflectivity_q <= reflectivity; intensity_q <= diffuse_intensity;
        end
    end

    //color mix is vibes not physics
    //FIXED_ONE prevents precision losses during truncation and stuff
    //diffuse and reflection scaling with one real multiply each
    logic signed [33:0] base_term_r, base_term_g, base_term_b;
    logic signed [33:0] refl_prod_r, refl_prod_g, refl_prod_b;
    fixed_t intensity_q2;

    always_ff @(posedge clk) begin
        if (rst) begin
            base_term_r <= 0; base_term_g <= 0; base_term_b <= 0;
            refl_prod_r <= 0; refl_prod_g <= 0; refl_prod_b <= 0;
            intensity_q2 <= 0;
        end else begin
            base_term_r <= ((base_r_q * FIXED_ONE) * intensity_q) >>> 9;
            base_term_g <= ((base_g_q * FIXED_ONE) * intensity_q) >>> 9;
            base_term_b <= ((base_b_q * FIXED_ONE) * intensity_q) >>> 9;
            refl_prod_r <= ((reflect_r_q * FIXED_ONE) * reflectivity_q) >>> 9;
            refl_prod_g <= ((reflect_g_q * FIXED_ONE) * reflectivity_q) >>> 9;
            refl_prod_b <= ((reflect_b_q * FIXED_ONE) * reflectivity_q) >>> 9;
            intensity_q2 <= intensity_q;
        end
    end

    //last multiply for the reflection term
    logic signed [33:0] final_r_fp;
    logic signed [33:0] final_g_fp;
    logic signed [33:0] final_b_fp;

    assign final_r_fp = base_term_r + ((refl_prod_r * intensity_q2) >>> 9);
    assign final_g_fp = base_term_g + ((refl_prod_g * intensity_q2) >>> 9);
    assign final_b_fp = base_term_b + ((refl_prod_b * intensity_q2) >>> 9);

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

    logic [7:0] r_out, g_out, b_out;
    assign r_out = final_r_clamped[15:8];
    assign g_out = final_g_clamped[15:8];
    assign b_out = final_b_clamped[15:8];

    //finally determine pixel
    always_comb begin
        if (no_hit) begin
            red = SKY_R;
            green = SKY_G;
            blue = SKY_B;
        end else begin
            red = r_out;
            green = g_out;
            blue = b_out;
        end
    end

endmodule
