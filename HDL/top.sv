module Header_Parser (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [15:0] data_in,       // 2 bytes per cycle

    output logic        finished,
    output logic [ 7:0] sizes, // {window bytes, dictionary ID bytes, FCS bytes}
    output logic [ 7:0] Frame_Header_Descriptor, // 1 byte
    output logic [ 7:0] Window_Descriptor,       // 0-1 bytes
    output logic [31:0] Dictionary_ID,           // 0-4 bytes
    output logic [63:0] Frame_Content_Size,      // 0-8 bytes
    output logic [ 7:0] extra_byte // Unused byte, sent back to system for processing
);

    typedef enum logic [2:0] {
        IDLE,
        READ_MAGIC_NUMBER,
        READ_FRAME_HEADER_DESCRIPTOR,
        READ_REMAINING_BYTES
    } state_t;

    state_t state, next_state;
    logic [31:0] magic_buffer;
    logic [2:0]  byte_index;

    logic [1:0] Frame_Content_Size_flag, Dictionary_ID_flag;
    logic Single_Segment_flag, Content_Checksum_flag;

    logic Window_Descriptor_Bytes;
    logic [2:0] Dictionary_ID_Bytes
    logic [3:0] Frame_Content_Size_Bytes;

    logic [4:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            byte_index   <= 0;
            magic_buffer <= 0;
            magic_valid  <= 0;
            window_log   <= 0;
            finished     <= 0;
        end
        else begin
            state <= next_state;
            if (state == IDLE) begin
                if (start) begin
                    magic_buffer[7:0] <= data_in[15:8];
                    magic_buffer[15:8] <= data_in[7:0];
                end
                Window_Descriptor_Bytes <= 1'b0;
                Dictionary_ID_Bytes <= 3'b0;
                Frame_Content_Size_Bytes <= 4'b0;
                count <= 4'b0;
                sizes <= 1'b0;
                extra_byte <= 8'b0;
            end
            else if (state == READ_MAGIC_NUMBER) begin
                magic_buffer[23:16] <= data_in[15:8];
                magic_buffer[31:24] <= data_in[7:0];
            end
            else if (state == READ_FRAME_HEADER_DESCRIPTOR) begin
                Frame_Content_Size_flag <= data_in[7:6];
                Single_Segment_flag <= data_in[5];
                Content_Checksum_flag <= data_in[2];
                Dictionary_ID_flag <= data_in[1:0];

                Frame_Header_Descriptor <= data_in[7:0];

                // Find the remaining number of bytes
                // Read Window_Descriptor_Bytes if present
                if (!(data_in[5])) begin
                    Window_Descriptor_Bytes <= 1;
                    Window_Descriptor <= data_in[15:8];
                    sizes[7] <= 1;
                end

                // Dictionary_ID_flag   
                case (data_in[1:0])
                    2'b00: begin
                        Dictionary_ID_Bytes <= 3'd0;
                    end
                    2'b01: begin
                        Dictionary_ID_Bytes <= 3'd1;
                        sizes[6:4] <= 3'd1;
                    end
                    2'b10: begin
                        Dictionary_ID_Bytes <= 3'd2;
                        sizes[6:4] <= 3'd2;
                    end
                    2'b11: begin
                        Dictionary_ID_Bytes <= 3'd4;
                        sizes[6:4] <= 3'd4;
                    end
                endcase


                if (data_in[5] && (data_in[1:0] != 2'b00)) begin
                    Dictionary_ID[7:0] <= data_in[15:8];
                end

                // Frame_Content_Size_flag
                case (data_in[7:6])
                    2'b00: begin
                        Frame_Content_Size_Bytes <= {3'b0, data_in[5]}; // Single_Segment_flag\
                        sizes[3:0] <= {3'b0, data_in[5]};
                    end
                    2'b01: begin
                        Frame_Content_Size_Bytes <= 4'd2;
                        sizes[3:0] <= 4'd2;
                    end
                    2'b10: begin
                        Frame_Content_Size_Bytes <= 4'd4;
                        sizes[3:0] <= 4'd4;
                    end
                    2'b11: begin
                        Frame_Content_Size_Bytes <= 4'd8;
                        sizes[3:0] <= 4'd8;
                    end
                endcase

                // Read this if no Window_Descriptor_Bytes or Frame_Content_Size_Bytes available to read
                if (data_in[5] && (data_in[1:0] == 2'b00) && (data_in[7:6] != 2'b00)) begin
                    Frame_Content_Size[7:0] <= data_in[15:8];
                end

                // First non-header byte has been read
                count <= 1;

            end

            else if (state == READ_REMAINING_BYTES) begin
                // Read Dictionary_ID_Bytes: Convert from little endian
                if (Window_Descriptor_Bytes + Dictionary_ID_Bytes > count) begin

                    case (count - Window_Descriptor_Bytes)
                        2'b00: begin
                            Dictionary_ID[7:0] <= data_in[7:0];
                        end
                        2'b01: begin
                            Dictionary_ID[15:8] <= data_in[7:0];
                        end
                        2'b10: begin
                            Dictionary_ID[23:16] <= data_in[7:0];
                        end
                        2'b11: begin
                            Dictionary_ID[31:24] <= data_in[7:0];
                        end
                    endcase

                    // Handle these cases here: Dict-Dict, Dict-FCS, Dict-Nothing

                    // Dict-Dict
                    if (Window_Descriptor_Bytes + Dictionary_ID_Bytes > count + 1) begin

                        case (count + 1 - Window_Descriptor_Bytes)
                            2'b00: begin
                                // Should not be reached
                            end
                            2'b01: begin
                                Dictionary_ID[15:8] <= data_in[15:8];
                            end
                            2'b10: begin
                                Dictionary_ID[23:16] <= data_in[15:8];
                            end
                            2'b11: begin
                                Dictionary_ID[31:24] <= data_in[15:8];
                            end
                        endcase
                    end
                    // Dict-FCS
                    else if (Window_Descriptor_Bytes + Dictionary_ID_Bytes + Frame_Content_Size_Bytes > count + 1) begin
                        case (count + 1 - Window_Descriptor_Bytes - Dictionary_ID_Bytes)
                            3'b000: begin
                                Frame_Content_Size[7:0] <= data_in[15:8];
                            end
                            3'b001: begin
                                Frame_Content_Size[15:8] <= data_in[15:8];
                            end
                            3'b010: begin
                                Frame_Content_Size[23:16] <= data_in[15:8];
                            end
                            3'b011: begin
                                Frame_Content_Size[31:24] <= data_in[15:8];
                            end
                            3'b100: begin
                                Frame_Content_Size[39:32] <= data_in[15:8];
                            end
                            3'b101: begin
                                Frame_Content_Size[47:40] <= data_in[15:8];
                            end
                            3'b110: begin
                                Frame_Content_Size[55:48] <= data_in[15:8];
                            end
                            3'b111: begin
                                Frame_Content_Size[63:56] <= data_in[15:8];
                            end
                        endcase
                    end

                    // Dict-Nothing
                    else begin
                        extra_byte <= data_in[15:8];
                    end
                end

                // FCS-FCS and FCS-Nothing cases
                else if (Window_Descriptor_Bytes + Dictionary_ID_Bytes + Frame_Content_Size_Bytes > count) begin
                    case (count - Window_Descriptor_Bytes - Dictionary_ID_Bytes)
                       3'b000: begin
                            Frame_Content_Size[7:0] <= data_in[7:0];
                        end
                        3'b001: begin
                            Frame_Content_Size[15:8] <= data_in[7:0];
                        end
                        3'b010: begin
                            Frame_Content_Size[23:16] <= data_in[7:0];
                        end
                        3'b011: begin
                            Frame_Content_Size[31:24] <= data_in[7:0];
                        end
                        3'b100: begin
                            Frame_Content_Size[39:32] <= data_in[7:0];
                        end
                        3'b101: begin
                            Frame_Content_Size[47:40] <= data_in[7:0];
                        end
                        3'b110: begin
                            Frame_Content_Size[55:48] <= data_in[7:0];
                        end
                        3'b111: begin
                            Frame_Content_Size[63:56] <= data_in[7:0];
                        end
                    endcase

                    // FCS-FCS
                    if (Window_Descriptor_Bytes + Dictionary_ID_Bytes + Frame_Content_Size_Bytes > count + 1) begin
                        case (count + 1 - Window_Descriptor_Bytes - Dictionary_ID_Bytes)
                            3'b000: begin
                                Frame_Content_Size[7:0] <= data_in[15:8];
                            end
                            3'b001: begin
                                Frame_Content_Size[15:8] <= data_in[15:8];
                            end
                            3'b010: begin
                                Frame_Content_Size[23:16] <= data_in[15:8];
                            end
                            3'b011: begin
                                Frame_Content_Size[31:24] <= data_in[15:8];
                            end
                            3'b100: begin
                                Frame_Content_Size[39:32] <= data_in[15:8];
                            end
                            3'b101: begin
                                Frame_Content_Size[47:40] <= data_in[15:8];
                            end
                            3'b110: begin
                                Frame_Content_Size[55:48] <= data_in[15:8];
                            end
                            3'b111: begin
                                Frame_Content_Size[63:56] <= data_in[15:8];
                            end
                        endcase
                    end
                    // FCS-Nothing
                    else begin
                        extra_byte <= data_in[15:8];
                    end
                end

                count += 2;
            end
        end
    end

    typedef enum logic [2:0] {
        IDLE,
        READ_MAGIC_NUMBER,
        READ_FRAME_HEADER_DESCRIPTOR,
        READ_REMAINING_BYTES
    } state_t;

    assign finished = counter >= Window_Descriptor_Bytes + Dictionary_ID_Bytes + Frame_Content_Size_Bytes;
    always_comb begin
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = READ_MAGIC_NUMBER;
                end
            end
            READ_MAGIC_NUMBER: begin
                next_state = READ_FRAME_HEADER_DESCRIPTOR;
            end
            READ_FRAME_HEADER_DESCRIPTOR: begin
                next_state = READ_REMAINING_BYTES;
            end
            READ_REMAINING_BYTES: begin
                if (finished) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ_REMAINING_BYTES;
                end
            end
        endcase

    end
endmodule

// TODO: analyze power usage for saving calculations of byte index as logic vectors