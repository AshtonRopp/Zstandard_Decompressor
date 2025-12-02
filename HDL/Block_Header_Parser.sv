// Block_Header_Parser.sv
// SystemVerilog module to parse a Zstandard Block_Header (3 bytes, little-endian)

module Block_Header_Parser #(
    parameter int WIDTH_BYTE = 8,
    parameter int BLOCK_MAX_LIMIT = 131072
) (
    input  logic                  clk,
    input  logic                  reset,

    // Input: all three bytes at once, little-endian
    input  logic                  in_ready,
    input  logic [WIDTH_BYTE-1:0] in_b0,
    input  logic [WIDTH_BYTE-1:0] in_b1,
    input  logic [WIDTH_BYTE-1:0] in_b2,

    // Output parsed header (pulsed when header_valid)
    output logic                 header_valid,
    output logic                 last_block,
    output logic [1:0]           block_type,
    output logic [20:0]          block_size,

    // Error flags
    output logic                 reserved_type_err,
    output logic                 size_exceed_err
);

    // Enum for block types
    typedef enum logic [1:0] {
        RAW_BLOCK        = 2'b00,
        RLE_BLOCK        = 2'b01,
        COMPRESSED_BLOCK = 2'b10,
        RESERVED_BLOCK   = 2'b11
    } block_type_e;


    // Assemble 24-bit header as it appears in memory
    logic [23:0] raw_header;
    assign raw_header = {in_b0, in_b1, in_b2};

    logic [23:0] little_endian_header;
    assign little_endian_header = {raw_header[ 7: 4], raw_header[ 3: 0],
                                   raw_header[15:12], raw_header[11: 8],
                                   raw_header[23:20], raw_header[19:16]};

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            header_valid <= 1'b0;
            last_block <= 1'b0;
            block_type <= RAW_BLOCK;
            block_size <= 21'd0;
            reserved_type_err <= 1'b0;
            size_exceed_err <= 1'b0;
        end else if (in_ready) begin

            // Extract fields
            last_block <= little_endian_header[0];
            block_type <= little_endian_header[2:1];
            block_size <= little_endian_header[23:3];

            // Error flags
            reserved_type_err <= (in_b0[2:1] == RESERVED_BLOCK);
            size_exceed_err <= (({in_b2,in_b1,in_b0} >> 3) > BLOCK_MAX_LIMIT);

            header_valid <= 1'b1; // pulse high one cycle
        end else begin
            header_valid <= 1'b0;
            reserved_type_err <= 1'b0;
            size_exceed_err <= 1'b0;
        end
    end

endmodule
