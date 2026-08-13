`timescale 1ns/1ns
//limits simulation to a few frames so we can see it with vgasim
module vga_tb;

    //first vsync flushes the pipeline before two clean frames
    localparam NUM_VSYNCS = 3;

    logic clk = 0;
    logic rst = 1;
    logic hsync, vsync;
    logic [7:0] red, green, blue;

    int fd;
    int vsync_count = 0;
    logic prev_vsync = 1;

    vga_controller dut (.*);

    always #20 clk = ~clk;

    initial begin
        fd = $fopen("output/vga_out.txt", "w");
        #200 rst = 0;
        $display("VGA Testbench: running %0d vsync periods", NUM_VSYNCS);
    end

    always @(posedge clk) begin
        if (!rst) begin
            $fdisplay(fd, "%0d ns: %b %b %b %b %b", $time, hsync, vsync, red, green, blue);

            if (prev_vsync && !vsync) begin
                vsync_count <= vsync_count + 1;
                $display("vsync %0d", vsync_count + 1);
                if (vsync_count + 1 == NUM_VSYNCS) begin
                    $fclose(fd);
                    $finish;
                end
            end
            prev_vsync <= vsync;
        end
    end

endmodule
