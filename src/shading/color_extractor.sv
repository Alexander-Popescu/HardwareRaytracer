//just decodes pixel data, RGBA but I didnt do the A
module color_extractor (
    input  logic [31:0] pixel_data,
    output logic [7:0]  red,
    output logic [7:0]  green,
    output logic [7:0]  blue
);
    assign red = pixel_data[31:24];
    assign green = pixel_data[23:16];
    assign blue = pixel_data[15:8];
endmodule
