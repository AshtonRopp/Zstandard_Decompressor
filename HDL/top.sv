module Header_Parser (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [15:0] data_in,       // 2 bytes per cycle

    output logic        finished,
);

    typedef enum logic [2:0] {
        IDLE,
        READ_MAGIC_NUMBER,
        READ_FRAME_HEADER_DESCRIPTOR,
        READ_WINDOW_DESCRIPTOR,
        READ_DICTIONARY_ID,
        READ_FRAME_CONTENT_SIZE,
        DONE
    } state_t;

    state_t state, next_state;
    logic [31:0] magic_buffer;
    logic [2:0]  byte_index;

    logic [1:0] Frame_Content_Size_flag, Dictionary_ID_flag;
    logic Single_Segment_flag, Content_Checksum_flag;

    logic Window_Descriptor_Bytes;
    logic [2:0] Dictionary_ID_Bytes
    logic [3:0] Frame_Content_Size_Bytes;

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
            if (start && state == IDLE) begin
                magic_buffer[7:0] <= data_in[15:8];
                magic_buffer[15:8] <= data_in[7:0];
                Window_Descriptor_Bytes <= 0;
                Dictionary_ID_Bytes <= 3'b0;
                Frame_Content_Size_Bytes <= 4'b0;
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

                // Find the remaining number of bytes

                Window_Descriptor_Bytes <= !(data_in[5]);

                // Dictionary_ID_flag
                case (data_in[1:0])
                    2'b00: begin
                        Dictionary_ID_Bytes <= 3'd0;
                    end
                    2'b01: begin
                        Dictionary_ID_Bytes <= 3'd1;
                    end
                    2'b10: begin
                        Dictionary_ID_Bytes <= 3'd2;
                    end
                    2'b11: begin
                        Dictionary_ID_Bytes <= 3'd4;
                    end
                endcase

                // Frame_Content_Size_flag
                case (data_in[7:6])
                    2'b00: begin
                        Frame_Content_Size_Bytes <= {3'b0, data_in[5]}; // Single_Segment_flag
                    end
                    2'b01: begin
                        Frame_Content_Size_Bytes <= 4'd2;
                    end
                    2'b10: begin
                        Frame_Content_Size_Bytes <= 4'd4;
                    end
                    2'b11: begin
                        Frame_Content_Size_Bytes <= 4'd8;
                    end
                endcase

                // TODO: do next available byte here


            end
        end
    end
endmodule
