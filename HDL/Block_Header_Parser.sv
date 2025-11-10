// Block_Header_Parser.sv
// SystemVerilog module to parse a Zstandard Block_Header (3 bytes, little-endian)

module Block_Header_Parser #(
    parameter int WIDTH_BYTE = 8,
    parameter int BLOCK_MAX_LIMIT = 131072
) (
    input  logic                  clk,
    input  logic                  reset,

    // Input byte stream interface
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [WIDTH_BYTE-1:0] in_byte,

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

    // Internal registers for 3-byte accumulation
    logic [WIDTH_BYTE-1:0] b0, b1, b2;
    logic [1:0] byte_cnt;

    assign in_ready = 1'b1; // always ready to accept bytes

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_cnt <= 2'd0;
            b0 <= 8'd0; b1 <= 8'd0; b2 <= 8'd0;
            header_valid <= 1'b0;
            last_block <= 1'b0;
            block_type <= 2'b00;
            block_size <= 21'd0;
            raw_header <= 24'd0;
            reserved_type_err <= 1'b0;
            size_exceed_err <= 1'b0;
        end else begin
            header_valid <= 1'b0; // default
            reserved_type_err <= 1'b0;
            size_exceed_err <= 1'b0;

            if (in_valid && in_ready) begin
                case (byte_cnt)
                    2'd0: begin
                        b0 <= in_byte;
                        byte_cnt <= 2'd1;
                    end
                    2'd1: begin
                        b1 <= in_byte;
                        byte_cnt <= 2'd2;
                    end
                    2'd2: begin
                        b2 <= in_byte;
                        byte_cnt <= 2'd0;

                        // Assemble little-endian 24-bit header
                        raw_header <= {in_byte, b1, b0};

                        // Extract fields
                        last_block <= b0[0];                // bit 0 of first byte
                        block_type <= b0[2:1];              // bits 1-2 of first byte
                        block_size <= {b2, b1, b0} >> 3;    // upper 21 bits (bits 3-23)

                        // Error flags
                        reserved_type_err <= (b0[2:1] == 2'b11);
                        size_exceed_err <= (({b2,b1,b0} >> 3) > BLOCK_MAX_LIMIT);

                        header_valid <= 1'b1; // pulse high one cycle
                    end
                endcase
            end
        end
    end

endmodule
