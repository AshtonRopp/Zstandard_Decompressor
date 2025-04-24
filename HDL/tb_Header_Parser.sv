`timescale 1ns / 1ps

module tb_Header_Parser();

    logic clk;
    logic reset;
    logic start;
    logic [15:0] data_in;

    logic finished;
    logic [7:0] sizes;
    logic [7:0] Frame_Header_Descriptor;
    logic [7:0] Window_Descriptor;
    logic [31:0] Dictionary_ID;
    logic [63:0] Frame_Content_Size;
    logic [7:0] extra_byte;

    // Instantiate DUT
    Header_Parser dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .data_in(data_in),
        .finished(finished),
        .sizes(sizes),
        .Frame_Header_Descriptor(Frame_Header_Descriptor),
        .Window_Descriptor(Window_Descriptor),
        .Dictionary_ID(Dictionary_ID),
        .Frame_Content_Size(Frame_Content_Size),
        .extra_byte(extra_byte)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // ROM to hold test data (input.data: 2 bytes per line in hex)
    logic [15:0] rom [0:31];
    integer i;

    initial begin
        $display("Starting testbench...");
        $readmemh("input.data", rom);

        // Initialize inputs
        reset = 1;
        start = 0;
        data_in = 16'h0000;
        #20;
        reset = 0;
        #10;
        start = 1;

        // Send data from ROM
        for (i = 0; i < 32; i++) begin
            @(posedge clk);
            data_in = rom[i];
        end

        start = 0;
        @(posedge clk);
        @(posedge clk);

        $display("==== Results ====");
        $display("Finished:               %0d", finished);
        $display("Sizes:                  0x%0h", sizes);
        $display("Frame Header Descriptor: 0x%0h", Frame_Header_Descriptor);
        $display("Window Descriptor:      0x%0h", Window_Descriptor);
        $display("Dictionary ID:          0x%0h", Dictionary_ID);
        $display("Frame Content Size:     0x%0h", Frame_Content_Size);
        $display("Extra Byte:             0x%0h", extra_byte);
        $finish;
    end

endmodule
