module tb_Header_Parser();

    logic clk = 0;
    always #5 clk = ~clk; // Clock toggles every 5ns

    // Other signals
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

    logic [15:0] rom [0:31];
    integer i;

    initial begin
        $display("Starting Header_Parser test...");
        $readmemh("input.data", rom);

        reset = 1;
        start = 0;
        data_in = 16'h0000;
        repeat (2) @(posedge clk);
        reset = 0;

        for (i = 0; i < 32; i++) begin
            @(posedge clk);
            if(i == 1) begin
                start = 0;
            end
            if (i == 0) begin
                start = 1;
            end
            data_in = rom[i];
            if (finished) begin
                break;
            end
        end

        // repeat (10) @(posedge clk);

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
