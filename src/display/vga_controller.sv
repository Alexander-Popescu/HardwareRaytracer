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
    localparam H_FRONT = 16;
    localparam H_SYNC = 96;
    localparam H_BACK = 48;
    localparam H_TOTAL = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT = 10;
    localparam V_SYNC = 2;
    localparam V_BACK = 33;
    localparam V_TOTAL = 525;

    logic [9:0] h_count;
    logic [9:0] v_count;
    logic raw_active_display;
    logic raw_hsync;
    logic raw_vsync;

    //vga timing
    always_ff @(posedge clk) begin
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
            raw_hsync = 1'b0;
        end else begin
            raw_hsync = 1'b1;
        end
    end

    always_comb begin
        if ((v_count >= V_VISIBLE + V_FRONT) && (v_count < V_VISIBLE + V_FRONT + V_SYNC)) begin
            raw_vsync = 1'b0;
        end else begin
            raw_vsync = 1'b1;
        end
    end

    always_comb begin
        if (h_count < H_VISIBLE && v_count < V_VISIBLE) begin
            raw_active_display = 1'b1;
        end else begin
            raw_active_display = 1'b0;
        end
    end

    //delay syncs to match the renderer latency
    localparam RENDER_LATENCY = 2 * (PIPE_LATENCY + 3);
    logic [RENDER_LATENCY-1:0] hsync_pipe;
    logic [RENDER_LATENCY-1:0] vsync_pipe;
    logic [RENDER_LATENCY-1:0] active_disp_pipe;

    always_ff @(posedge clk) begin
        if (rst) begin
            hsync_pipe <= {RENDER_LATENCY{1'b1}};
            vsync_pipe <= {RENDER_LATENCY{1'b1}};
            active_disp_pipe <= '0;
        end else begin
            hsync_pipe <= {hsync_pipe[RENDER_LATENCY-2:0], raw_hsync};
            vsync_pipe <= {vsync_pipe[RENDER_LATENCY-2:0], raw_vsync};
            active_disp_pipe <= {active_disp_pipe[RENDER_LATENCY-2:0], raw_active_display};
        end
    end

    assign hsync = hsync_pipe[RENDER_LATENCY-1];
    assign vsync = vsync_pipe[RENDER_LATENCY-1];
    logic active_display;
    assign active_display = active_disp_pipe[RENDER_LATENCY-1];

    logic [31:0] renderer_pixel_data;

    graphics_renderer #(
        .SPHERE_CENTER_X(SPHERE_CENTER_X),
        .SPHERE_CENTER_Y(SPHERE_CENTER_Y),
        .SPHERE_CENTER_Z(SPHERE_CENTER_Z),
        .SPHERE_RADIUS(SPHERE_RADIUS),
        .PLANE_Y(PLANE_Y)
    ) renderer_inst (
        .clk(clk),
        .rst(rst),
        .rt_h_count(h_count),
        .rt_v_count(v_count),
        .rt_enable(1'b1),
        .pixel_data(renderer_pixel_data)
    );

    //decode rgb vals
    logic [7:0] raw_red, raw_green, raw_blue;
    color_extractor color_extractor_inst (
        .pixel_data(renderer_pixel_data),
        .red(raw_red),
        .green(raw_green),
        .blue(raw_blue)
    );

    //mask colors outside the active area
    assign red   = active_display ? raw_red   : 8'd0;
    assign green = active_display ? raw_green : 8'd0;
    assign blue  = active_display ? raw_blue  : 8'd0;

endmodule
