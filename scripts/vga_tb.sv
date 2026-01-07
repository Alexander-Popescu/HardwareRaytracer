`timescale 1ns/1ns
//limits simulation to a few frames so we can see it with vgasim
module vga_tb;

    localparam NUM_FRAMES = 2;

    logic clk = 0;
    logic rst = 1;
    logic hsync, vsync;
    logic [7:0] red, green, blue;

    int fd;
    int frame_count = 0;
    logic prev_vsync = 1;

    vga_controller dut (.*);

    always #20 clk = ~clk;

    initial begin
        fd = $fopen("output/vga_out.txt", "w");
        #200 rst = 0;

        @(posedge clk);
        @(posedge clk);

        $display("VGA Testbench");
        $display("========================");

        wait(dut.active_display && dut.h_count == 0 && dut.v_count == 0);
        $display("First frame started");

        repeat(NUM_FRAMES) @(negedge vsync);

        $fclose(fd);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            $fdisplay(fd, "%0d ns: %b %b %b %b %b", $time, hsync, dut.vsync, red, green, blue);

            if (prev_vsync && !dut.vsync)
                frame_count <= frame_count + 1;
            prev_vsync <= dut.vsync;
        end
    end

endmodule
