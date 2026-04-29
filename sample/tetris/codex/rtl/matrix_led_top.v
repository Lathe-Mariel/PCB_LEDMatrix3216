module matrix_led_top (
    input  wire clk,
    input  wire USER_KEY,
    input  wire KEY_LEFT,
    input  wire KEY_RIGHT,
    input  wire KEY_DOWN,
    input  wire BTN_A,
    input  wire BTN_B,
    output reg  SIN1,
    output reg  SIN2,
    output reg  SIN3,
    output reg  LATCH,
    output reg  LED_CLK,
    output reg  STROBE_
);

    localparam integer CLK_HZ            = 50_000_000;
    localparam integer DISPLAY_X         = 16;
    localparam integer DISPLAY_Y         = 64;
    localparam integer FIELD_W           = 8;
    localparam integer FIELD_H           = 32;
    localparam integer CELL_H            = 1;
    localparam integer PREVIEW_X         = 10;
    localparam integer PREVIEW_Y         = 4;
    localparam integer PREVIEW_W         = 4;
    localparam integer PREVIEW_H         = 4;
    localparam integer SCORE_X           = 10;
    localparam integer SCORE_Y           = 40;
    localparam integer SCORE_W           = 5;
    localparam integer SCORE_DIGITS      = 5;
    localparam integer DIGIT_H           = 3;
    localparam integer DIGIT_STRIDE      = 4;
    localparam integer CONTROL_TICK_CYC  = CLK_HZ / 50;
    localparam integer GRAVITY_TICK_CYC  = CLK_HZ / 2;
    localparam integer BASE_ON_TICKS     = 5_000;
    localparam integer SPAWN_X           = 2;
    localparam integer SPAWN_Y           = 0;

    localparam integer STATE_LOAD        = 0;
    localparam integer STATE_SHIFT_SETUP = 1;
    localparam integer STATE_SHIFT_HIGH  = 2;
    localparam integer STATE_SHIFT_LOW   = 3;
    localparam integer STATE_LATCH_ON    = 4;
    localparam integer STATE_LATCH_OFF   = 5;
    localparam integer STATE_HOLD        = 6;

    localparam integer ROW0_IS_LEFT      = 1;
    localparam integer COL0_IS_TOP       = 1;
    localparam integer SHIFT_MSB_FIRST   = 1;

    reg [2:0]  state;
    reg        plane_sel;
    reg [3:0]  scan_row;
    reg [5:0]  bit_index;
    reg [31:0] row_shift_word;
    reg [31:0] col_shift_word_sin2;
    reg [31:0] col_shift_word_sin3;
    reg [13:0] hold_count;

    reg [19:0] control_count;
    reg [24:0] gravity_count;

    reg        key_left_ff0;
    reg        key_left_ff1;
    reg        key_right_ff0;
    reg        key_right_ff1;
    reg        key_down_ff0;
    reg        key_down_ff1;
    reg        btn_a_ff0;
    reg        btn_a_ff1;
    reg        btn_b_ff0;
    reg        btn_b_ff1;

    reg        key_left_prev;
    reg        key_right_prev;
    reg        btn_a_prev;
    reg        btn_b_prev;

    reg [255:0] board_bits;
    reg [255:0] temp_board_bits;
    reg [255:0] compact_board_bits;
    reg [2:0]   cur_piece;
    reg [2:0]   next_piece;
    reg [1:0]   cur_rot;
    reg signed [4:0] cur_x;
    reg signed [5:0] cur_y;
    reg         game_over;
    reg [16:0]  score_value;
    reg [3:0]   score_d4;
    reg [3:0]   score_d3;
    reg [3:0]   score_d2;
    reg [3:0]   score_d1;
    reg [3:0]   score_d0;
    reg [15:0]  lfsr;

    integer work_x;
    integer work_y;
    integer work_rot;
    integer cell_x;
    integer cell_y;
    integer read_row;
    integer write_row;
    integer clear_count;
    integer new_score;
    integer locked_now;
    integer row_full;

    wire control_pulse;
    wire gravity_pulse;
    wire left_press;
    wire right_press;
    wire rot_r_press;
    wire rot_l_press;
    wire soft_drop_step;
    wire drop_step;

    assign control_pulse = (control_count == CONTROL_TICK_CYC - 1);
    assign gravity_pulse = (gravity_count == GRAVITY_TICK_CYC - 1);

    assign left_press     = control_pulse && key_left_ff1  && !key_left_prev;
    assign right_press    = control_pulse && key_right_ff1 && !key_right_prev;
    assign rot_r_press    = control_pulse && btn_a_ff1     && !btn_a_prev;
    assign rot_l_press    = control_pulse && btn_b_ff1     && !btn_b_prev;
    assign soft_drop_step = control_pulse && key_down_ff1;
    assign drop_step      = gravity_pulse || soft_drop_step;

    function [31:0] row_word_for;
        input [3:0] x_idx;
        integer panel_row;
        reg [15:0] one_hot_row;
        begin
            one_hot_row = 16'd0;
            panel_row = ROW0_IS_LEFT ? x_idx : (DISPLAY_X - 1 - x_idx);
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

    function [15:0] piece_shape;
        input [2:0] piece_id;
        input [1:0] rot;
        begin
            piece_shape = 16'h0000;
            case (piece_id)
                3'd0: begin
                    case (rot)
                        2'd0: piece_shape = 16'b0000_1111_0000_0000;
                        2'd1: piece_shape = 16'b0010_0010_0010_0010;
                        2'd2: piece_shape = 16'b0000_1111_0000_0000;
                        default: piece_shape = 16'b0010_0010_0010_0010;
                    endcase
                end
                3'd1: begin
                    piece_shape = 16'b0000_0110_0110_0000;
                end
                3'd2: begin
                    case (rot)
                        2'd0: piece_shape = 16'b0000_1110_0100_0000;
                        2'd1: piece_shape = 16'b0100_0110_0100_0000;
                        2'd2: piece_shape = 16'b0100_1110_0000_0000;
                        default: piece_shape = 16'b0100_1100_0100_0000;
                    endcase
                end
                3'd3: begin
                    case (rot)
                        2'd0: piece_shape = 16'b0000_0110_1100_0000;
                        2'd1: piece_shape = 16'b0100_0110_0010_0000;
                        2'd2: piece_shape = 16'b0000_0110_1100_0000;
                        default: piece_shape = 16'b0100_0110_0010_0000;
                    endcase
                end
                3'd4: begin
                    case (rot)
                        2'd0: piece_shape = 16'b0000_1100_0110_0000;
                        2'd1: piece_shape = 16'b0010_0110_0100_0000;
                        2'd2: piece_shape = 16'b0000_1100_0110_0000;
                        default: piece_shape = 16'b0010_0110_0100_0000;
                    endcase
                end
                3'd5: begin
                    case (rot)
                        2'd0: piece_shape = 16'b1000_1110_0000_0000;
                        2'd1: piece_shape = 16'b0110_0100_0100_0000;
                        2'd2: piece_shape = 16'b0000_1110_0010_0000;
                        default: piece_shape = 16'b0100_0100_1100_0000;
                    endcase
                end
                default: begin
                    case (rot)
                        2'd0: piece_shape = 16'b0010_1110_0000_0000;
                        2'd1: piece_shape = 16'b0100_0100_0110_0000;
                        2'd2: piece_shape = 16'b0000_1110_1000_0000;
                        default: piece_shape = 16'b1100_0100_0100_0000;
                    endcase
                end
            endcase
        end
    endfunction

    function piece_cell;
        input [2:0] piece_id;
        input [1:0] rot;
        input integer local_x;
        input integer local_y;
        reg [15:0] shape;
        integer bit_index_local;
        begin
            piece_cell = 1'b0;
            if ((local_x >= 0) && (local_x < 4) && (local_y >= 0) && (local_y < 4)) begin
                shape = piece_shape(piece_id, rot);
                bit_index_local = 15 - ((local_y * 4) + local_x);
                piece_cell = shape[bit_index_local];
            end
        end
    endfunction

    function position_valid_on_board;
        input [255:0] board_state;
        input [2:0] piece_id;
        input [1:0] rot;
        input integer base_x;
        input integer base_y;
        integer local_x;
        integer local_y;
        integer board_x;
        integer board_y;
        begin
            position_valid_on_board = 1'b1;
            for (local_y = 0; local_y < 4; local_y = local_y + 1) begin
                for (local_x = 0; local_x < 4; local_x = local_x + 1) begin
                    if (piece_cell(piece_id, rot, local_x, local_y)) begin
                        board_x = base_x + local_x;
                        board_y = base_y + local_y;
                        if ((board_x < 0) || (board_x >= FIELD_W) ||
                            (board_y < 0) || (board_y >= FIELD_H)) begin
                            position_valid_on_board = 1'b0;
                        end else if (board_state[(board_y * FIELD_W) + board_x]) begin
                            position_valid_on_board = 1'b0;
                        end
                    end
                end
            end
        end
    endfunction

    function current_piece_cell;
        input integer board_x;
        input integer board_y;
        integer local_x;
        integer local_y;
        begin
            current_piece_cell = 1'b0;
            for (local_y = 0; local_y < 4; local_y = local_y + 1) begin
                for (local_x = 0; local_x < 4; local_x = local_x + 1) begin
                    if (piece_cell(cur_piece, cur_rot, local_x, local_y) &&
                        (cur_x + local_x == board_x) &&
                        (cur_y + local_y == board_y)) begin
                        current_piece_cell = 1'b1;
                    end
                end
            end
        end
    endfunction

    function [2:0] random_piece;
        input [15:0] seed;
        begin
            case (seed[2:0])
                3'd0: random_piece = 3'd0;
                3'd1: random_piece = 3'd1;
                3'd2: random_piece = 3'd2;
                3'd3: random_piece = 3'd3;
                3'd4: random_piece = 3'd4;
                3'd5: random_piece = 3'd5;
                default: random_piece = 3'd6;
            endcase
        end
    endfunction

    function integer score_increment;
        input integer lines;
        begin
            case (lines)
                1: score_increment = 1;
                2: score_increment = 4;
                3: score_increment = 16;
                4: score_increment = 256;
                default: score_increment = 0;
            endcase
        end
    endfunction

    function [2:0] digit_row_bits;
        input [3:0] digit;
        input integer row;
        begin
            digit_row_bits = 3'b000;
            case (digit)
                4'd0: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b101;
                        2: digit_row_bits = 3'b101;
                        3: digit_row_bits = 3'b101;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
                4'd1: begin
                    case (row)
                        0: digit_row_bits = 3'b010;
                        1: digit_row_bits = 3'b110;
                        2: digit_row_bits = 3'b010;
                        3: digit_row_bits = 3'b010;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
                4'd2: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b001;
                        2: digit_row_bits = 3'b111;
                        3: digit_row_bits = 3'b100;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
                4'd3: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b001;
                        2: digit_row_bits = 3'b111;
                        3: digit_row_bits = 3'b001;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
                4'd4: begin
                    case (row)
                        0: digit_row_bits = 3'b101;
                        1: digit_row_bits = 3'b101;
                        2: digit_row_bits = 3'b111;
                        3: digit_row_bits = 3'b001;
                        4: digit_row_bits = 3'b001;
                    endcase
                end
                4'd5: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b100;
                        2: digit_row_bits = 3'b111;
                        3: digit_row_bits = 3'b001;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
                4'd6: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b100;
                        2: digit_row_bits = 3'b111;
                        3: digit_row_bits = 3'b101;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
                4'd7: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b001;
                        2: digit_row_bits = 3'b001;
                        3: digit_row_bits = 3'b001;
                        4: digit_row_bits = 3'b001;
                    endcase
                end
                4'd8: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b101;
                        2: digit_row_bits = 3'b111;
                        3: digit_row_bits = 3'b101;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
                default: begin
                    case (row)
                        0: digit_row_bits = 3'b111;
                        1: digit_row_bits = 3'b101;
                        2: digit_row_bits = 3'b111;
                        3: digit_row_bits = 3'b001;
                        4: digit_row_bits = 3'b111;
                    endcase
                end
            endcase
        end
    endfunction

    function digit_pixel_rotated;
        input [3:0] digit;
        input integer local_x;
        input integer local_y;
        reg [2:0] src_row;
        begin
            digit_pixel_rotated = 1'b0;
            if ((local_x >= 0) && (local_x < SCORE_W) &&
                (local_y >= 0) && (local_y < DIGIT_H)) begin
                src_row = digit_row_bits(digit, 4 - local_x);
                digit_pixel_rotated = src_row[2 - local_y];
            end
        end
    endfunction

    function [3:0] score_digit_at;
        input integer digit_index;
        begin
            case (digit_index)
                0: score_digit_at = score_d4;
                1: score_digit_at = score_d3;
                2: score_digit_at = score_d2;
                3: score_digit_at = score_d1;
                default: score_digit_at = score_d0;
            endcase
        end
    endfunction

    function [1:0] logical_pixel_gray;
        input integer screen_y;
        input [3:0] screen_x;
        integer board_y;
        integer preview_y;
        integer digit_slot;
        integer local_x;
        integer local_y;
        begin
            logical_pixel_gray = 2'd0;

            if ((screen_x < FIELD_W) && (screen_y < (FIELD_H * CELL_H))) begin
                board_y = screen_y / CELL_H;
                if (board_bits[(board_y * FIELD_W) + screen_x]) begin
                    logical_pixel_gray = 2'd2;
                end
                if (current_piece_cell(screen_x, board_y) && !game_over) begin
                    logical_pixel_gray = 2'd3;
                end
            end else if ((screen_x >= PREVIEW_X) && (screen_x < PREVIEW_X + PREVIEW_W) &&
                         (screen_y >= PREVIEW_Y) && (screen_y < PREVIEW_Y + PREVIEW_H)) begin
                local_x = screen_x - PREVIEW_X;
                preview_y = (screen_y - PREVIEW_Y) / CELL_H;
                if (piece_cell(next_piece, 2'd0, local_x, preview_y)) begin
                    logical_pixel_gray = 2'd3;
                end
            end else if ((screen_x >= SCORE_X) && (screen_x < SCORE_X + SCORE_W) &&
                         (screen_y >= SCORE_Y) &&
                         (screen_y < SCORE_Y + (SCORE_DIGITS * DIGIT_STRIDE))) begin
                digit_slot = (screen_y - SCORE_Y) / DIGIT_STRIDE;
                local_y = (screen_y - SCORE_Y) % DIGIT_STRIDE;
                local_x = screen_x - SCORE_X;
                if ((digit_slot < SCORE_DIGITS) && (local_y < DIGIT_H) &&
                    digit_pixel_rotated(score_digit_at(digit_slot), local_x, local_y)) begin
                    logical_pixel_gray = 2'd3;
                end
            end

            if (game_over && (screen_x >= 10) && (screen_x < 15) &&
                (screen_y >= 28) && (screen_y < 36) &&
                ((screen_x + screen_y) & 1)) begin
                logical_pixel_gray = 2'd3;
            end
        end
    endfunction

    function [31:0] column_word_sin2_for;
        input [3:0] x_idx;
        input plane;
        integer y;
        integer panel_y;
        integer lane_bit;
        reg [1:0] gray;
        begin
            column_word_sin2_for = 32'd0;
            for (y = 0; y < DISPLAY_Y; y = y + 1) begin
                panel_y = COL0_IS_TOP ? y : (DISPLAY_Y - 1 - y);
                gray = logical_pixel_gray(y, x_idx);
                if (gray[plane]) begin
                    if ((panel_y >= 16) && (panel_y < 32)) begin
                        lane_bit = panel_y - 16;
                        column_word_sin2_for[lane_bit] = 1'b1;
                    end else if (panel_y >= 48) begin
                        lane_bit = panel_y - 32;
                        column_word_sin2_for[lane_bit] = 1'b1;
                    end
                end
            end
        end
    endfunction

    function [31:0] column_word_sin3_for;
        input [3:0] x_idx;
        input plane;
        integer y;
        integer panel_y;
        integer lane_bit;
        reg [1:0] gray;
        begin
            column_word_sin3_for = 32'd0;
            for (y = 0; y < DISPLAY_Y; y = y + 1) begin
                panel_y = COL0_IS_TOP ? y : (DISPLAY_Y - 1 - y);
                gray = logical_pixel_gray(y, x_idx);
                if (gray[plane]) begin
                    if (panel_y < 16) begin
                        lane_bit = panel_y;
                        column_word_sin3_for[lane_bit] = 1'b1;
                    end else if ((panel_y >= 32) && (panel_y < 48)) begin
                        lane_bit = panel_y - 16;
                        column_word_sin3_for[lane_bit] = 1'b1;
                    end
                end
            end
        end
    endfunction

    always @(posedge clk) begin
        if (USER_KEY) begin
            state             <= STATE_LOAD;
            plane_sel         <= 1'b0;
            scan_row          <= 4'd0;
            bit_index         <= 6'd31;
            row_shift_word    <= 32'd0;
            col_shift_word_sin2 <= 32'd0;
            col_shift_word_sin3 <= 32'd0;
            hold_count        <= 14'd0;
            control_count     <= 20'd0;
            gravity_count     <= 25'd0;
            key_left_ff0      <= 1'b0;
            key_left_ff1      <= 1'b0;
            key_right_ff0     <= 1'b0;
            key_right_ff1     <= 1'b0;
            key_down_ff0      <= 1'b0;
            key_down_ff1      <= 1'b0;
            btn_a_ff0         <= 1'b0;
            btn_a_ff1         <= 1'b0;
            btn_b_ff0         <= 1'b0;
            btn_b_ff1         <= 1'b0;
            key_left_prev     <= 1'b0;
            key_right_prev    <= 1'b0;
            btn_a_prev        <= 1'b0;
            btn_b_prev        <= 1'b0;
            board_bits        <= 256'd0;
            temp_board_bits   <= 256'd0;
            compact_board_bits <= 256'd0;
            cur_piece         <= 3'd0;
            next_piece        <= 3'd1;
            cur_rot           <= 2'd0;
            cur_x             <= SPAWN_X;
            cur_y             <= SPAWN_Y;
            game_over         <= 1'b0;
            score_value       <= 17'd0;
            score_d4          <= 4'd0;
            score_d3          <= 4'd0;
            score_d2          <= 4'd0;
            score_d1          <= 4'd0;
            score_d0          <= 4'd0;
            lfsr              <= 16'h1ACE;
            SIN1              <= 1'b0;
            SIN2              <= 1'b0;
            SIN3              <= 1'b0;
            LATCH             <= 1'b0;
            LED_CLK           <= 1'b0;
            STROBE_           <= 1'b1;
        end else begin
            key_left_ff0  <= KEY_LEFT;
            key_left_ff1  <= key_left_ff0;
            key_right_ff0 <= KEY_RIGHT;
            key_right_ff1 <= key_right_ff0;
            key_down_ff0  <= KEY_DOWN;
            key_down_ff1  <= key_down_ff0;
            btn_a_ff0     <= BTN_A;
            btn_a_ff1     <= btn_a_ff0;
            btn_b_ff0     <= BTN_B;
            btn_b_ff1     <= btn_b_ff0;

            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            if (control_pulse) begin
                control_count  <= 20'd0;
                key_left_prev  <= key_left_ff1;
                key_right_prev <= key_right_ff1;
                btn_a_prev     <= btn_a_ff1;
                btn_b_prev     <= btn_b_ff1;
            end else begin
                control_count <= control_count + 20'd1;
            end

            if (gravity_pulse) begin
                gravity_count <= 25'd0;
            end else begin
                gravity_count <= gravity_count + 25'd1;
            end

            case (state)
                STATE_LOAD: begin
                    STROBE_           <= 1'b1;
                    LATCH             <= 1'b0;
                    LED_CLK           <= 1'b0;
                    SIN1              <= 1'b0;
                    SIN2              <= 1'b0;
                    SIN3              <= 1'b0;
                    row_shift_word    <= row_word_for(scan_row);
                    col_shift_word_sin2 <= column_word_sin2_for(scan_row, plane_sel);
                    col_shift_word_sin3 <= column_word_sin3_for(scan_row, plane_sel);
                    bit_index         <= 6'd31;
                    state             <= STATE_SHIFT_SETUP;
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
                    LATCH      <= 1'b0;
                    STROBE_    <= 1'b0;
                    hold_count <= plane_sel ? ((BASE_ON_TICKS << 1) - 1) : (BASE_ON_TICKS - 1);
                    state      <= STATE_HOLD;
                end

                STATE_HOLD: begin
                    if (hold_count == 0) begin
                        STROBE_ <= 1'b1;
                        if (scan_row == DISPLAY_X - 1) begin
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

            if ((control_pulse || gravity_pulse) && !game_over) begin
                work_x = cur_x;
                work_y = cur_y;
                work_rot = cur_rot;
                locked_now = 0;

                if (drop_step && !position_valid_on_board(board_bits, cur_piece, cur_rot, cur_x, cur_y + 1)) begin
                        work_x = cur_x;
                        work_y = cur_y;
                        work_rot = cur_rot;
                        temp_board_bits = board_bits;
                        for (cell_y = 0; cell_y < 4; cell_y = cell_y + 1) begin
                            for (cell_x = 0; cell_x < 4; cell_x = cell_x + 1) begin
                                if (piece_cell(cur_piece, cur_rot, cell_x, cell_y)) begin
                                    temp_board_bits[((cur_y + cell_y) * FIELD_W) + (cur_x + cell_x)] = 1'b1;
                                end
                            end
                        end

                        clear_count = 0;
                        for (read_row = FIELD_H - 1; read_row >= 0; read_row = read_row - 1) begin
                            row_full = 1;
                            for (cell_x = 0; cell_x < FIELD_W; cell_x = cell_x + 1) begin
                                if (!temp_board_bits[(read_row * FIELD_W) + cell_x]) begin
                                    row_full = 0;
                                end
                            end
                            if (row_full != 0) begin
                                clear_count = clear_count + 1;
                                for (cell_x = 0; cell_x < FIELD_W; cell_x = cell_x + 1) begin
                                    temp_board_bits[(read_row * FIELD_W) + cell_x] = 1'b0;
                                end
                            end
                        end

                        board_bits <= temp_board_bits;

                        new_score = score_value + score_increment(clear_count);
                        if (new_score > 99999) begin
                            new_score = 99999;
                        end
                        score_value <= new_score[16:0];
                        score_d4    <= (new_score / 10000) % 10;
                        score_d3    <= (new_score / 1000) % 10;
                        score_d2    <= (new_score / 100) % 10;
                        score_d1    <= (new_score / 10) % 10;
                        score_d0    <= new_score % 10;

                        cur_piece <= next_piece;
                        next_piece <= random_piece(lfsr);
                        cur_rot <= 2'd0;
                        cur_x <= SPAWN_X;
                        cur_y <= SPAWN_Y;
                        if (!position_valid_on_board(temp_board_bits, next_piece, 2'd0, SPAWN_X, SPAWN_Y)) begin
                            game_over <= 1'b1;
                        end
                        locked_now = 1;
                end else begin
                    if (rot_r_press) begin
                        if (position_valid_on_board(board_bits, cur_piece, (work_rot + 1) & 2'b11, work_x, work_y)) begin
                            work_rot = (work_rot + 1) & 2'b11;
                        end
                    end
                    if (rot_l_press) begin
                        if (position_valid_on_board(board_bits, cur_piece, (work_rot + 3) & 2'b11, work_x, work_y)) begin
                            work_rot = (work_rot + 3) & 2'b11;
                        end
                    end
                    if (left_press) begin
                        if (position_valid_on_board(board_bits, cur_piece, work_rot, work_x - 1, work_y)) begin
                            work_x = work_x - 1;
                        end
                    end
                    if (right_press) begin
                        if (position_valid_on_board(board_bits, cur_piece, work_rot, work_x + 1, work_y)) begin
                            work_x = work_x + 1;
                        end
                    end

                    if (drop_step) begin
                        if (position_valid_on_board(board_bits, cur_piece, work_rot, work_x, work_y + 1)) begin
                            work_y = work_y + 1;
                        end
                    end
                end

                if (locked_now == 0) begin
                    cur_x   <= work_x;
                    cur_y   <= work_y;
                    cur_rot <= work_rot[1:0];
                end
            end
        end
    end

endmodule
