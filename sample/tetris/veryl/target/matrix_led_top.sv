// ---------------------------------------------------------------------------
// matrix_led_top.veryl
//
// Tetris game on 16x64 LED matrix with DualShock controller input.
// Ported from matrix_led_top.v to Veryl.
// Target: Gowin EDA synthesis.
// ---------------------------------------------------------------------------

module tetris_matrix_led_top (
    input  var logic         clk           ,
    input  var logic         user_key      ,
    input  var logic         user_key2     ,
    output var logic         sin1          ,
    output var logic         sin2          ,
    output var logic         sin3          ,
    output var logic         latch         ,
    output var logic         led_clk       ,
    output var logic         strobe_n      ,
    output var logic         joystick_cs2  ,
    output var logic         joystick_mosi2,
    output var logic         joystick_clk2 ,
    output var logic         joystick_cs   ,
    output var logic         joystick_mosi ,
    input  var logic         joystick_miso ,
    input  var logic         joystick_miso2,
    output var logic         joystick_clk  ,
    output var logic [8-1:0] led       
);
    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    localparam int unsigned CLK_HZ           = 50_000_000;
    localparam int unsigned DISPLAY_X        = 16;
    localparam int unsigned DISPLAY_Y        = 64;
    localparam int unsigned FIELD_W          = 8;
    localparam int unsigned FIELD_H          = 32;
    localparam int unsigned CELL_H           = 1;
    localparam int unsigned PREVIEW_X        = 10;
    localparam int unsigned PREVIEW_Y        = 4;
    localparam int unsigned PREVIEW_W        = 4;
    localparam int unsigned PREVIEW_H        = 4;
    localparam int          SCORE_X          = 10;
    localparam int unsigned SCORE_Y          = 40;
    localparam int unsigned SCORE_W          = 5;
    localparam int unsigned SCORE_DIGITS     = 5;
    localparam int unsigned DIGIT_H          = 3;
    localparam int unsigned DIGIT_STRIDE     = 4;
    localparam int unsigned CONTROL_TICK_CYC = CLK_HZ / 50;
    localparam int unsigned GRAVITY_TICK_CYC = CLK_HZ / 2;
    localparam int unsigned BASE_ON_TICKS    = 5_000;
    localparam int unsigned SPAWN_X          = 2;
    localparam int unsigned SPAWN_Y          = 0;
    localparam int unsigned SCLK_DELAY       = 200;

    // Display state machine states
    localparam logic [3-1:0] STATE_LOAD        = 3'd0;
    localparam logic [3-1:0] STATE_SHIFT_SETUP = 3'd1;
    localparam logic [3-1:0] STATE_SHIFT_HIGH  = 3'd2;
    localparam logic [3-1:0] STATE_SHIFT_LOW   = 3'd3;
    localparam logic [3-1:0] STATE_LATCH_ON    = 3'd4;
    localparam logic [3-1:0] STATE_LATCH_OFF   = 3'd5;
    localparam logic [3-1:0] STATE_HOLD        = 3'd6;

    // Display orientation
    localparam int unsigned ROW0_IS_LEFT    = 0;
    localparam int unsigned COL0_IS_TOP     = 0;
    localparam int unsigned SHIFT_MSB_FIRST = 0;

    // -----------------------------------------------------------------------
    // DualShock clock generation (250 kHz from 50 MHz)
    // -----------------------------------------------------------------------
    logic         sclk    ;
    logic [8-1:0] sclk_cnt; // ceil(log2(200)) = 8 bits

    always_ff @ (posedge clk) begin
        if (sclk_cnt == (SCLK_DELAY - 1)) begin
            sclk     <= ~sclk;
            sclk_cnt <= 8'h00;
        end else begin
            sclk_cnt <= sclk_cnt + 8'h01;
        end
    end

    // -----------------------------------------------------------------------
    // DualShock controller instance
    // -----------------------------------------------------------------------
    logic [8-1:0] joy_rx  [2];
    logic [8-1:0] joy_rx2 [2]; // second controller (unused in game logic)

    // Unused outputs for second controller tied off
    always_comb joystick_cs2   = 1'b1;
    always_comb joystick_mosi2 = 1'b1;
    always_comb joystick_clk2  = 1'b1;

    tetris_dualshock_controller controller (
        .i_clk250k (sclk         ),
        .i_rstn    (1'b1         ),
        .o_ps_clk  (joystick_clk ),
        .o_ps_sel  (joystick_cs  ),
        .o_ps_txd  (joystick_mosi),
        .i_ps_rxd  (joystick_miso),
        .o_rxd_1   (joy_rx[0]    ),
        .o_rxd_2   (joy_rx[1]    ),
        .o_rxd_3   (             ),
        .o_rxd_4   (             ),
        .o_rxd_5   (             ),
        .o_rxd_6   (             ),
        .i_conf_sw (1'b0         ),
        .i_mode_sw (1'b1         ),
        .i_mode_en (1'b0         ),
        .i_vib_sw  (2'b00        ),
        .i_vib_dat (8'hFF        )
    );

    // -----------------------------------------------------------------------
    // Button / joystick decoding
    // -----------------------------------------------------------------------
    // DualShock byte0 bit mapping (active-low):
    //   bit7=left  bit5=right  bit6=down  bit3=start
    // byte1: bit4=triangle  bit7=square  bit6=cross  bit5=circle
    logic key_left ;
    logic key_right;
    logic key_down ;
    logic btn_a    ;
    logic btn_b    ;
    logic reset_key;

    always_comb key_left  = ~joy_rx[0][7];
    always_comb key_right = ~joy_rx[0][5];
    always_comb key_down  = ~joy_rx[0][6];
    always_comb btn_a     = ~joy_rx[1][4];
    always_comb btn_b     = ~joy_rx[1][7];
    always_comb reset_key = ~joy_rx[0][3];

    always_comb led[0]   = ~joy_rx[0][5];
    always_comb led[1]   = ~joy_rx[0][7];
    always_comb led[7:2] = 6'h00;

    // -----------------------------------------------------------------------
    // Registers
    // -----------------------------------------------------------------------
    logic [3-1:0]  state              ;
    logic          plane_sel          ;
    logic [4-1:0]  scan_row           ;
    logic [6-1:0]  bit_index          ;
    logic [32-1:0] row_shift_word     ;
    logic [32-1:0] col_shift_word_sin2;
    logic [32-1:0] col_shift_word_sin3;
    logic [14-1:0] hold_count         ;

    logic [20-1:0] control_count;
    logic [25-1:0] gravity_count;

    logic key_left_ff0 ;
    logic key_left_ff1 ;
    logic key_right_ff0;
    logic key_right_ff1;
    logic key_down_ff0 ;
    logic key_down_ff1 ;
    logic btn_a_ff0    ;
    logic btn_a_ff1    ;
    logic btn_b_ff0    ;
    logic btn_b_ff1    ;

    logic key_left_prev ;
    logic key_right_prev;
    logic btn_a_prev    ;
    logic btn_b_prev    ;

    logic [256-1:0] board_bits        ;
    logic [256-1:0] temp_board_bits   ;
    logic [256-1:0] compact_board_bits;
    logic [3-1:0]   cur_piece         ;
    logic [3-1:0]   next_piece        ;
    logic [2-1:0]   cur_rot           ;
    logic [5-1:0]   cur_x             ; // signed, but stored as 2's complement
    logic [6-1:0]   cur_y             ;
    logic           game_over         ;
    logic           line_clear_pending;
    logic [17-1:0]  score_value       ;
    logic [4-1:0]   score_d4          ;
    logic [4-1:0]   score_d3          ;
    logic [4-1:0]   score_d2          ;
    logic [4-1:0]   score_d1          ;
    logic [4-1:0]   score_d0          ;
    logic [16-1:0]  lfsr              ;

    // -----------------------------------------------------------------------
    // Derived pulse / press signals
    // -----------------------------------------------------------------------
    logic control_pulse ;
    logic gravity_pulse ;
    logic left_press    ;
    logic right_press   ;
    logic rot_r_press   ;
    logic rot_l_press   ;
    logic soft_drop_step;
    logic drop_step     ;

    always_comb control_pulse  = control_count == (CONTROL_TICK_CYC - 1);
    always_comb gravity_pulse  = gravity_count == (GRAVITY_TICK_CYC - 1);
    always_comb left_press     = control_pulse & key_left_ff1 & ~key_left_prev;
    always_comb right_press    = control_pulse & key_right_ff1 & ~key_right_prev;
    always_comb rot_r_press    = control_pulse & btn_a_ff1 & ~btn_a_prev;
    always_comb rot_l_press    = control_pulse & btn_b_ff1 & ~btn_b_prev;
    always_comb soft_drop_step = control_pulse & key_down_ff1;
    always_comb drop_step      = gravity_pulse | soft_drop_step;

    // -----------------------------------------------------------------------
    // Functions
    // -----------------------------------------------------------------------

    // Build row one-hot word for a given column index
    function automatic logic [32-1:0] row_word_for(
        input var logic [4-1:0] x_idx
    ) ;
        logic        [16-1:0] one_hot_row;
        int unsigned          panel_row  ;
        one_hot_row = 16'h0000;
        if (ROW0_IS_LEFT != 0) begin
            panel_row = unsigned'(int'(x_idx));
        end else begin
            panel_row = (DISPLAY_X - 1) - unsigned'(int'(x_idx));
        end
        one_hot_row[panel_row] = 1'b1;
        return {one_hot_row, one_hot_row};
    endfunction

    // Pick one bit from a 32-bit word (MSB or LSB first)
    function automatic logic serial_pick32(
        input var logic [32-1:0] word,
        input var logic [6-1:0]  idx 
    ) ;
        if (SHIFT_MSB_FIRST != 0) begin
            return word[idx];
        end else begin
            return word[31 - unsigned'(int'(idx))];
        end
    endfunction

    // Tetromino shape look-up (4x4 bitmap packed into 16 bits)
    function automatic logic [16-1:0] piece_shape(
        input var logic [3-1:0] piece_id,
        input var logic [2-1:0] rot     
    ) ;
        logic [16-1:0] result;
        result = 16'h0000;
        case (piece_id)
            3'd0: begin // I
                case (rot)
                    2'd0, 2'd2: result = 16'b0000_1111_0000_0000;
                    default   : result = 16'b0010_0010_0010_0010;
                endcase
            end
            3'd1: begin // O
                result = 16'b0000_0110_0110_0000;
            end
            3'd2: begin // T
                case (rot)
                    2'd0   : result = 16'b0000_1110_0100_0000;
                    2'd1   : result = 16'b0100_0110_0100_0000;
                    2'd2   : result = 16'b0100_1110_0000_0000;
                    default: result = 16'b0100_1100_0100_0000;
                endcase
            end
            3'd3: begin // S
                case (rot)
                    2'd0, 2'd2: result = 16'b0000_0110_1100_0000;
                    default   : result = 16'b0100_0110_0010_0000;
                endcase
            end
            3'd4: begin // Z
                case (rot)
                    2'd0, 2'd2: result = 16'b0000_1100_0110_0000;
                    default   : result = 16'b0010_0110_0100_0000;
                endcase
            end
            3'd5: begin // J
                case (rot)
                    2'd0   : result = 16'b1000_1110_0000_0000;
                    2'd1   : result = 16'b0110_0100_0100_0000;
                    2'd2   : result = 16'b0000_1110_0010_0000;
                    default: result = 16'b0100_0100_1100_0000;
                endcase
            end
            default: begin // L
                case (rot)
                    2'd0   : result = 16'b0010_1110_0000_0000;
                    2'd1   : result = 16'b0100_0100_0110_0000;
                    2'd2   : result = 16'b0000_1110_1000_0000;
                    default: result = 16'b1100_0100_0100_0000;
                endcase
            end
        endcase
        return result;
    endfunction

    // Test if a local cell of a piece is set
    function automatic logic piece_cell(
        input var logic [3-1:0] piece_id,
        input var logic [2-1:0] rot     ,
        input var int           local_x ,
        input var int           local_y 
    ) ;
        logic [16-1:0] shape  ;
        int            bit_pos;
        if (local_x >= 0 && local_x < 4 && local_y >= 0 && local_y < 4) begin
            shape   = piece_shape(piece_id, rot);
            bit_pos = 15 - (local_y * 4 + local_x);
            return shape[unsigned'(int'(bit_pos))];
        end else begin
            return 1'b0;
        end
    endfunction

    // Check whether a piece position is valid on the board
    function automatic logic position_valid(
        input var logic [256-1:0] board_state,
        input var logic [3-1:0]   piece_id   ,
        input var logic [2-1:0]   rot        ,
        input var int             base_x     ,
        input var int             base_y     
    ) ;
        logic valid;
        int   bx   ;
        int   by   ;
        valid = 1'b1;
        for (int ly = 0; ly < 4; ly++) begin
            for (int lx = 0; lx < 4; lx++) begin
                if (piece_cell(piece_id, rot, lx, ly)) begin
                    bx = base_x + lx;
                    by = base_y + ly;
                    if (bx < 0 || bx >= int'(FIELD_W) || by < 0 || by >= int'(FIELD_H)) begin
                        valid = 1'b0;
                    end else if (board_state[unsigned'(int'((by * int'(FIELD_W) + bx)))]) begin
                        valid = 1'b0;
                    end
                end
            end
        end
        return valid;
    endfunction

    // Check whether the piece should lock (nothing below it)
    function automatic logic piece_should_lock(
        input var logic [256-1:0] board_state,
        input var logic [3-1:0]   piece_id   ,
        input var logic [2-1:0]   rot        ,
        input var int             base_x     ,
        input var int             base_y     
    ) ;
        logic should_lock;
        int   bx         ;
        int   by         ;
        should_lock = 1'b0;
        for (int ly = 0; ly < 4; ly++) begin
            for (int lx = 0; lx < 4; lx++) begin
                if (piece_cell(piece_id, rot, lx, ly) && !piece_cell(piece_id, rot, lx, ly + 1)) begin
                    bx = base_x + lx;
                    by = base_y + ly;
                    if (by >= int'(FIELD_H) - 1) begin
                        should_lock = 1'b1;
                    end else if (bx >= 0 && bx < int'(FIELD_W) && by >= 0 && board_state[unsigned'(int'(((by + 1) * int'(FIELD_W) + bx)))]) begin
                        should_lock = 1'b1;
                    end
                end
            end
        end
        return should_lock;
    endfunction

    // Check if the current (active) piece occupies a given board cell
    function automatic logic current_piece_cell(
        input var int bx,
        input var int by
    ) ;
        logic found;
        found = 1'b0;
        for (int ly = 0; ly < 4; ly++) begin
            for (int lx = 0; lx < 4; lx++) begin
                if (piece_cell(cur_piece, cur_rot, lx, ly) && cur_x + lx == bx && cur_y + ly == by) begin
                    found = 1'b1;
                end
            end
        end
        return found;
    endfunction

    // LFSR-based random piece selector
    function automatic logic [3-1:0] random_piece(
        input var logic [16-1:0] seed
    ) ;
        case (seed[2:0])
            3'd0   : return 3'd0;
            3'd1   : return 3'd1;
            3'd2   : return 3'd2;
            3'd3   : return 3'd3;
            3'd4   : return 3'd4;
            3'd5   : return 3'd5;
            default: return 3'd6;
        endcase
    endfunction

    // Score increment per number of cleared lines
    function automatic int score_increment(
        input var int lines
    ) ;
        case (lines)
            1      : return 1;
            2      : return 4;
            3      : return 16;
            4      : return 256;
            default: return 0;
        endcase
    endfunction

    // 3-bit row bitmap for a 7-segment-style digit
    function automatic logic [3-1:0] digit_row_bits(
        input var logic [4-1:0] digit,
        input var int           row  
    ) ;
        logic [3-1:0] r;
        r = 3'b000;
        case (digit)
            4'd0   : begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b101;
                    2      : r = 3'b101;
                    3      : r = 3'b101;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
            4'd1   : begin
                case (row)
                    0      : r = 3'b010;
                    1      : r = 3'b110;
                    2      : r = 3'b010;
                    3      : r = 3'b010;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
            4'd2   : begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b001;
                    2      : r = 3'b111;
                    3      : r = 3'b100;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
            4'd3   : begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b001;
                    2      : r = 3'b111;
                    3      : r = 3'b001;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
            4'd4   : begin
                case (row)
                    0      : r = 3'b101;
                    1      : r = 3'b101;
                    2      : r = 3'b111;
                    3      : r = 3'b001;
                    4      : r = 3'b001;
                    default: begin
                    end
                endcase
            end
            4'd5   : begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b100;
                    2      : r = 3'b111;
                    3      : r = 3'b001;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
            4'd6   : begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b100;
                    2      : r = 3'b111;
                    3      : r = 3'b101;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
            4'd7   : begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b001;
                    2      : r = 3'b001;
                    3      : r = 3'b001;
                    4      : r = 3'b001;
                    default: begin
                    end
                endcase
            end
            4'd8   : begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b101;
                    2      : r = 3'b111;
                    3      : r = 3'b101;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
            default: begin
                case (row)
                    0      : r = 3'b111;
                    1      : r = 3'b101;
                    2      : r = 3'b111;
                    3      : r = 3'b001;
                    4      : r = 3'b111;
                    default: begin
                    end
                endcase
            end
        endcase
        return r;
    endfunction

    // Read rotated digit pixel
    function automatic logic digit_pixel_rotated(
        input var logic [4-1:0] digit  ,
        input var int           local_x,
        input var int           local_y
    ) ;
        logic [3-1:0] src_row;
        if (local_x >= 0 && local_x < int'(SCORE_W) && local_y >= 0 && local_y < int'(DIGIT_H)) begin
            src_row = digit_row_bits(digit, 4 - local_x);
            return src_row[2 - unsigned'(int'(local_y))];
        end else begin
            return 1'b0;
        end
    endfunction

    // Get score digit by position index
    function automatic logic [4-1:0] score_digit_at(
        input var int digit_index
    ) ;
        case (digit_index)
            0      : return score_d4;
            1      : return score_d3;
            2      : return score_d2;
            3      : return score_d1;
            default: return score_d0;
        endcase
    endfunction

    // Compute 2-bit grey level for a logical screen pixel
    function automatic logic [2-1:0] logical_pixel_gray(
        input var int           screen_y,
        input var logic [4-1:0] screen_x
    ) ;
        logic [2-1:0] gray      ;
        int           board_y   ;
        int           preview_y ;
        int           digit_slot;
        int           local_x   ;
        int           local_y   ;

        gray = 2'd0;

        if (screen_x < FIELD_W && screen_y < int'(FIELD_H) * int'(CELL_H)) begin
            board_y = screen_y / int'(CELL_H);
            if (board_bits[unsigned'(int'((board_y * int'(FIELD_W) + int'(screen_x))))]) begin
                gray = 2'd2;
            end
            if (current_piece_cell(int'(screen_x), board_y) && !game_over) begin
                gray = 2'd3;
            end
        end else if (screen_x >= int'(PREVIEW_X) && screen_x < int'(PREVIEW_X) + int'(PREVIEW_W) && screen_y >= int'(PREVIEW_Y) && screen_y < int'(PREVIEW_Y) + int'(PREVIEW_H)) begin
            local_x   = int'(screen_x) - int'(PREVIEW_X);
            preview_y = (screen_y - int'(PREVIEW_Y)) / int'(CELL_H);
            if (piece_cell(next_piece, 2'd0, local_x, preview_y)) begin
                gray = 2'd3;
            end
        end else if (screen_x >= SCORE_X && screen_x < SCORE_X + SCORE_W && screen_y >= SCORE_Y && screen_y < SCORE_Y + SCORE_DIGITS * DIGIT_STRIDE) begin
            digit_slot = (screen_y - SCORE_Y) / DIGIT_STRIDE;
            local_y    = (screen_y - SCORE_Y) % DIGIT_STRIDE;
            local_x    = screen_x - SCORE_X;
            if (digit_slot < SCORE_DIGITS && local_y < DIGIT_H && digit_pixel_rotated(score_digit_at(digit_slot), local_x, local_y)) begin
                gray = 2'd3;
            end
        end

        // Game-over checkerboard overlay
        if (game_over && screen_x >= 10 && screen_x < 15 && screen_y >= 28 && screen_y < 36 && (screen_x + screen_y) & 1 != 0) begin
            gray = 2'd3;
        end

        return gray;
    endfunction

    // Build SIN2 column word for a given x column and plane
    function automatic logic [32-1:0] column_word_sin2_for(
        input var logic [4-1:0] x_idx,
        input var logic         plane
    ) ;
        logic [32-1:0] result  ;
        int            panel_y ;
        int            lane_bit;
        logic [2-1:0]  gray    ;
        result   = 32'd0;
        for (int y = 0; y < int'(DISPLAY_Y); y++) begin
            if (COL0_IS_TOP != 0) begin
                panel_y = y;
            end else begin
                panel_y = int'(DISPLAY_Y) - 1 - y;
            end
            gray = logical_pixel_gray(y, x_idx);
            if (gray[unsigned'(int'(plane))]) begin
                if (panel_y >= 16 && panel_y < 32) begin
                    lane_bit                          = panel_y - 16;
                    result[unsigned'(int'(lane_bit))] = 1'b1;
                end else if (panel_y >= 48) begin
                    lane_bit                          = panel_y - 32;
                    result[unsigned'(int'(lane_bit))] = 1'b1;
                end
            end
        end
        return result;
    endfunction

    // Build SIN3 column word for a given x column and plane
    function automatic logic [32-1:0] column_word_sin3_for(
        input var logic [4-1:0] x_idx,
        input var logic         plane
    ) ;
        logic [32-1:0] result  ;
        int            panel_y ;
        int            lane_bit;
        logic [2-1:0]  gray    ;
        result   = 32'd0;
        for (int y = 0; y < int'(DISPLAY_Y); y++) begin
            if (COL0_IS_TOP != 0) begin
                panel_y = y;
            end else begin
                panel_y = int'(DISPLAY_Y) - 1 - y;
            end
            gray = logical_pixel_gray(y, x_idx);
            if (gray[unsigned'(int'(plane))]) begin
                if (panel_y < 16) begin
                    lane_bit                          = panel_y;
                    result[unsigned'(int'(lane_bit))] = 1'b1;
                end else if (panel_y >= 32 && panel_y < 48) begin
                    lane_bit                          = panel_y - 16;
                    result[unsigned'(int'(lane_bit))] = 1'b1;
                end
            end
        end
        return result;
    endfunction

    // -----------------------------------------------------------------------
    // Main always_ff block
    // -----------------------------------------------------------------------
    always_ff @ (posedge clk) begin
        if (reset_key) begin
            // --- Synchronous reset (from DualShock Start button) ---
            state               <= STATE_LOAD;
            plane_sel           <= 1'b0;
            scan_row            <= 4'd0;
            bit_index           <= 6'd31;
            row_shift_word      <= 32'd0;
            col_shift_word_sin2 <= 32'd0;
            col_shift_word_sin3 <= 32'd0;
            hold_count          <= 14'd0;
            control_count       <= 20'd0;
            gravity_count       <= 25'd0;
            key_left_ff0        <= 1'b0;
            key_left_ff1        <= 1'b0;
            key_right_ff0       <= 1'b0;
            key_right_ff1       <= 1'b0;
            key_down_ff0        <= 1'b0;
            key_down_ff1        <= 1'b0;
            btn_a_ff0           <= 1'b0;
            btn_a_ff1           <= 1'b0;
            btn_b_ff0           <= 1'b0;
            btn_b_ff1           <= 1'b0;
            key_left_prev       <= 1'b0;
            key_right_prev      <= 1'b0;
            btn_a_prev          <= 1'b0;
            btn_b_prev          <= 1'b0;
            board_bits          <= 256'd0;
            temp_board_bits     <= 256'd0;
            compact_board_bits  <= 256'd0;
            cur_piece           <= 3'd0;
            next_piece          <= 3'd1;
            cur_rot             <= 2'd0;
            cur_x               <= SPAWN_X;
            cur_y               <= SPAWN_Y;
            game_over           <= 1'b0;
            line_clear_pending  <= 1'b0;
            score_value         <= 17'd0;
            score_d4            <= 4'd0;
            score_d3            <= 4'd0;
            score_d2            <= 4'd0;
            score_d1            <= 4'd0;
            score_d0            <= 4'd0;
            lfsr                <= 16'h1ACE;
            sin1                <= 1'b0;
            sin2                <= 1'b0;
            sin3                <= 1'b0;
            latch               <= 1'b0;
            led_clk             <= 1'b0;
            strobe_n            <= 1'b1;
        end else begin
            // --- Input double-flip-flop synchronisers ---
            key_left_ff0  <= key_left;
            key_left_ff1  <= key_left_ff0;
            key_right_ff0 <= key_right;
            key_right_ff1 <= key_right_ff0;
            key_down_ff0  <= key_down;
            key_down_ff1  <= key_down_ff0;
            btn_a_ff0     <= btn_a;
            btn_a_ff1     <= btn_a_ff0;
            btn_b_ff0     <= btn_b;
            btn_b_ff1     <= btn_b_ff0;

            // LFSR advance (Fibonacci: taps 16,14,13,11 → bits 15,13,12,10)
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            // Control timer
            if (control_pulse) begin
                control_count  <= 20'd0;
                key_left_prev  <= key_left_ff1;
                key_right_prev <= key_right_ff1;
                btn_a_prev     <= btn_a_ff1;
                btn_b_prev     <= btn_b_ff1;
            end else begin
                control_count <= control_count + 20'd1;
            end

            // Gravity timer
            if (gravity_pulse) begin
                gravity_count <= 25'd0;
            end else begin
                gravity_count <= gravity_count + 25'd1;
            end

            // ---------------------------------------------------------------
            // LED display state machine
            // ---------------------------------------------------------------
            case (state) inside
                STATE_LOAD: begin
                    strobe_n            <= 1'b1;
                    latch               <= 1'b0;
                    led_clk             <= 1'b0;
                    sin1                <= 1'b0;
                    sin2                <= 1'b0;
                    sin3                <= 1'b0;
                    row_shift_word      <= row_word_for(scan_row);
                    col_shift_word_sin2 <= column_word_sin2_for(scan_row, plane_sel);
                    col_shift_word_sin3 <= column_word_sin3_for(scan_row, plane_sel);
                    bit_index           <= 6'd31;
                    state               <= STATE_SHIFT_SETUP;
                end
                STATE_SHIFT_SETUP: begin
                    led_clk <= 1'b0;
                    sin1    <= serial_pick32(row_shift_word, bit_index);
                    sin2    <= serial_pick32(col_shift_word_sin2, bit_index);
                    sin3    <= serial_pick32(col_shift_word_sin3, bit_index);
                    state   <= STATE_SHIFT_HIGH;
                end
                STATE_SHIFT_HIGH: begin
                    led_clk <= 1'b1;
                    state   <= STATE_SHIFT_LOW;
                end
                STATE_SHIFT_LOW: begin
                    led_clk <= 1'b0;
                    if (bit_index == 6'd0) begin
                        state <= STATE_LATCH_ON;
                    end else begin
                        bit_index <= bit_index - 6'd1;
                        state     <= STATE_SHIFT_SETUP;
                    end
                end
                STATE_LATCH_ON: begin
                    latch <= 1'b1;
                    state <= STATE_LATCH_OFF;
                end
                STATE_LATCH_OFF: begin
                    latch      <= 1'b0;
                    strobe_n   <= 1'b0;
                    hold_count <= ((plane_sel == 1) ? ( ((BASE_ON_TICKS << 1) - 1) ) : ( (BASE_ON_TICKS - 1) ));
                    state      <= STATE_HOLD;
                end
                STATE_HOLD: begin
                    if (hold_count == 14'd0) begin
                        strobe_n <= 1'b1;
                        if (scan_row == (DISPLAY_X - 1)) begin
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

            // ---------------------------------------------------------------
            // Tetris game logic (runs on control_pulse or gravity_pulse)
            // ---------------------------------------------------------------
            if ((control_pulse | gravity_pulse) & ~game_over) begin

                if (line_clear_pending) begin
                    // ---- Compact board: remove full rows ----
                    logic [256-1:0] compact;
                    int             clr_cnt;
                    int             wr_row ;
                    int             rd_row ;
                    logic           full   ;
                    int             ns     ;

                    compact = 256'd0;
                    clr_cnt = 0;
                    wr_row  = int'(FIELD_H) - 1;

                    for (int r = 0; r < int'(FIELD_H); r++) begin
                        rd_row = int'(FIELD_H) - 1 - r;
                        full   = 1'b1;
                        for (int cx = 0; cx < int'(FIELD_W); cx++) begin
                            if (!board_bits[unsigned'(int'((rd_row * int'(FIELD_W) + cx)))]) begin
                                full = 1'b0;
                            end
                        end
                        if (full) begin
                            clr_cnt = clr_cnt + 1;
                        end else begin
                            for (int cx = 0; cx < int'(FIELD_W); cx++) begin
                                compact[unsigned'(int'((wr_row * int'(FIELD_W) + cx)))] = board_bits[unsigned'(int'((rd_row * int'(FIELD_W) + cx)))];
                            end
                            wr_row = wr_row - 1;
                        end
                    end

                    board_bits <= compact;

                    ns          =  int'(score_value) + score_increment(clr_cnt);
                    if (ns > 99999) begin
                        ns          =  99999;
                    end
                    score_value <= ns;
                    score_d4    <= (ns / 10000 % 10);
                    score_d3    <= (ns / 1000 % 10);
                    score_d2    <= (ns / 100 % 10);
                    score_d1    <= (ns / 10 % 10);
                    score_d0    <= (ns % 10);

                    cur_piece          <= next_piece;
                    next_piece         <= random_piece(lfsr);
                    cur_rot            <= 2'd0;
                    cur_x              <= SPAWN_X;
                    cur_y              <= SPAWN_Y;
                    line_clear_pending <= 1'b0;

                    if (!position_valid(compact, next_piece, 2'd0, int'(SPAWN_X), int'(SPAWN_Y))) begin
                        game_over <= 1'b1;
                    end

                end else begin
                    // ---- Normal game tick ----
                    byte unsigned wx    ;
                    byte unsigned wy    ;
                    int           wrot  ;
                    logic         locked;

                    wx     = cur_x;
                    wy     = cur_y;
                    wrot   = int'(cur_rot);
                    locked = 1'b0;

                    if (piece_should_lock(board_bits, cur_piece, cur_rot, cur_x, cur_y)) begin
                        locked = 1'b1;
                    end else begin
                        if (rot_r_press) begin
                            if (position_valid(board_bits, cur_piece, ((wrot + 1) & 3), wx, wy)) begin
                                wrot = (wrot + 1) & 3;
                            end
                        end
                        if (rot_l_press) begin
                            if (position_valid(board_bits, cur_piece, ((wrot + 3) & 3), wx, wy)) begin
                                wrot = (wrot + 3) & 3;
                            end
                        end
                        if (left_press) begin
                            if (position_valid(board_bits, cur_piece, wrot, wx - 1, wy)) begin
                                wx = wx - 1;
                            end
                        end
                        if (right_press) begin
                            if (position_valid(board_bits, cur_piece, wrot, wx + 1, wy)) begin
                                wx = wx + 1;
                            end
                        end

                        if (piece_should_lock(board_bits, cur_piece, wrot, wx, wy)) begin
                            locked = 1'b1;
                        end else if (drop_step) begin
                            if (position_valid(board_bits, cur_piece, wrot, wx, wy + 1)) begin
                                wy = wy + 1;
                            end
                        end
                    end

                    if (locked) begin
                        // ---- Lock piece into board ----
                        logic [256-1:0] tmp    ;
                        int             clr_cnt;
                        logic           full   ;

                        tmp = board_bits;
                        for (int ly = 0; ly < 4; ly++) begin
                            for (int lx = 0; lx < 4; lx++) begin
                                if (piece_cell(cur_piece, wrot, lx, ly)) begin
                                    tmp[unsigned'(int'(((wy + ly) * int'(FIELD_W) + (wx + lx))))] = 1'b1;
                                end
                            end
                        end

                        clr_cnt = 0;
                        for (int r = 0; r < int'(FIELD_H); r++) begin
                            int rr  ;
                            rr   = FIELD_H - 1 - r;
                            full = 1'b1;
                            for (int cx = 0; cx < int'(FIELD_W); cx++) begin
                                if (!tmp[unsigned'(int'((rr * int'(FIELD_W) + cx)))]) begin
                                    full = 1'b0;
                                end
                            end
                            if (full) begin
                                clr_cnt = clr_cnt + 1;
                            end
                        end

                        board_bits <= tmp;

                        if (clr_cnt != 0) begin
                            line_clear_pending <= 1'b1;
                        end else begin
                            cur_piece  <= next_piece;
                            next_piece <= random_piece(lfsr);
                            cur_rot    <= 2'd0;
                            cur_x      <= SPAWN_X;
                            cur_y      <= SPAWN_Y;
                            if (!position_valid(tmp, next_piece, 2'd0, int'(SPAWN_X), int'(SPAWN_Y))) begin
                                game_over <= 1'b1;
                            end
                        end
                    end else begin
                        cur_x   <= wx;
                        cur_y   <= wy;
                        cur_rot <= wrot;
                    end
                end
            end
        end
    end
endmodule
//# sourceMappingURL=matrix_led_top.sv.map
