// Block_Header_Parser.sv
// SystemVerilog module to parse a Zstandard Block_Header (3 bytes, little-endian)

module Block_Header_Parser #(
    parameter int WIDTH_BYTE = 8,
    parameter int BLOCK_MAX_LIMIT = 131072
) (
    input  logic                  clk,
    input  logic                  reset,

    // Input: all three bytes at once, little-endian
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [WIDTH_BYTE-1:0] in_b0,
    input  logic [WIDTH_BYTE-1:0] in_b1,
    input  logic [WIDTH_BYTE-1:0] in_b2,

    // Output parsed header (pulsed when header_valid)
    output logic                 header_valid,
    output logic                 last_block,
    output logic [1:0]           block_type,
    output logic [20:0]          block_size,
    output logic [23:0]          raw_header,

    // Error flags
    output logic                 reserved_type_err,
    output logic                 size_exceed_err
);

    assign in_ready = 1'b1; // always ready

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            header_valid <= 1'b0;
            last_block <= 1'b0;
            block_type <= 2'b00;
            block_size <= 21'd0;
            raw_header <= 24'd0;
            reserved_type_err <= 1'b0;
            size_exceed_err <= 1'b0;
        end else if (in_valid && in_ready) begin
            // Assemble little-endian 24-bit header
            raw_header <= {in_b2, in_b1, in_b0};

            // Extract fields
            last_block <= in_b0[0];
            block_type <= in_b0[2:1];
            block_size <= {in_b2, in_b1, in_b0} >> 3;

            // Error flags
            reserved_type_err <= (in_b0[2:1] == 2'b11);
            size_exceed_err <= (({in_b2,in_b1,in_b0} >> 3) > BLOCK_MAX_LIMIT);

            header_valid <= 1'b1; // pulse high one cycle
        end else begin
            header_valid <= 1'b0;
            reserved_type_err <= 1'b0;
            size_exceed_err <= 1'b0;
        end
    end

endmodule
