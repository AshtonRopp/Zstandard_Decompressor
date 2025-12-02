module tb_Block_Header_Parser();

    logic clk = 0;
    always #5 clk = ~clk; // Clock toggles every 5ns

    // Other signals
    logic reset;
    logic start;
    logic [15:0] frame_h_data_in;

    logic frame_finished;
    logic [7:0] sizes;
    logic [7:0] Frame_Header_Descriptor;
    logic [7:0] Window_Descriptor;
    logic [31:0] Dictionary_ID;
    logic [63:0] Frame_Content_Size;
    logic [7:0] extra_byte;

    Frame_Header_Parser fhp (
        .clk(clk),
        .reset(reset),
        .start(start),
        .data_in(frame_h_data_in),
        .finished(frame_finished),
        .sizes(sizes),
        .Frame_Header_Descriptor(Frame_Header_Descriptor),
        .Window_Descriptor(Window_Descriptor),
        .Dictionary_ID(Dictionary_ID),
        .Frame_Content_Size(Frame_Content_Size),
        .extra_byte(extra_byte)
    );


    // Inputs
    logic                  in_ready;
    logic [7:0]            in_b0;
    logic [7:0]            in_b1;
    logic [7:0]            in_b2;

    // Outputs
    logic                  header_valid;
    logic                  last_block;
    logic [1:0]            block_type;
    logic [20:0]           block_size;
    logic                  reserved_type_err;
    logic                  size_exceed_err;
    logic [7:0] extra_byte_bhp;

    Block_Header_Parser #(
        .WIDTH_BYTE(8),
        .BLOCK_MAX_LIMIT(131072)
    ) bhp (
        .clk              (clk),
        .reset            (reset),

        .in_ready         (in_ready),
        .in_b0            (in_b0),
        .in_b1            (in_b1),
        .in_b2            (in_b2),

        .header_valid     (header_valid),
        .last_block       (last_block),
        .block_type       (block_type),
        .block_size       (block_size),

        .reserved_type_err(reserved_type_err),
        .size_exceed_err  (size_exceed_err)
    );



    logic [15:0] rom [0:31];
    integer i;
    integer block_cnt = 0;

    initial begin
        $display("Starting Frame_Header_Parser test...");
        $readmemh("input.data", rom);

        reset = 1;
        start = 0;
        frame_h_data_in = 16'h0000;

        // Block Header signals
        in_ready = 0;
        in_b0 = 8'd0;
        in_b1 = 8'd0;
        in_b2 = 8'd0;

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

            // Assuming no extra byte, this logic would have to change otherwise
            if (frame_finished) begin
                start = 0;
                frame_h_data_in = 16'bx;
                in_b0 = rom[i-1][15:8];
                in_b1 = rom[i-1][7:0];
                block_cnt = 1;
            end
            else if (block_cnt == 1) begin
                in_ready = 1;
                in_b2 = rom[i-1][15:8];
                extra_byte_bhp = rom[i-1][7:0];
                block_cnt = 2;
            end
            else if (header_valid && block_cnt == 2) begin
                break;
            end
            else begin
                frame_h_data_in = rom[i];
            end
        end

        $display("==== Results ====");
        $display("Sizes:                   0x%0h", sizes);
        $display("Frame Header Descriptor: 0x%0h", Frame_Header_Descriptor);
        $display("Window Descriptor:       0x%0h", Window_Descriptor);
        $display("Dictionary ID:           0x%0h", Dictionary_ID);
        $display("Frame Content Size:      0x%0h", Frame_Content_Size);
        $display("Extra Byte:              0x%0h", extra_byte);
        $display("Warning: these results do NOT preserve trailing 0s");
        $finish;

    end

endmodule
