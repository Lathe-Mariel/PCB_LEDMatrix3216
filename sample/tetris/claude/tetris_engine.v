// =============================================================================
// tetris_engine.v  –  Tetris game engine
// initial ブロック不使用: shape ROM を純粋な組み合わせ回路で実装
//
// 画面レイアウト (16col × 64row, 縦長):
//
//   Col:  0  1  2  3  4  5  6  7 | 8  9 10 11 | 12 13 14 15
//   Row 0 ┌──────────────────────┬────────────┬────────────┐
//         │   プレイフィールド    │ 次ピース   │  (未使用) │ rows 0-7
//         │   8cols × 32rows     │  4×4       │            │
//   Row31 │                      ├────────────┴────────────┤
//         │                      │  (未使用)               │ rows 8-31
//         ├──────────────────────┼─────────────────────────┤
//   Row32 │  (未使用)            │  スコア5桁 (縦並び)     │ rows 32-63
//   Row63 └──────────────────────┴─────────────────────────┘
//
// テトロミノ座標系:
//   (px, py) = 4×4バウンディングボックスの左上, プレイフィールド内
//   px: 0..7 (列), py: 0..31 (行, 下方向が増加)
// =============================================================================

module tetris_engine (
    input  wire clk,
    input  wire rst_n,
    // キー入力 (1 = 押下)
    input  wire key_left,
    input  wire key_right,
    input  wire key_down,
    input  wire key_rot_r,
    input  wire key_rot_l,
    // フレームバッファ出力 (64行 × 16bit)
    output wire [15:0] fb_row0,  output wire [15:0] fb_row1,
    output wire [15:0] fb_row2,  output wire [15:0] fb_row3,
    output wire [15:0] fb_row4,  output wire [15:0] fb_row5,
    output wire [15:0] fb_row6,  output wire [15:0] fb_row7,
    output wire [15:0] fb_row8,  output wire [15:0] fb_row9,
    output wire [15:0] fb_row10, output wire [15:0] fb_row11,
    output wire [15:0] fb_row12, output wire [15:0] fb_row13,
    output wire [15:0] fb_row14, output wire [15:0] fb_row15,
    output wire [15:0] fb_row16, output wire [15:0] fb_row17,
    output wire [15:0] fb_row18, output wire [15:0] fb_row19,
    output wire [15:0] fb_row20, output wire [15:0] fb_row21,
    output wire [15:0] fb_row22, output wire [15:0] fb_row23,
    output wire [15:0] fb_row24, output wire [15:0] fb_row25,
    output wire [15:0] fb_row26, output wire [15:0] fb_row27,
    output wire [15:0] fb_row28, output wire [15:0] fb_row29,
    output wire [15:0] fb_row30, output wire [15:0] fb_row31,
    output wire [15:0] fb_row32, output wire [15:0] fb_row33,
    output wire [15:0] fb_row34, output wire [15:0] fb_row35,
    output wire [15:0] fb_row36, output wire [15:0] fb_row37,
    output wire [15:0] fb_row38, output wire [15:0] fb_row39,
    output wire [15:0] fb_row40, output wire [15:0] fb_row41,
    output wire [15:0] fb_row42, output wire [15:0] fb_row43,
    output wire [15:0] fb_row44, output wire [15:0] fb_row45,
    output wire [15:0] fb_row46, output wire [15:0] fb_row47,
    output wire [15:0] fb_row48, output wire [15:0] fb_row49,
    output wire [15:0] fb_row50, output wire [15:0] fb_row51,
    output wire [15:0] fb_row52, output wire [15:0] fb_row53,
    output wire [15:0] fb_row54, output wire [15:0] fb_row55,
    output wire [15:0] fb_row56, output wire [15:0] fb_row57,
    output wire [15:0] fb_row58, output wire [15:0] fb_row59,
    output wire [15:0] fb_row60, output wire [15:0] fb_row61,
    output wire [15:0] fb_row62, output wire [15:0] fb_row63
);

// ===========================================================================
// パラメータ
// ===========================================================================
localparam PF_W = 8;   // プレイフィールド幅 (列数)
localparam PF_H = 32;  // プレイフィールド高さ (行数)

// 重力タイマー: 25MHz / 12,500,000 = 2Hz (約0.5秒/段)
localparam GRAVITY_DIV = 24'd12_500_000;

// ===========================================================================
// Shape ROM  –  組み合わせ回路で実装 (initial ブロック不使用)
//
// テトロミノ種類: 0=I, 1=O, 2=T, 3=S, 4=Z, 5=J, 6=L
// 回転: 0=0°, 1=90°, 2=180°, 3=270°
// 各行: 4bit (bit3=左端列, bit0=右端列)
//
// shape_rom_out: {typ[2:0], rot[1:0], row[1:0]} → 4bit パターン
// インデックス = typ*16 + rot*4 + row  (7bit)
// ===========================================================================
function [3:0] shape_rom;
    input [2:0] typ;
    input [1:0] rot;
    input [1:0] row;
    reg [6:0] idx;
    begin
        idx = {typ, rot, row};
        case (idx)
            // ---- I-piece (type=0) ----
            // rot0: 0000/1111/0000/0000
            7'h00: shape_rom = 4'b0000; 7'h01: shape_rom = 4'b1111;
            7'h02: shape_rom = 4'b0000; 7'h03: shape_rom = 4'b0000;
            // rot1: 0010/0010/0010/0010
            7'h04: shape_rom = 4'b0010; 7'h05: shape_rom = 4'b0010;
            7'h06: shape_rom = 4'b0010; 7'h07: shape_rom = 4'b0010;
            // rot2 = rot0
            7'h08: shape_rom = 4'b0000; 7'h09: shape_rom = 4'b1111;
            7'h0A: shape_rom = 4'b0000; 7'h0B: shape_rom = 4'b0000;
            // rot3 = rot1
            7'h0C: shape_rom = 4'b0010; 7'h0D: shape_rom = 4'b0010;
            7'h0E: shape_rom = 4'b0010; 7'h0F: shape_rom = 4'b0010;

            // ---- O-piece (type=1) ----
            // all rots: 0110/0110/0000/0000
            7'h10: shape_rom = 4'b0110; 7'h11: shape_rom = 4'b0110;
            7'h12: shape_rom = 4'b0000; 7'h13: shape_rom = 4'b0000;
            7'h14: shape_rom = 4'b0110; 7'h15: shape_rom = 4'b0110;
            7'h16: shape_rom = 4'b0000; 7'h17: shape_rom = 4'b0000;
            7'h18: shape_rom = 4'b0110; 7'h19: shape_rom = 4'b0110;
            7'h1A: shape_rom = 4'b0000; 7'h1B: shape_rom = 4'b0000;
            7'h1C: shape_rom = 4'b0110; 7'h1D: shape_rom = 4'b0110;
            7'h1E: shape_rom = 4'b0000; 7'h1F: shape_rom = 4'b0000;

            // ---- T-piece (type=2) ----
            // rot0: 0100/1110/0000/0000
            7'h20: shape_rom = 4'b0100; 7'h21: shape_rom = 4'b1110;
            7'h22: shape_rom = 4'b0000; 7'h23: shape_rom = 4'b0000;
            // rot1: 0100/0110/0100/0000
            7'h24: shape_rom = 4'b0100; 7'h25: shape_rom = 4'b0110;
            7'h26: shape_rom = 4'b0100; 7'h27: shape_rom = 4'b0000;
            // rot2: 1110/0100/0000/0000
            7'h28: shape_rom = 4'b1110; 7'h29: shape_rom = 4'b0100;
            7'h2A: shape_rom = 4'b0000; 7'h2B: shape_rom = 4'b0000;
            // rot3: 0100/1100/0100/0000
            7'h2C: shape_rom = 4'b0100; 7'h2D: shape_rom = 4'b1100;
            7'h2E: shape_rom = 4'b0100; 7'h2F: shape_rom = 4'b0000;

            // ---- S-piece (type=3) ----
            // rot0: 0110/1100/0000/0000
            7'h30: shape_rom = 4'b0110; 7'h31: shape_rom = 4'b1100;
            7'h32: shape_rom = 4'b0000; 7'h33: shape_rom = 4'b0000;
            // rot1: 0100/0110/0010/0000
            7'h34: shape_rom = 4'b0100; 7'h35: shape_rom = 4'b0110;
            7'h36: shape_rom = 4'b0010; 7'h37: shape_rom = 4'b0000;
            // rot2 = rot0
            7'h38: shape_rom = 4'b0110; 7'h39: shape_rom = 4'b1100;
            7'h3A: shape_rom = 4'b0000; 7'h3B: shape_rom = 4'b0000;
            // rot3 = rot1
            7'h3C: shape_rom = 4'b0100; 7'h3D: shape_rom = 4'b0110;
            7'h3E: shape_rom = 4'b0010; 7'h3F: shape_rom = 4'b0000;

            // ---- Z-piece (type=4) ----
            // rot0: 1100/0110/0000/0000
            7'h40: shape_rom = 4'b1100; 7'h41: shape_rom = 4'b0110;
            7'h42: shape_rom = 4'b0000; 7'h43: shape_rom = 4'b0000;
            // rot1: 0010/0110/0100/0000
            7'h44: shape_rom = 4'b0010; 7'h45: shape_rom = 4'b0110;
            7'h46: shape_rom = 4'b0100; 7'h47: shape_rom = 4'b0000;
            // rot2 = rot0
            7'h48: shape_rom = 4'b1100; 7'h49: shape_rom = 4'b0110;
            7'h4A: shape_rom = 4'b0000; 7'h4B: shape_rom = 4'b0000;
            // rot3 = rot1
            7'h4C: shape_rom = 4'b0010; 7'h4D: shape_rom = 4'b0110;
            7'h4E: shape_rom = 4'b0100; 7'h4F: shape_rom = 4'b0000;

            // ---- J-piece (type=5) ----
            // rot0: 1000/1110/0000/0000
            7'h50: shape_rom = 4'b1000; 7'h51: shape_rom = 4'b1110;
            7'h52: shape_rom = 4'b0000; 7'h53: shape_rom = 4'b0000;
            // rot1: 0110/0100/0100/0000
            7'h54: shape_rom = 4'b0110; 7'h55: shape_rom = 4'b0100;
            7'h56: shape_rom = 4'b0100; 7'h57: shape_rom = 4'b0000;
            // rot2: 1110/0010/0000/0000
            7'h58: shape_rom = 4'b1110; 7'h59: shape_rom = 4'b0010;
            7'h5A: shape_rom = 4'b0000; 7'h5B: shape_rom = 4'b0000;
            // rot3: 0100/0100/1100/0000
            7'h5C: shape_rom = 4'b0100; 7'h5D: shape_rom = 4'b0100;
            7'h5E: shape_rom = 4'b1100; 7'h5F: shape_rom = 4'b0000;

            // ---- L-piece (type=6) ----
            // rot0: 0010/1110/0000/0000
            7'h60: shape_rom = 4'b0010; 7'h61: shape_rom = 4'b1110;
            7'h62: shape_rom = 4'b0000; 7'h63: shape_rom = 4'b0000;
            // rot1: 0100/0100/0110/0000
            7'h64: shape_rom = 4'b0100; 7'h65: shape_rom = 4'b0100;
            7'h66: shape_rom = 4'b0110; 7'h67: shape_rom = 4'b0000;
            // rot2: 1110/1000/0000/0000
            7'h68: shape_rom = 4'b1110; 7'h69: shape_rom = 4'b1000;
            7'h6A: shape_rom = 4'b0000; 7'h6B: shape_rom = 4'b0000;
            // rot3: 1100/0100/0100/0000
            7'h6C: shape_rom = 4'b1100; 7'h6D: shape_rom = 4'b0100;
            7'h6E: shape_rom = 4'b0100; 7'h6F: shape_rom = 4'b0000;

            default: shape_rom = 4'b0000;
        endcase
    end
endfunction

// shape ROM からビット1個を取り出す
// sc: シェイプ内列 (0=左端=bit3, 3=右端=bit0)
function get_shape_bit;
    input [2:0] typ;
    input [1:0] rot;
    input [1:0] sr;   // shape row 0-3
    input [1:0] sc;   // shape col 0-3
    reg [3:0] row_bits;
    begin
        row_bits = shape_rom(typ, rot, sr);
        get_shape_bit = row_bits[3 - sc];
    end
endfunction

// ===========================================================================
// プレイフィールドメモリ: 32行 × 8列
// pf[row][col] : bit7=左端列(col0), bit0=右端列(col7)
// ===========================================================================
reg [7:0] pf [0:31];

// ===========================================================================
// 現在ピース状態
// ===========================================================================
reg [2:0] piece_type;       // 0-6
reg [1:0] piece_rot;        // 0-3
reg signed [4:0] px;        // 列 (符号付き: 壁判定のため)
reg signed [5:0] py;        // 行 (符号付き: 上端外も表現)

// 次ピース
reg [2:0] next_type;

// ===========================================================================
// スコア (5桁BCD, 最大99999)
// [19:16]=万の位, [15:12]=千の位, [11:8]=百の位, [7:4]=十の位, [3:0]=一の位
// ===========================================================================
reg [19:0] score_bcd;

// ===========================================================================
// ゲーム状態
// ===========================================================================
localparam GS_SPAWN    = 3'd0;
localparam GS_PLAY     = 3'd1;
localparam GS_CLEAR    = 3'd2;
localparam GS_GAMEOVER = 3'd3;

reg [2:0] game_state;

// ===========================================================================
// 重力タイマー (25MHz / 12,500,000 = 2Hz)
// ===========================================================================
reg [23:0] grav_cnt;
wire grav_tick = (grav_cnt == 24'd0);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        grav_cnt <= GRAVITY_DIV;
    else if (grav_cnt == 24'd0)
        grav_cnt <= GRAVITY_DIV;
    else
        grav_cnt <= grav_cnt - 1'b1;
end

// ===========================================================================
// 7bit LFSR 乱数 (フィードバック: x7+x6+1)
// ===========================================================================
reg [6:0] lfsr;

// LFSRから0-6のピース種類を生成
function [2:0] lfsr_to_type;
    input [6:0] v;
    begin
        // 0..6 の範囲に収める (7以上は上位3bitで再試行)
        if (v[2:0] < 3'd7)
            lfsr_to_type = v[2:0];
        else if (v[5:3] < 3'd7)
            lfsr_to_type = v[5:3];
        else
            lfsr_to_type = 3'd0;
    end
endfunction

// ===========================================================================
// キーエッジ検出 (立ち上がりエッジ)
// ===========================================================================
reg key_left_r, key_right_r, key_down_r, key_rot_r_r, key_rot_l_r;
wire key_left_edge  = key_left  & ~key_left_r;
wire key_right_edge = key_right & ~key_right_r;
wire key_down_edge  = key_down  & ~key_down_r;
wire key_rotr_edge  = key_rot_r & ~key_rot_r_r;
wire key_rotl_edge  = key_rot_l & ~key_rot_l_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_left_r  <= 1'b0; key_right_r <= 1'b0; key_down_r  <= 1'b0;
        key_rot_r_r <= 1'b0; key_rot_l_r <= 1'b0;
    end else begin
        key_left_r  <= key_left;  key_right_r <= key_right;
        key_down_r  <= key_down;  key_rot_r_r <= key_rot_r;
        key_rot_l_r <= key_rot_l;
    end
end

// ===========================================================================
// 衝突判定関数
// 指定位置・回転でピースが壁/固定ブロックと衝突するか判定
// ===========================================================================
function collides;
    input [2:0] typ;
    input [1:0] rot;
    input signed [4:0] cpx;
    input signed [5:0] cpy;
    reg [1:0] sr, sc;
    reg signed [4:0] fx;
    reg signed [5:0] fy;
    reg hit;
    begin
        hit = 1'b0;
        for (sr = 2'd0; sr <= 2'd3; sr = sr + 1'b1) begin
            for (sc = 2'd0; sc <= 2'd3; sc = sc + 1'b1) begin
                if (get_shape_bit(typ, rot, sr, sc)) begin
                    fx = cpx + {{3{1'b0}}, sc};
                    fy = cpy + {{4{1'b0}}, sr};
                    // 左右壁・底面
                    if (fx < 5'sd0 || fx >= $signed(5'd8) || fy >= 6'sd32)
                        hit = 1'b1;
                    // 固定ブロック (fy >= 0 のみ参照)
                    else if (fy >= 6'sd0 && pf[fy[4:0]][7 - fx[2:0]])
                        hit = 1'b1;
                end
            end
        end
        collides = hit;
    end
endfunction

// ===========================================================================
// ライン消去検出
// ===========================================================================
wire [31:0] row_full_mask;
genvar gi;
generate
    for (gi = 0; gi < 32; gi = gi + 1) begin : full_detect
        assign row_full_mask[gi] = (pf[gi] == 8'hFF);
    end
endgenerate

// ===========================================================================
// BCD 加算タスク
// ===========================================================================
task bcd_add;
    input  [19:0] a;
    input  [19:0] b;
    output [19:0] result;
    reg [4:0] d0, d1, d2, d3, d4;
    reg c0, c1, c2, c3;
    begin
        d0 = {1'b0, a[3:0]}  + {1'b0, b[3:0]};
        c0 = (d0 >= 5'd10); if (c0) d0 = d0 - 5'd10;

        d1 = {1'b0, a[7:4]}  + {1'b0, b[7:4]}  + {4'b0, c0};
        c1 = (d1 >= 5'd10); if (c1) d1 = d1 - 5'd10;

        d2 = {1'b0, a[11:8]} + {1'b0, b[11:8]} + {4'b0, c1};
        c2 = (d2 >= 5'd10); if (c2) d2 = d2 - 5'd10;

        d3 = {1'b0, a[15:12]}+ {1'b0, b[15:12]}+ {4'b0, c2};
        c3 = (d3 >= 5'd10); if (c3) d3 = d3 - 5'd10;

        d4 = {1'b0, a[19:16]}+ {1'b0, b[19:16]}+ {4'b0, c3};
        if (d4 >= 5'd10) d4 = 5'd9; // 飽和

        result = {d4[3:0], d3[3:0], d2[3:0], d1[3:0], d0[3:0]};
    end
endtask

// ===========================================================================
// ライン消去後の行詰め処理
// clear_mask で指定された行を除去し, 上から詰める
// ===========================================================================
task compact_field;
    input [31:0] mask;
    input [2:0]  cnt; // 消去行数
    reg [4:0] dst, src;
    integer k;
    begin
        dst = 5'd31;
        // src を 31 から 0 に走査し, maskが0の行のみ dst へコピー
        for (k = 31; k >= 0; k = k - 1) begin
            src = k[4:0];
            if (!mask[src]) begin
                pf[dst] <= pf[src];
                dst = dst - 1'b1;
            end
        end
        // 上端の cnt 行を 0 クリア
        for (k = 0; k < 4; k = k + 1) begin
            if (k[2:0] < cnt)
                pf[k[4:0]] <= 8'h00;
        end
    end
endtask

// ===========================================================================
// メインゲーム FSM
// ===========================================================================
reg [31:0] clear_mask;
reg [2:0]  clear_count;
reg [3:0]  clear_anim;  // 消去アニメーションカウンタ
integer    i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 32; i = i + 1)
            pf[i] <= 8'h00;
        score_bcd  <= 20'h00000;
        game_state <= GS_SPAWN;
        lfsr       <= 7'h55;
        piece_type <= 3'd0;
        next_type  <= 3'd1;
        px         <= 5'sd2;
        py         <= -6'sd1;
        piece_rot  <= 2'd0;
        clear_mask <= 32'd0;
        clear_count <= 3'd0;
        clear_anim <= 4'd0;
    end else begin
        // LFSR を毎サイクル更新
        lfsr <= {lfsr[5:0], lfsr[6] ^ lfsr[5]};

        case (game_state)

            // --------------------------------------------------------------
            GS_SPAWN: begin
                piece_type <= next_type;
                next_type  <= lfsr_to_type(lfsr);
                piece_rot  <= 2'd0;
                px         <= 5'sd2;
                py         <= -6'sd1;
                if (collides(next_type, 2'd0, 5'sd2, -6'sd1))
                    game_state <= GS_GAMEOVER;
                else
                    game_state <= GS_PLAY;
            end

            // --------------------------------------------------------------
            GS_PLAY: begin
                // 右回転
                if (key_rotr_edge) begin
                    if (!collides(piece_type, piece_rot + 2'd1, px, py))
                        piece_rot <= piece_rot + 2'd1;
                end
                // 左回転
                else if (key_rotl_edge) begin
                    if (!collides(piece_type, piece_rot - 2'd1, px, py))
                        piece_rot <= piece_rot - 2'd1;
                end

                // 左移動
                if (key_left_edge) begin
                    if (!collides(piece_type, piece_rot, px - 5'sd1, py))
                        px <= px - 5'sd1;
                end

                // 右移動
                if (key_right_edge) begin
                    if (!collides(piece_type, piece_rot, px + 5'sd1, py))
                        px <= px + 5'sd1;
                end

                // 重力 / ソフトドロップ
                if (grav_tick || key_down_edge) begin
                    if (!collides(piece_type, piece_rot, px, py + 6'sd1)) begin
                        py <= py + 6'sd1;
                    end else begin
                        // ピースを固定
                        begin : lock_blk
                            reg [1:0] lsr, lsc;
                            reg signed [4:0] lfx;
                            reg signed [5:0] lfy;
                            for (lsr = 2'd0; lsr <= 2'd3; lsr = lsr + 1'b1) begin
                                for (lsc = 2'd0; lsc <= 2'd3; lsc = lsc + 1'b1) begin
                                    if (get_shape_bit(piece_type, piece_rot, lsr, lsc)) begin
                                        lfx = px + {{3{1'b0}}, lsc};
                                        lfy = py + {{4{1'b0}}, lsr};
                                        if (lfy >= 6'sd0 && lfy < 6'sd32 &&
                                            lfx >= 5'sd0 && lfx < 5'sd8)
                                            pf[lfy[4:0]][7 - lfx[2:0]] <= 1'b1;
                                    end
                                end
                            end
                        end

                        // ライン消去検出
                        clear_mask  <= row_full_mask;
                        clear_count <= row_full_mask[0]  + row_full_mask[1]  +
                                       row_full_mask[2]  + row_full_mask[3]  +
                                       row_full_mask[4]  + row_full_mask[5]  +
                                       row_full_mask[6]  + row_full_mask[7]  +
                                       row_full_mask[8]  + row_full_mask[9]  +
                                       row_full_mask[10] + row_full_mask[11] +
                                       row_full_mask[12] + row_full_mask[13] +
                                       row_full_mask[14] + row_full_mask[15] +
                                       row_full_mask[16] + row_full_mask[17] +
                                       row_full_mask[18] + row_full_mask[19] +
                                       row_full_mask[20] + row_full_mask[21] +
                                       row_full_mask[22] + row_full_mask[23] +
                                       row_full_mask[24] + row_full_mask[25] +
                                       row_full_mask[26] + row_full_mask[27] +
                                       row_full_mask[28] + row_full_mask[29] +
                                       row_full_mask[30] + row_full_mask[31];
                        clear_anim  <= 4'd8;
                        game_state  <= GS_CLEAR;
                    end
                end
            end

            // --------------------------------------------------------------
            GS_CLEAR: begin
                if (clear_anim != 4'd0) begin
                    clear_anim <= clear_anim - 1'b1;
                end else begin
                    // スコア加算
                    begin : score_blk
                        reg [19:0] add_val;
                        case (clear_count)
                            3'd1: add_val = 20'h00001;  //   1点
                            3'd2: add_val = 20'h00004;  //   4点
                            3'd3: add_val = 20'h00016;  //  16点
                            3'd4: add_val = 20'h00256;  // 256点
                            default: add_val = 20'h00000;
                        endcase
                        bcd_add(score_bcd, add_val, score_bcd);
                    end

                    // 行詰め処理
                    compact_field(clear_mask, clear_count);

                    clear_mask  <= 32'd0;
                    clear_count <= 3'd0;
                    game_state  <= GS_SPAWN;
                end
            end

            // --------------------------------------------------------------
            GS_GAMEOVER: begin
                // 全LED点滅 (grav_cntのMSBでトグル)
                // いずれかのキーでリセット
                if (key_left_edge || key_right_edge ||
                    key_rotr_edge || key_rotl_edge  || key_down_edge) begin
                    for (i = 0; i < 32; i = i + 1)
                        pf[i] <= 8'h00;
                    score_bcd  <= 20'h00000;
                    game_state <= GS_SPAWN;
                end
            end

            default: game_state <= GS_SPAWN;
        endcase
    end
end

// ===========================================================================
// フレームバッファ合成 (組み合わせ回路)
//
// bit割り当て: fb_rowN[15]=col0(左端), fb_rowN[0]=col15(右端)
//
// エリア分割:
//   cols 0-7,  rows 0-31  : プレイフィールド + 落下中ピース
//   cols 8-11, rows 0-7   : 次ピース予告 (4×4)
//   cols 11-13, rows 32-62: スコア5桁 (3px幅×5px高 × 5桁, 縦並び)
// ===========================================================================

// スコアBCDの各桁
wire [3:0] score_d4 = score_bcd[19:16]; // 万の位 (最上位)
wire [3:0] score_d3 = score_bcd[15:12];
wire [3:0] score_d2 = score_bcd[11:8];
wire [3:0] score_d1 = score_bcd[7:4];
wire [3:0] score_d0 = score_bcd[3:0];   // 一の位 (最下位)

// フォントROM接続 (各桁×5行)
wire [2:0] fp [0:4][0:4]; // fp[digit_idx][font_row]
genvar gj, gk;
generate
    for (gj = 0; gj < 5; gj = gj + 1) begin : fgen_digit
        wire [3:0] dsel;
        assign dsel = (gj == 0) ? score_d4 :
                      (gj == 1) ? score_d3 :
                      (gj == 2) ? score_d2 :
                      (gj == 3) ? score_d1 : score_d0;
        for (gk = 0; gk < 5; gk = gk + 1) begin : fgen_row
            font_5x3 uf (
                .digit  (dsel),
                .row    (gk[2:0]),
                .pixels (fp[gj][gk])
            );
        end
    end
endgenerate

// ゲームオーバー点滅: grav_cnt MSB でトグル
wire go_flash = (game_state == GS_GAMEOVER) & grav_cnt[23];

// 1行分のピクセル合成関数
function [15:0] compose_row;
    input [5:0] r;      // 表示行 0..63
    reg [15:0] out;
    reg [3:0]  c;
    // プレイフィールド
    reg        pf_px, piece_px;
    reg [1:0]  lsr2, lsc2;
    reg signed [4:0] lfx2;
    reg signed [5:0] lfy2;
    // 次ピース予告
    reg [1:0] nc, nr;
    // スコアパネル
    reg [5:0] local_r;
    reg [2:0] didx, frow;
    reg [1:0] fcol;
    reg [2:0] fpx;
    begin
        out = 16'h0000;

        for (c = 4'd0; c <= 4'd15; c = c + 1'b1) begin

            // ----------------------------------------------------------------
            // プレイフィールド: cols 0-7, rows 0-31
            // ----------------------------------------------------------------
            if (c <= 4'd7 && r <= 6'd31) begin
                // 固定ブロック
                pf_px = pf[r[4:0]][7 - c[2:0]];

                // 落下中ピース
                piece_px = 1'b0;
                begin : piece_check
                    reg [1:0] psr, psc;
                    reg signed [4:0] pfx;
                    reg signed [5:0] pfy;
                    for (psr = 2'd0; psr <= 2'd3; psr = psr + 1'b1) begin
                        for (psc = 2'd0; psc <= 2'd3; psc = psc + 1'b1) begin
                            if (get_shape_bit(piece_type, piece_rot, psr, psc)) begin
                                pfx = px + {{3{1'b0}}, psc};
                                pfy = py + {{4{1'b0}}, psr};
                                if (pfy == $signed({1'b0, r}) &&
                                    pfx == $signed({1'b0, c[2:0]}))
                                    piece_px = 1'b1;
                            end
                        end
                    end
                end

                // 消去アニメ: 該当行を点滅
                if (game_state == GS_CLEAR && clear_mask[r[4:0]])
                    out[15 - c] = clear_anim[2];
                else if (go_flash)
                    out[15 - c] = 1'b1;
                else
                    out[15 - c] = pf_px | piece_px;
            end

            // ----------------------------------------------------------------
            // 次ピース予告: cols 8-11, rows 0-7
            // ----------------------------------------------------------------
            else if (c >= 4'd8 && c <= 4'd11 && r <= 6'd7) begin
                nc = c[1:0]; // 0-3 (c-8 の下位2bit)
                nr = r[1:0]; // 0-3
                out[15 - c] = get_shape_bit(next_type, 2'd0, nr, nc);
            end

            // ----------------------------------------------------------------
            // スコアパネル: cols 11-13, rows 32-62
            // 桁配置 (各桁3px幅×5px高, 桁間1px空き):
            //   digit4(万) : rows 32-36
            //   digit3(千) : rows 38-42
            //   digit2(百) : rows 44-48
            //   digit1(十) : rows 50-54
            //   digit0(一) : rows 56-60
            // ----------------------------------------------------------------
            else if (c >= 4'd11 && c <= 4'd13 && r >= 6'd32 && r <= 6'd62) begin
                local_r = r - 6'd32; // 0..30
                // 桁インデックス: 0..4 (6行ピッチ)
                didx = local_r[5:1] / 3'd3; // 0..4
                frow = local_r % 3'd6;       // 0..5 (5が空きピクセル)
                fcol = c[1:0] - 2'd3;        // cols 11-13 → 0-2

                if (frow <= 3'd4 && didx <= 3'd4) begin
                    fpx = fp[didx][frow[2:0]];
                    out[15 - c] = fpx[2 - (c - 4'd11)];
                end else begin
                    out[15 - c] = 1'b0;
                end
            end

            else begin
                out[15 - c] = 1'b0;
            end
        end

        compose_row = out;
    end
endfunction

// フレームバッファ出力アサイン
assign fb_row0  = compose_row(6'd0);  assign fb_row1  = compose_row(6'd1);
assign fb_row2  = compose_row(6'd2);  assign fb_row3  = compose_row(6'd3);
assign fb_row4  = compose_row(6'd4);  assign fb_row5  = compose_row(6'd5);
assign fb_row6  = compose_row(6'd6);  assign fb_row7  = compose_row(6'd7);
assign fb_row8  = compose_row(6'd8);  assign fb_row9  = compose_row(6'd9);
assign fb_row10 = compose_row(6'd10); assign fb_row11 = compose_row(6'd11);
assign fb_row12 = compose_row(6'd12); assign fb_row13 = compose_row(6'd13);
assign fb_row14 = compose_row(6'd14); assign fb_row15 = compose_row(6'd15);
assign fb_row16 = compose_row(6'd16); assign fb_row17 = compose_row(6'd17);
assign fb_row18 = compose_row(6'd18); assign fb_row19 = compose_row(6'd19);
assign fb_row20 = compose_row(6'd20); assign fb_row21 = compose_row(6'd21);
assign fb_row22 = compose_row(6'd22); assign fb_row23 = compose_row(6'd23);
assign fb_row24 = compose_row(6'd24); assign fb_row25 = compose_row(6'd25);
assign fb_row26 = compose_row(6'd26); assign fb_row27 = compose_row(6'd27);
assign fb_row28 = compose_row(6'd28); assign fb_row29 = compose_row(6'd29);
assign fb_row30 = compose_row(6'd30); assign fb_row31 = compose_row(6'd31);
assign fb_row32 = compose_row(6'd32); assign fb_row33 = compose_row(6'd33);
assign fb_row34 = compose_row(6'd34); assign fb_row35 = compose_row(6'd35);
assign fb_row36 = compose_row(6'd36); assign fb_row37 = compose_row(6'd37);
assign fb_row38 = compose_row(6'd38); assign fb_row39 = compose_row(6'd39);
assign fb_row40 = compose_row(6'd40); assign fb_row41 = compose_row(6'd41);
assign fb_row42 = compose_row(6'd42); assign fb_row43 = compose_row(6'd43);
assign fb_row44 = compose_row(6'd44); assign fb_row45 = compose_row(6'd45);
assign fb_row46 = compose_row(6'd46); assign fb_row47 = compose_row(6'd47);
assign fb_row48 = compose_row(6'd48); assign fb_row49 = compose_row(6'd49);
assign fb_row50 = compose_row(6'd50); assign fb_row51 = compose_row(6'd51);
assign fb_row52 = compose_row(6'd52); assign fb_row53 = compose_row(6'd53);
assign fb_row54 = compose_row(6'd54); assign fb_row55 = compose_row(6'd55);
assign fb_row56 = compose_row(6'd56); assign fb_row57 = compose_row(6'd57);
assign fb_row58 = compose_row(6'd58); assign fb_row59 = compose_row(6'd59);
assign fb_row60 = compose_row(6'd60); assign fb_row61 = compose_row(6'd61);
assign fb_row62 = compose_row(6'd62); assign fb_row63 = compose_row(6'd63);

endmodule
