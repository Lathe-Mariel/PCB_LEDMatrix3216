// =============================================================================
// font_5x3.v  –  5行 × 3列 数字フォント ROM (digits 0-9)
// initial ブロック不使用: 純粋な組み合わせ回路として実装
// 各桁: 3列 × 5行, bit2=左列, bit1=中列, bit0=右列
// =============================================================================
module font_5x3 (
    input  wire [3:0] digit,    // 0..9
    input  wire [2:0] row,      // 0..4 (上から下)
    output reg  [2:0] pixels    // bit2=左, bit1=中, bit0=右
);

// 15bit グリフデータ [14:12]=row0, [11:9]=row1, [8:6]=row2, [5:3]=row3, [2:0]=row4
reg [14:0] glyph;

always @(*) begin
    case (digit)
        //          row0      row1      row2      row3      row4
        4'd0: glyph = {3'b111, 3'b101, 3'b101, 3'b101, 3'b111};
        4'd1: glyph = {3'b010, 3'b110, 3'b010, 3'b010, 3'b111};
        4'd2: glyph = {3'b111, 3'b001, 3'b111, 3'b100, 3'b111};
        4'd3: glyph = {3'b111, 3'b001, 3'b111, 3'b001, 3'b111};
        4'd4: glyph = {3'b101, 3'b101, 3'b111, 3'b001, 3'b001};
        4'd5: glyph = {3'b111, 3'b100, 3'b111, 3'b001, 3'b111};
        4'd6: glyph = {3'b111, 3'b100, 3'b111, 3'b101, 3'b111};
        4'd7: glyph = {3'b111, 3'b001, 3'b001, 3'b001, 3'b001};
        4'd8: glyph = {3'b111, 3'b101, 3'b111, 3'b101, 3'b111};
        4'd9: glyph = {3'b111, 3'b101, 3'b111, 3'b001, 3'b111};
        default: glyph = 15'd0;
    endcase
end

always @(*) begin
    case (row)
        3'd0:    pixels = glyph[14:12];
        3'd1:    pixels = glyph[11:9];
        3'd2:    pixels = glyph[8:6];
        3'd3:    pixels = glyph[5:3];
        3'd4:    pixels = glyph[2:0];
        default: pixels = 3'b000;
    endcase
end

endmodule
