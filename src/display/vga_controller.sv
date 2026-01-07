import fixed_point::*;

//VGA timing generator
module vga_controller #(
    parameter SPHERE_CENTER_X = 0,
    parameter SPHERE_CENTER_Y = -256,
    parameter SPHERE_CENTER_Z = -256,
    parameter SPHERE_RADIUS = 384,
    parameter PLANE_Y = -768
) (
    input  logic clk,
    input  logic rst,
    output logic hsync,
    output logic vsync,
    output logic [7:0]  red,
    output logic [7:0]  green,
    output logic [7:0]  blue
);

    //VGA spec
    localparam H_VISIBLE = 640;
    localparam H_FRONT = 16;  //front porch
    localparam H_SYNC = 96; //sync pulse width
    localparam H_BACK = 48; //back porch
    localparam H_TOTAL = 800;//cycles per line

    localparam V_VISIBLE = 480;
    localparam V_FRONT = 10;
    localparam V_SYNC = 2;
    localparam V_BACK = 33;
    localparam V_TOTAL = 525; //lines per frame

    logic [9:0] h_count;
    logic [9:0] v_count;
    logic active_display;

    //pixel buffer signals
    logic queue_push_en;
    assign queue_push_en = 1'b1;
    logic [31:0] renderer_pixel_data;
    logic [31:0] queue_pop_data;

    localparam PIPELINE_OFFSET = 3;
    logic [9:0] ray_x;
    logic [9:0] ray_y;

    //effective coordinates for rays, with pipeline offset
    assign ray_x = (h_count + PIPELINE_OFFSET) % H_VISIBLE;
    assign ray_y = ((v_count + ((h_count + PIPELINE_OFFSET) / H_VISIBLE)) > (V_VISIBLE - 1)) ? 
                    0 : (v_count + ((h_count + PIPELINE_OFFSET) / H_VISIBLE));

    //vga timing
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 10'd1) begin
                //line wrap
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 10'd1) begin
                    //frame wrap
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 10'd1;
                end
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    //sync pulses

    always_comb begin
        if ((h_count >= H_VISIBLE + H_FRONT) && (h_count < H_VISIBLE + H_FRONT + H_SYNC)) begin
            hsync = 1'b0;
        end else begin
            hsync = 1'b1;
        end
    end

    always_comb begin
        if ((v_count >= V_VISIBLE + V_FRONT) && (v_count < V_VISIBLE + V_FRONT + V_SYNC)) begin
            vsync = 1'b0;
        end else begin
            vsync = 1'b1;
        end
    end

    always_comb begin
        if (h_count < H_VISIBLE && v_count < V_VISIBLE) begin
            active_display = 1'b1;
        end else begin
            active_display = 1'b0;
        end
    end

    graphics_renderer #(
        .SPHERE_CENTER_X(SPHERE_CENTER_X),
        .SPHERE_CENTER_Y(SPHERE_CENTER_Y),
        .SPHERE_CENTER_Z(SPHERE_CENTER_Z),
        .SPHERE_RADIUS(SPHERE_RADIUS),
        .PLANE_Y(PLANE_Y)
    ) renderer_inst (
        .clk(clk),
        .rst(rst),
        .rt_h_count(ray_x),
        .rt_v_count(ray_y),
        .rt_enable(1'b1),
        .pixel_data(renderer_pixel_data)
    );

    //sync pixels to when they should be displayed
    pixel_queue #(.N_STAGES(3)) pixel_queue_inst (
        .clk(clk),
        .rst(rst),
        .push_en(queue_push_en),
        .push_data(renderer_pixel_data),
        .pop_data(queue_pop_data)
    );

    //decode rgb vals
    color_extractor color_extractor_inst (
        .pixel_data(queue_pop_data),
        .red(red),
        .green(green),
        .blue(blue)
    );

endmodule
