// =============================================================================
// led_driver.v  –  Matrix LED driver for 16×64 LED panel (revised)
//
// 確定仕様:
//   SIN1 : 16bit one-hot 行選択, LSBファースト, 16bitを2周(=32clk)繰り返し
//   SIN2 : 32bit 列データ, LSBファースト (SIN3と同時並列)
//   SIN3 : 32bit 列データ, LSBファースト (SIN2と同時並列)
//   → SIN1/SIN2/SIN3 を同時並列で 32クロック転送
//   LATCH  : 32クロック完了後に共通で1パルス (正論理)
//   STROBE_: 負論理, 表示保持期間中 Low
//
// 列の物理マッピング (64列, LSBファースト転送):
//   転送bit 0-15  → SIN3[15:0]  → 物理列  0-15
//   転送bit 0-15  → SIN2[15:0]  → 物理列 16-31
//   転送bit 16-31 → SIN3[31:16] → 物理列 32-47
//   転送bit 16-31 → SIN2[31:16] → 物理列 48-63
//
// 本設計の画面サイズは横16ドットのため:
//   SIN3[15:0]  = col_word[15:0]  (有効)
//   SIN2[15:0]  = 16'h0000        (未使用)
//   SIN3[31:16] = 16'h0000        (未使用)
//   SIN2[31:16] = 16'h0000        (未使用)
//   → sr_sin3 = {16'h0000, col_word}
//   → sr_sin2 = 32'h00000000
//
// タイミング (25MHz clk, LED_CLK = 12.5MHz):
//   ST_LOAD  : 1サイクル  (シフトレジスタロード)
//   ST_SHIFT : 32×2=64サイクル (32クロック × 立上り/立下り)
//   ST_LATCH : 1サイクル  (LATCHパルス)
//   ST_HOLD  : HOLD_CYCLES (STROBE_ Low 保持)
//   1行合計  ≈ 666サイクル @ 25MHz → 行レート ≈ 37.5kHz
//   フレームレート = 37.5kHz ÷ 64行 ≈ 586 fps
// =============================================================================

module led_driver (
    input  wire clk,
    input  wire rst_n,
    // 64-row framebuffer (16 cols each, bit0=左端列)
    input  wire [15:0] fb_row0,  input  wire [15:0] fb_row1,
    input  wire [15:0] fb_row2,  input  wire [15:0] fb_row3,
    input  wire [15:0] fb_row4,  input  wire [15:0] fb_row5,
    input  wire [15:0] fb_row6,  input  wire [15:0] fb_row7,
    input  wire [15:0] fb_row8,  input  wire [15:0] fb_row9,
    input  wire [15:0] fb_row10, input  wire [15:0] fb_row11,
    input  wire [15:0] fb_row12, input  wire [15:0] fb_row13,
    input  wire [15:0] fb_row14, input  wire [15:0] fb_row15,
    input  wire [15:0] fb_row16, input  wire [15:0] fb_row17,
    input  wire [15:0] fb_row18, input  wire [15:0] fb_row19,
    input  wire [15:0] fb_row20, input  wire [15:0] fb_row21,
    input  wire [15:0] fb_row22, input  wire [15:0] fb_row23,
    input  wire [15:0] fb_row24, input  wire [15:0] fb_row25,
    input  wire [15:0] fb_row26, input  wire [15:0] fb_row27,
    input  wire [15:0] fb_row28, input  wire [15:0] fb_row29,
    input  wire [15:0] fb_row30, input  wire [15:0] fb_row31,
    input  wire [15:0] fb_row32, input  wire [15:0] fb_row33,
    input  wire [15:0] fb_row34, input  wire [15:0] fb_row35,
    input  wire [15:0] fb_row36, input  wire [15:0] fb_row37,
    input  wire [15:0] fb_row38, input  wire [15:0] fb_row39,
    input  wire [15:0] fb_row40, input  wire [15:0] fb_row41,
    input  wire [15:0] fb_row42, input  wire [15:0] fb_row43,
    input  wire [15:0] fb_row44, input  wire [15:0] fb_row45,
    input  wire [15:0] fb_row46, input  wire [15:0] fb_row47,
    input  wire [15:0] fb_row48, input  wire [15:0] fb_row49,
    input  wire [15:0] fb_row50, input  wire [15:0] fb_row51,
    input  wire [15:0] fb_row52, input  wire [15:0] fb_row53,
    input  wire [15:0] fb_row54, input  wire [15:0] fb_row55,
    input  wire [15:0] fb_row56, input  wire [15:0] fb_row57,
    input  wire [15:0] fb_row58, input  wire [15:0] fb_row59,
    input  wire [15:0] fb_row60, input  wire [15:0] fb_row61,
    input  wire [15:0] fb_row62, input  wire [15:0] fb_row63,
    // LED interface
    output reg  SIN1,
    output reg  SIN2,
    output reg  SIN3,
    output reg  LATCH,
    output reg  LED_CLK,
    output reg  STROBE_
);

// ---------------------------------------------------------------------------
// 現在走査中の行 (0..63)
// SIN1 one-hot は cur_row[3:0] ビット目が 1
// ---------------------------------------------------------------------------
reg [5:0] cur_row;

// ---------------------------------------------------------------------------
// フレームバッファ読み出し (combinatorial)
// ---------------------------------------------------------------------------
reg [15:0] col_word;

always @(*) begin
    case (cur_row)
        6'd0:  col_word = fb_row0;   6'd1:  col_word = fb_row1;
        6'd2:  col_word = fb_row2;   6'd3:  col_word = fb_row3;
        6'd4:  col_word = fb_row4;   6'd5:  col_word = fb_row5;
        6'd6:  col_word = fb_row6;   6'd7:  col_word = fb_row7;
        6'd8:  col_word = fb_row8;   6'd9:  col_word = fb_row9;
        6'd10: col_word = fb_row10;  6'd11: col_word = fb_row11;
        6'd12: col_word = fb_row12;  6'd13: col_word = fb_row13;
        6'd14: col_word = fb_row14;  6'd15: col_word = fb_row15;
        6'd16: col_word = fb_row16;  6'd17: col_word = fb_row17;
        6'd18: col_word = fb_row18;  6'd19: col_word = fb_row19;
        6'd20: col_word = fb_row20;  6'd21: col_word = fb_row21;
        6'd22: col_word = fb_row22;  6'd23: col_word = fb_row23;
        6'd24: col_word = fb_row24;  6'd25: col_word = fb_row25;
        6'd26: col_word = fb_row26;  6'd27: col_word = fb_row27;
        6'd28: col_word = fb_row28;  6'd29: col_word = fb_row29;
        6'd30: col_word = fb_row30;  6'd31: col_word = fb_row31;
        6'd32: col_word = fb_row32;  6'd33: col_word = fb_row33;
        6'd34: col_word = fb_row34;  6'd35: col_word = fb_row35;
        6'd36: col_word = fb_row36;  6'd37: col_word = fb_row37;
        6'd38: col_word = fb_row38;  6'd39: col_word = fb_row39;
        6'd40: col_word = fb_row40;  6'd41: col_word = fb_row41;
        6'd42: col_word = fb_row42;  6'd43: col_word = fb_row43;
        6'd44: col_word = fb_row44;  6'd45: col_word = fb_row45;
        6'd46: col_word = fb_row46;  6'd47: col_word = fb_row47;
        6'd48: col_word = fb_row48;  6'd49: col_word = fb_row49;
        6'd50: col_word = fb_row50;  6'd51: col_word = fb_row51;
        6'd52: col_word = fb_row52;  6'd53: col_word = fb_row53;
        6'd54: col_word = fb_row54;  6'd55: col_word = fb_row55;
        6'd56: col_word = fb_row56;  6'd57: col_word = fb_row57;
        6'd58: col_word = fb_row58;  6'd59: col_word = fb_row59;
        6'd60: col_word = fb_row60;  6'd61: col_word = fb_row61;
        6'd62: col_word = fb_row62;  default: col_word = fb_row63;
    endcase
end

// ---------------------------------------------------------------------------
// 行選択 one-hot (16bit)
// cur_row[3:0] がアクティブビット
// ---------------------------------------------------------------------------
wire [15:0] row_onehot = (16'h0001 << cur_row[3:0]);

// ---------------------------------------------------------------------------
// シフトレジスタ (32bit, LSBファースト = 右シフト)
//
// sr_sin1[31:0] = {row_onehot, row_onehot}
//   bit0  = row_onehot[0]  → 1周目 最初に送出
//   bit15 = row_onehot[15] → 1周目 最後
//   bit16 = row_onehot[0]  → 2周目 最初
//   bit31 = row_onehot[15] → 2周目 最後
//
// sr_sin3[31:0] = {16'h0000, col_word[15:0]}
//   bit0  = col_word[0]  → 物理列0 (左端)
//   bit15 = col_word[15] → 物理列15 (右端)
//   bit16-31 = 0         → 物理列32-47 (未使用)
//
// sr_sin2[31:0] = 32'h00000000 (未使用)
// ---------------------------------------------------------------------------
reg [31:0] sr_sin1;
reg [31:0] sr_sin2;
reg [31:0] sr_sin3;

// ---------------------------------------------------------------------------
// ステートマシン
// ---------------------------------------------------------------------------
localparam ST_LOAD  = 2'd0;
localparam ST_SHIFT = 2'd1;
localparam ST_LATCH = 2'd2;
localparam ST_HOLD  = 2'd3;

reg [1:0] state;
reg [4:0] bit_cnt;   // 転送ビットカウンタ 0..31
reg [9:0] hold_cnt;  // STROBE_ 保持カウンタ
reg       clk_phase; // LED_CLK 生成用 (0=立上り準備, 1=立下り)

// 保持サイクル数
// 1行 = (64 + 1 + HOLD_CYCLES) cycles @ 25MHz
// HOLD_CYCLES=600 → 1行≈666cycles → 行レート≈37.5kHz → FPS≈586
localparam HOLD_CYCLES = 10'd600;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= ST_LOAD;
        cur_row   <= 6'd0;
        bit_cnt   <= 5'd0;
        hold_cnt  <= HOLD_CYCLES;
        clk_phase <= 1'b0;
        sr_sin1   <= 32'd0;
        sr_sin2   <= 32'd0;
        sr_sin3   <= 32'd0;
        SIN1      <= 1'b0;
        SIN2      <= 1'b0;
        SIN3      <= 1'b0;
        LATCH     <= 1'b0;
        LED_CLK   <= 1'b0;
        STROBE_   <= 1'b1;
    end else begin
        case (state)

            // ----------------------------------------------------------------
            // ST_LOAD: シフトレジスタにデータをセット
            // ----------------------------------------------------------------
            ST_LOAD: begin
                LATCH     <= 1'b0;
                STROBE_   <= 1'b1;
                LED_CLK   <= 1'b0;
                clk_phase <= 1'b0;
                bit_cnt   <= 5'd0;

                // SIN1: one-hot 16bit × 2周 (LSBファースト)
                sr_sin1 <= {row_onehot, row_onehot};

                // SIN3: col_word を物理列0-15 (SIN3[15:0]) に割り当て
                sr_sin3 <= {16'h0000, col_word};

                // SIN2: 全ビット未使用
                sr_sin2 <= 32'h00000000;

                state <= ST_SHIFT;
            end

            // ----------------------------------------------------------------
            // ST_SHIFT: 32クロックでシリアル転送
            //   LED_CLK 立上り → データ出力
            //   LED_CLK 立下り → シフト & カウント
            // ----------------------------------------------------------------
            ST_SHIFT: begin
                clk_phase <= ~clk_phase;

                if (!clk_phase) begin
                    // --- 立上りエッジ: SINラインにデータを出力 ---
                    LED_CLK <= 1'b1;
                    SIN1    <= sr_sin1[0];  // LSBファースト
                    SIN2    <= sr_sin2[0];
                    SIN3    <= sr_sin3[0];
                end else begin
                    // --- 立下りエッジ: シフト ---
                    LED_CLK <= 1'b0;
                    sr_sin1 <= {1'b0, sr_sin1[31:1]};  // 右シフト
                    sr_sin2 <= {1'b0, sr_sin2[31:1]};
                    sr_sin3 <= {1'b0, sr_sin3[31:1]};

                    if (bit_cnt == 5'd31) begin
                        state   <= ST_LATCH;
                        bit_cnt <= 5'd0;
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end
            end

            // ----------------------------------------------------------------
            // ST_LATCH: LATCH パルス & STROBE_ アサート
            // ----------------------------------------------------------------
            ST_LATCH: begin
                LATCH    <= 1'b1;   // 正論理: 1でデータラッチ
                STROBE_  <= 1'b0;   // 負論理: Low で表示イネーブル
                hold_cnt <= HOLD_CYCLES;
                state    <= ST_HOLD;
            end

            // ----------------------------------------------------------------
            // ST_HOLD: 表示保持 → 次の行へ
            // ----------------------------------------------------------------
            ST_HOLD: begin
                LATCH <= 1'b0;      // LATCHは1サイクルのみ
                if (hold_cnt == 10'd0) begin
                    STROBE_ <= 1'b1;            // 表示ディセーブル
                    cur_row <= cur_row + 1'b1;  // 0..63 自動折り返し
                    state   <= ST_LOAD;
                end else begin
                    hold_cnt <= hold_cnt - 1'b1;
                end
            end

            default: state <= ST_LOAD;

        endcase
    end
end

endmodule
