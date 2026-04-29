// =============================================================================
// tetris_top.v  –  Top-level for Tang Primer 25K Matrix-LED Tetris
// System clock : 50 MHz (clk pin E2)
// =============================================================================
module tetris_top (
    input  wire clk,          // 50 MHz system clock (E2)
    input  wire USER_KEY,     // key1 (H11, PULL_MODE=DOWN → 1=pressed)
    input  wire USER_KEY2,    // key2 (H10, PULL_MODE=DOWN → 1=pressed)
    // Matrix LED interface
    output wire SIN1,         // Row select serial data  (A11)
    output wire SIN2,         // Column data [15:0]      (A10)
    output wire SIN3,         // Column data [31:16]     (E10)
    output wire LATCH,        // Data latch              (E11)
    output wire LED_CLK,      // Shift-register clock    (K11)
    output wire STROBE_       // Display strobe (active-low) (L5)
);

// ---------------------------------------------------------------------------
// PLL  (user supplies the IP; expected output: 25 MHz game clock)
// See pll_spec.md for required PLL parameters.
// The PLL module name is assumed to be "pll_25m".
// ---------------------------------------------------------------------------
wire clk_25m;
wire pll_lock;

pll_25m u_pll (
    .clkin   (clk),
    .clkout  (clk_25m),
    .lock    (pll_lock)
);

// ---------------------------------------------------------------------------
// Reset  – hold reset until PLL locks, then release after 16 cycles
// ---------------------------------------------------------------------------
reg [3:0] rst_cnt = 4'hF;
wire      rst_n   = (rst_cnt == 4'h0);

always @(posedge clk_25m) begin
    if (!pll_lock)
        rst_cnt <= 4'hF;
    else if (rst_cnt != 4'h0)
        rst_cnt <= rst_cnt - 1'b1;
end

// ---------------------------------------------------------------------------
// Key interface registers (unused physical keys mapped for future use)
// The physical buttons available today are USER_KEY / USER_KEY2.
// We map them to "left" and "right" as a demo.  All other keys are wired
// to 0 until external hardware is added.
// ---------------------------------------------------------------------------
wire key_left  = USER_KEY;   // H11
wire key_right = USER_KEY2;  // H10
wire key_down  = 1'b0;
wire key_rot_r = 1'b0;
wire key_rot_l = 1'b0;

// ---------------------------------------------------------------------------
// Framebuffer  64 rows × 16 cols, 1 bpp
// Row 0 = top of physical display
// ---------------------------------------------------------------------------
wire [15:0] fb_row [0:63];   // framebuffer output from game engine

// ---------------------------------------------------------------------------
// Game engine
// ---------------------------------------------------------------------------
tetris_engine u_engine (
    .clk      (clk_25m),
    .rst_n    (rst_n),
    .key_left (key_left),
    .key_right(key_right),
    .key_down (key_down),
    .key_rot_r(key_rot_r),
    .key_rot_l(key_rot_l),
    .fb_row0  (fb_row[0]),
    .fb_row1  (fb_row[1]),
    .fb_row2  (fb_row[2]),
    .fb_row3  (fb_row[3]),
    .fb_row4  (fb_row[4]),
    .fb_row5  (fb_row[5]),
    .fb_row6  (fb_row[6]),
    .fb_row7  (fb_row[7]),
    .fb_row8  (fb_row[8]),
    .fb_row9  (fb_row[9]),
    .fb_row10 (fb_row[10]),
    .fb_row11 (fb_row[11]),
    .fb_row12 (fb_row[12]),
    .fb_row13 (fb_row[13]),
    .fb_row14 (fb_row[14]),
    .fb_row15 (fb_row[15]),
    .fb_row16 (fb_row[16]),
    .fb_row17 (fb_row[17]),
    .fb_row18 (fb_row[18]),
    .fb_row19 (fb_row[19]),
    .fb_row20 (fb_row[20]),
    .fb_row21 (fb_row[21]),
    .fb_row22 (fb_row[22]),
    .fb_row23 (fb_row[23]),
    .fb_row24 (fb_row[24]),
    .fb_row25 (fb_row[25]),
    .fb_row26 (fb_row[26]),
    .fb_row27 (fb_row[27]),
    .fb_row28 (fb_row[28]),
    .fb_row29 (fb_row[29]),
    .fb_row30 (fb_row[30]),
    .fb_row31 (fb_row[31]),
    .fb_row32 (fb_row[32]),
    .fb_row33 (fb_row[33]),
    .fb_row34 (fb_row[34]),
    .fb_row35 (fb_row[35]),
    .fb_row36 (fb_row[36]),
    .fb_row37 (fb_row[37]),
    .fb_row38 (fb_row[38]),
    .fb_row39 (fb_row[39]),
    .fb_row40 (fb_row[40]),
    .fb_row41 (fb_row[41]),
    .fb_row42 (fb_row[42]),
    .fb_row43 (fb_row[43]),
    .fb_row44 (fb_row[44]),
    .fb_row45 (fb_row[45]),
    .fb_row46 (fb_row[46]),
    .fb_row47 (fb_row[47]),
    .fb_row48 (fb_row[48]),
    .fb_row49 (fb_row[49]),
    .fb_row50 (fb_row[50]),
    .fb_row51 (fb_row[51]),
    .fb_row52 (fb_row[52]),
    .fb_row53 (fb_row[53]),
    .fb_row54 (fb_row[54]),
    .fb_row55 (fb_row[55]),
    .fb_row56 (fb_row[56]),
    .fb_row57 (fb_row[57]),
    .fb_row58 (fb_row[58]),
    .fb_row59 (fb_row[59]),
    .fb_row60 (fb_row[60]),
    .fb_row61 (fb_row[61]),
    .fb_row62 (fb_row[62]),
    .fb_row63 (fb_row[63])
);

// ---------------------------------------------------------------------------
// LED driver
// ---------------------------------------------------------------------------
led_driver u_led (
    .clk      (clk_25m),
    .rst_n    (rst_n),
    .fb_row0  (fb_row[0]),
    .fb_row1  (fb_row[1]),
    .fb_row2  (fb_row[2]),
    .fb_row3  (fb_row[3]),
    .fb_row4  (fb_row[4]),
    .fb_row5  (fb_row[5]),
    .fb_row6  (fb_row[6]),
    .fb_row7  (fb_row[7]),
    .fb_row8  (fb_row[8]),
    .fb_row9  (fb_row[9]),
    .fb_row10 (fb_row[10]),
    .fb_row11 (fb_row[11]),
    .fb_row12 (fb_row[12]),
    .fb_row13 (fb_row[13]),
    .fb_row14 (fb_row[14]),
    .fb_row15 (fb_row[15]),
    .fb_row16 (fb_row[16]),
    .fb_row17 (fb_row[17]),
    .fb_row18 (fb_row[18]),
    .fb_row19 (fb_row[19]),
    .fb_row20 (fb_row[20]),
    .fb_row21 (fb_row[21]),
    .fb_row22 (fb_row[22]),
    .fb_row23 (fb_row[23]),
    .fb_row24 (fb_row[24]),
    .fb_row25 (fb_row[25]),
    .fb_row26 (fb_row[26]),
    .fb_row27 (fb_row[27]),
    .fb_row28 (fb_row[28]),
    .fb_row29 (fb_row[29]),
    .fb_row30 (fb_row[30]),
    .fb_row31 (fb_row[31]),
    .fb_row32 (fb_row[32]),
    .fb_row33 (fb_row[33]),
    .fb_row34 (fb_row[34]),
    .fb_row35 (fb_row[35]),
    .fb_row36 (fb_row[36]),
    .fb_row37 (fb_row[37]),
    .fb_row38 (fb_row[38]),
    .fb_row39 (fb_row[39]),
    .fb_row40 (fb_row[40]),
    .fb_row41 (fb_row[41]),
    .fb_row42 (fb_row[42]),
    .fb_row43 (fb_row[43]),
    .fb_row44 (fb_row[44]),
    .fb_row45 (fb_row[45]),
    .fb_row46 (fb_row[46]),
    .fb_row47 (fb_row[47]),
    .fb_row48 (fb_row[48]),
    .fb_row49 (fb_row[49]),
    .fb_row50 (fb_row[50]),
    .fb_row51 (fb_row[51]),
    .fb_row52 (fb_row[52]),
    .fb_row53 (fb_row[53]),
    .fb_row54 (fb_row[54]),
    .fb_row55 (fb_row[55]),
    .fb_row56 (fb_row[56]),
    .fb_row57 (fb_row[57]),
    .fb_row58 (fb_row[58]),
    .fb_row59 (fb_row[59]),
    .fb_row60 (fb_row[60]),
    .fb_row61 (fb_row[61]),
    .fb_row62 (fb_row[62]),
    .fb_row63 (fb_row[63]),
    .SIN1     (SIN1),
    .SIN2     (SIN2),
    .SIN3     (SIN3),
    .LATCH    (LATCH),
    .LED_CLK  (LED_CLK),
    .STROBE_  (STROBE_)
);

endmodule
