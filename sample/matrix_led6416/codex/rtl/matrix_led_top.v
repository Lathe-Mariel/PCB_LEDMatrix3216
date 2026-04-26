module matrix_led_top (
    input  wire clk,
    input  wire USER_KEY,
    output reg  SIN1,
    output reg  SIN2,
    output reg  SIN3,
    output reg  LATCH,
    output reg  LED_CLK,
    output reg  STROBE_
);

    localparam integer CLK_HZ           = 50_000_000;
    localparam integer DISPLAY_ROWS     = 16;
    localparam integer DISPLAY_COLS     = 64;
    localparam integer FONT_W           = 8;
    localparam integer FONT_H           = 8;
    localparam integer CHAR_STRIDE      = 9;
    localparam integer MSG_LEN          = 28;
    localparam integer TEXT_COLUMNS     = MSG_LEN * CHAR_STRIDE;
    localparam integer SCROLL_SPAN      = TEXT_COLUMNS + DISPLAY_COLS;
    localparam integer SCROLL_TICK_CYC  = CLK_HZ / 10;
    localparam integer BASE_ON_TICKS    = 5_000;

    localparam integer STATE_LOAD        = 0;
    localparam integer STATE_SHIFT_SETUP = 1;
    localparam integer STATE_SHIFT_HIGH  = 2;
    localparam integer STATE_SHIFT_LOW   = 3;
    localparam integer STATE_LATCH_ON    = 4;
    localparam integer STATE_LATCH_OFF   = 5;
    localparam integer STATE_HOLD        = 6;

    localparam integer ROW0_IS_TOP       = 1;
    localparam integer COL0_IS_LEFT      = 1;
    localparam integer SHIFT_MSB_FIRST   = 1;

    reg [2:0]  state;
    reg        plane_sel;
    reg [3:0]  scan_row;
    reg [5:0]  bit_index;
    reg [31:0] row_shift_word;
    reg [31:0] col_shift_word_sin2;
    reg [31:0] col_shift_word_sin3;
    reg [13:0] hold_count;
    reg [22:0] scroll_tick_count;
    reg [8:0]  scroll_offset;

    function [31:0] row_word_for;
        input [3:0] row_idx;
        integer panel_row;
        reg [15:0] one_hot_row;
        begin
            one_hot_row = 16'd0;
            panel_row = ROW0_IS_TOP ? row_idx : (DISPLAY_ROWS - 1 - row_idx);
            one_hot_row[panel_row] = 1'b1;
            row_word_for = {one_hot_row, one_hot_row};
        end
    endfunction

    function serial_pick32;
        input [31:0] word;
        input [5:0] idx;
        begin
            if (SHIFT_MSB_FIRST != 0) begin
                serial_pick32 = word[idx];
            end else begin
                serial_pick32 = word[31 - idx];
            end
        end
    endfunction

    function [7:0] message_char;
        input integer index;
        begin
            case (index)
                0:  message_char = "S";
                1:  message_char = "t";
                2:  message_char = "a";
                3:  message_char = "n";
                4:  message_char = "f";
                5:  message_char = "o";
                6:  message_char = "r";
                7:  message_char = "d";
                8:  message_char = " ";
                9:  message_char = "U";
                10: message_char = "n";
                11: message_char = "i";
                12: message_char = "v";
                13: message_char = "e";
                14: message_char = "r";
                15: message_char = "s";
                16: message_char = "i";
                17: message_char = "t";
                18: message_char = "y";
                19: message_char = " ";
                20: message_char = "N";
                21: message_char = "e";
                22: message_char = "t";
                23: message_char = "w";
                24: message_char = "o";
                25: message_char = "r";
                26: message_char = "k";
                27: message_char = ".";
                default: message_char = " ";
            endcase
        end
    endfunction

    function [7:0] font_row_bits;
        input [7:0] ch;
        input [2:0] row;
        begin
            font_row_bits = 8'b00000000;
            case (ch)
                " ": begin
                    font_row_bits = 8'b00000000;
                end
                ",": begin
                    case (row)
                        3'd5: font_row_bits = 8'b00011000;
                        3'd6: font_row_bits = 8'b00011000;
                        3'd7: font_row_bits = 8'b00110000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                ".": begin
                    case (row)
                        3'd5: font_row_bits = 8'b00011000;
                        3'd6: font_row_bits = 8'b00011000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "N": begin
                    case (row)
                        3'd0: font_row_bits = 8'b01000010;
                        3'd1: font_row_bits = 8'b01100010;
                        3'd2: font_row_bits = 8'b01010010;
                        3'd3: font_row_bits = 8'b01001010;
                        3'd4: font_row_bits = 8'b01000110;
                        3'd5: font_row_bits = 8'b01000010;
                        3'd6: font_row_bits = 8'b01000010;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "S": begin
                    case (row)
                        3'd0: font_row_bits = 8'b00111110;
                        3'd1: font_row_bits = 8'b01000000;
                        3'd2: font_row_bits = 8'b01000000;
                        3'd3: font_row_bits = 8'b00111100;
                        3'd4: font_row_bits = 8'b00000010;
                        3'd5: font_row_bits = 8'b00000010;
                        3'd6: font_row_bits = 8'b01111100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "U": begin
                    case (row)
                        3'd0: font_row_bits = 8'b01000010;
                        3'd1: font_row_bits = 8'b01000010;
                        3'd2: font_row_bits = 8'b01000010;
                        3'd3: font_row_bits = 8'b01000010;
                        3'd4: font_row_bits = 8'b01000010;
                        3'd5: font_row_bits = 8'b01000010;
                        3'd6: font_row_bits = 8'b00111100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "W": begin
                    case (row)
                        3'd0: font_row_bits = 8'b10000001;
                        3'd1: font_row_bits = 8'b10000001;
                        3'd2: font_row_bits = 8'b10000001;
                        3'd3: font_row_bits = 8'b10011001;
                        3'd4: font_row_bits = 8'b10011001;
                        3'd5: font_row_bits = 8'b10100101;
                        3'd6: font_row_bits = 8'b11000011;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "a": begin
                    case (row)
                        3'd1: font_row_bits = 8'b00111100;
                        3'd2: font_row_bits = 8'b00000100;
                        3'd3: font_row_bits = 8'b00111100;
                        3'd4: font_row_bits = 8'b01000100;
                        3'd5: font_row_bits = 8'b01001100;
                        3'd6: font_row_bits = 8'b00110100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "c": begin
                    case (row)
                        3'd1: font_row_bits = 8'b00111000;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01000000;
                        3'd4: font_row_bits = 8'b01000000;
                        3'd5: font_row_bits = 8'b01000100;
                        3'd6: font_row_bits = 8'b00111000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "d": begin
                    case (row)
                        3'd0: font_row_bits = 8'b00000100;
                        3'd1: font_row_bits = 8'b00000100;
                        3'd2: font_row_bits = 8'b00110100;
                        3'd3: font_row_bits = 8'b01001100;
                        3'd4: font_row_bits = 8'b01000100;
                        3'd5: font_row_bits = 8'b01000100;
                        3'd6: font_row_bits = 8'b00111100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "e": begin
                    case (row)
                        3'd1: font_row_bits = 8'b00111000;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01111100;
                        3'd4: font_row_bits = 8'b01000000;
                        3'd5: font_row_bits = 8'b01000100;
                        3'd6: font_row_bits = 8'b00111000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "f": begin
                    case (row)
                        3'd0: font_row_bits = 8'b00001100;
                        3'd1: font_row_bits = 8'b00010000;
                        3'd2: font_row_bits = 8'b00111100;
                        3'd3: font_row_bits = 8'b00010000;
                        3'd4: font_row_bits = 8'b00010000;
                        3'd5: font_row_bits = 8'b00010000;
                        3'd6: font_row_bits = 8'b00010000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "h": begin
                    case (row)
                        3'd0: font_row_bits = 8'b01000000;
                        3'd1: font_row_bits = 8'b01000000;
                        3'd2: font_row_bits = 8'b01011000;
                        3'd3: font_row_bits = 8'b01100100;
                        3'd4: font_row_bits = 8'b01000100;
                        3'd5: font_row_bits = 8'b01000100;
                        3'd6: font_row_bits = 8'b01000100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "i": begin
                    case (row)
                        3'd0: font_row_bits = 8'b00010000;
                        3'd2: font_row_bits = 8'b00110000;
                        3'd3: font_row_bits = 8'b00010000;
                        3'd4: font_row_bits = 8'b00010000;
                        3'd5: font_row_bits = 8'b00010000;
                        3'd6: font_row_bits = 8'b00111000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "k": begin
                    case (row)
                        3'd0: font_row_bits = 8'b01000000;
                        3'd1: font_row_bits = 8'b01001000;
                        3'd2: font_row_bits = 8'b01010000;
                        3'd3: font_row_bits = 8'b01100000;
                        3'd4: font_row_bits = 8'b01010000;
                        3'd5: font_row_bits = 8'b01001000;
                        3'd6: font_row_bits = 8'b01000100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "n": begin
                    case (row)
                        3'd1: font_row_bits = 8'b01111000;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01000100;
                        3'd4: font_row_bits = 8'b01000100;
                        3'd5: font_row_bits = 8'b01000100;
                        3'd6: font_row_bits = 8'b01000100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "o": begin
                    case (row)
                        3'd1: font_row_bits = 8'b00111000;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01000100;
                        3'd4: font_row_bits = 8'b01000100;
                        3'd5: font_row_bits = 8'b01000100;
                        3'd6: font_row_bits = 8'b00111000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "r": begin
                    case (row)
                        3'd1: font_row_bits = 8'b01011000;
                        3'd2: font_row_bits = 8'b01100100;
                        3'd3: font_row_bits = 8'b01000000;
                        3'd4: font_row_bits = 8'b01000000;
                        3'd5: font_row_bits = 8'b01000000;
                        3'd6: font_row_bits = 8'b01000000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "s": begin
                    case (row)
                        3'd1: font_row_bits = 8'b00111100;
                        3'd2: font_row_bits = 8'b01000000;
                        3'd3: font_row_bits = 8'b00111000;
                        3'd4: font_row_bits = 8'b00000100;
                        3'd5: font_row_bits = 8'b01000100;
                        3'd6: font_row_bits = 8'b00111000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "t": begin
                    case (row)
                        3'd0: font_row_bits = 8'b00010000;
                        3'd1: font_row_bits = 8'b00010000;
                        3'd2: font_row_bits = 8'b00111100;
                        3'd3: font_row_bits = 8'b00010000;
                        3'd4: font_row_bits = 8'b00010000;
                        3'd5: font_row_bits = 8'b00010100;
                        3'd6: font_row_bits = 8'b00001000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "u": begin
                    case (row)
                        3'd1: font_row_bits = 8'b01000100;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01000100;
                        3'd4: font_row_bits = 8'b01000100;
                        3'd5: font_row_bits = 8'b01001100;
                        3'd6: font_row_bits = 8'b00110100;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "v": begin
                    case (row)
                        3'd1: font_row_bits = 8'b01000100;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01000100;
                        3'd4: font_row_bits = 8'b00101000;
                        3'd5: font_row_bits = 8'b00101000;
                        3'd6: font_row_bits = 8'b00010000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "w": begin
                    case (row)
                        3'd1: font_row_bits = 8'b01000100;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01010100;
                        3'd4: font_row_bits = 8'b01010100;
                        3'd5: font_row_bits = 8'b01010100;
                        3'd6: font_row_bits = 8'b00101000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                "y": begin
                    case (row)
                        3'd1: font_row_bits = 8'b01000100;
                        3'd2: font_row_bits = 8'b01000100;
                        3'd3: font_row_bits = 8'b01000100;
                        3'd4: font_row_bits = 8'b00111100;
                        3'd5: font_row_bits = 8'b00000100;
                        3'd6: font_row_bits = 8'b00111000;
                        default: font_row_bits = 8'b00000000;
                    endcase
                end
                default: begin
                    font_row_bits = 8'b00000000;
                end
            endcase
        end
    endfunction

    function [1:0] pixel_gray;
        input integer screen_col;
        input [3:0] row_idx;
        input [8:0] scroll_pos;
        integer text_x;
        integer cell_index;
        integer x_in_cell;
        reg [7:0] ch;
        reg [7:0] glyph_row;
        begin
            pixel_gray = 2'd0;
            text_x = screen_col + scroll_pos - DISPLAY_COLS;
            if ((text_x >= 0) && (text_x < TEXT_COLUMNS) && (row_idx < DISPLAY_ROWS)) begin
                cell_index = text_x / CHAR_STRIDE;
                x_in_cell = text_x % CHAR_STRIDE;
                if ((cell_index < MSG_LEN) && (x_in_cell < FONT_W)) begin
                    ch = message_char(cell_index);
                    glyph_row = font_row_bits(ch, row_idx[3:1]);
                    if (glyph_row[7 - x_in_cell]) begin
                        pixel_gray = 2'd3;
                    end
                end
            end
        end
    endfunction

    function [31:0] column_word_sin2_for;
        input [3:0] row_idx;
        input       plane;
        input [8:0] scroll_pos;
        integer col;
        integer panel_col;
        integer lane_bit;
        reg [1:0] gray;
        begin
            column_word_sin2_for = 32'd0;
            for (col = 0; col < DISPLAY_COLS; col = col + 1) begin
                panel_col = COL0_IS_LEFT ? col : (DISPLAY_COLS - 1 - col);
                gray = pixel_gray(col, row_idx, scroll_pos);
                if (gray[plane]) begin
                    if ((panel_col >= 16) && (panel_col < 32)) begin
                        lane_bit = panel_col - 16;
                        column_word_sin2_for[lane_bit] = 1'b1;
                    end else if (panel_col >= 48) begin
                        lane_bit = panel_col - 32;
                        column_word_sin2_for[lane_bit] = 1'b1;
                    end
                end
            end
        end
    endfunction

    function [31:0] column_word_sin3_for;
        input [3:0] row_idx;
        input       plane;
        input [8:0] scroll_pos;
        integer col;
        integer panel_col;
        integer lane_bit;
        reg [1:0] gray;
        begin
            column_word_sin3_for = 32'd0;
            for (col = 0; col < DISPLAY_COLS; col = col + 1) begin
                panel_col = COL0_IS_LEFT ? col : (DISPLAY_COLS - 1 - col);
                gray = pixel_gray(col, row_idx, scroll_pos);
                if (gray[plane]) begin
                    if (panel_col < 16) begin
                        lane_bit = panel_col;
                        column_word_sin3_for[lane_bit] = 1'b1;
                    end else if ((panel_col >= 32) && (panel_col < 48)) begin
                        lane_bit = panel_col - 16;
                        column_word_sin3_for[lane_bit] = 1'b1;
                    end
                end
            end
        end
    endfunction

    always @(posedge clk or negedge USER_KEY) begin
        if (!USER_KEY) begin
            state             <= STATE_LOAD;
            plane_sel         <= 1'b0;
            scan_row          <= 4'd0;
            bit_index         <= 6'd31;
            row_shift_word    <= 32'd0;
            col_shift_word_sin2 <= 32'd0;
            col_shift_word_sin3 <= 32'd0;
            hold_count        <= 14'd0;
            scroll_tick_count <= 23'd0;
            scroll_offset     <= 9'd0;
            SIN1              <= 1'b0;
            SIN2              <= 1'b0;
            SIN3              <= 1'b0;
            LATCH             <= 1'b0;
            LED_CLK           <= 1'b0;
            STROBE_           <= 1'b1;
        end else begin
            if (scroll_tick_count == SCROLL_TICK_CYC - 1) begin
                scroll_tick_count <= 23'd0;
                if (scroll_offset == SCROLL_SPAN - 1) begin
                    scroll_offset <= 9'd0;
                end else begin
                    scroll_offset <= scroll_offset + 9'd1;
                end
            end else begin
                scroll_tick_count <= scroll_tick_count + 23'd1;
            end

            case (state)
                STATE_LOAD: begin
                    STROBE_        <= 1'b1;
                    LATCH          <= 1'b0;
                    LED_CLK        <= 1'b0;
                    SIN1           <= 1'b0;
                    SIN2           <= 1'b0;
                    SIN3           <= 1'b0;
                    row_shift_word <= row_word_for(scan_row);
                    col_shift_word_sin2 <= column_word_sin2_for(scan_row, plane_sel, scroll_offset);
                    col_shift_word_sin3 <= column_word_sin3_for(scan_row, plane_sel, scroll_offset);
                    bit_index      <= 6'd31;
                    state          <= STATE_SHIFT_SETUP;
                end

                STATE_SHIFT_SETUP: begin
                    LED_CLK <= 1'b0;
                    SIN1    <= serial_pick32(row_shift_word, bit_index);
                    SIN2    <= serial_pick32(col_shift_word_sin2, bit_index);
                    SIN3    <= serial_pick32(col_shift_word_sin3, bit_index);
                    state   <= STATE_SHIFT_HIGH;
                end

                STATE_SHIFT_HIGH: begin
                    LED_CLK <= 1'b1;
                    state   <= STATE_SHIFT_LOW;
                end

                STATE_SHIFT_LOW: begin
                    LED_CLK <= 1'b0;
                    if (bit_index == 0) begin
                        state <= STATE_LATCH_ON;
                    end else begin
                        bit_index <= bit_index - 6'd1;
                        state     <= STATE_SHIFT_SETUP;
                    end
                end

                STATE_LATCH_ON: begin
                    LATCH <= 1'b1;
                    state <= STATE_LATCH_OFF;
                end

                STATE_LATCH_OFF: begin
                    LATCH    <= 1'b0;
                    STROBE_  <= 1'b0;
                    hold_count <= plane_sel ? ((BASE_ON_TICKS << 1) - 1) : (BASE_ON_TICKS - 1);
                    state    <= STATE_HOLD;
                end

                STATE_HOLD: begin
                    if (hold_count == 0) begin
                        STROBE_ <= 1'b1;
                        if (scan_row == DISPLAY_ROWS - 1) begin
                            scan_row  <= 4'd0;
                            plane_sel <= ~plane_sel;
                        end else begin
                            scan_row <= scan_row + 4'd1;
                        end
                        state <= STATE_LOAD;
                    end else begin
                        hold_count <= hold_count - 14'd1;
                    end
                end

                default: begin
                    state <= STATE_LOAD;
                end
            endcase
        end
    end

endmodule
