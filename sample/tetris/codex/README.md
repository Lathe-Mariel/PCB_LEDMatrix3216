# 16x64 vertical Tetris for Tang Primer 25K

Files:

- `rtl/matrix_led_top.v`: top-level RTL for the LED matrix and game logic.
- `constraints/tang_primer_25k_pmod1_led_matrix.cst`: physical constraints for the display signals.

Design summary:

- Target clock: 50 MHz
- Physical panel drive: 16 rows x 64 columns
- Logical game screen: 16 dots wide x 64 dots tall
- Playfield: left 8 dots x 64 dots
- Next preview: right side, 4 dots x 4 dots
- Score: right side lower area, 5 digits shown with a rotated 5x3 font
- Brightness control: 2-bit BAM (4 levels including off)

Game mapping:

- The playfield is implemented as an 8 x 64 cell board.
- Each cell uses 1 dot x 1 dot.
- Tetrominoes are standard 4x4 masks.
- Gravity is 0.5 s per row.
- Soft drop repeats while `KEY_DOWN` is held.

Score:

- 1 cleared line: +1
- 2 cleared lines: +4
- 3 cleared lines: +16
- 4 cleared lines: +256

Display and I/O notes:

- `SIN1` shifts two cascaded 16-bit row-select words, one per 16x32 half.
- Vertical column order is mapped as `SIN3[15:0]`, `SIN2[15:0]`, `SIN3[31:16]`, `SIN2[31:16]`.
- `LATCH` captures the shift registers after 32 serial clocks.
- `STROBE_` is active low and is used as the display enable during the row hold time.
- `USER_KEY` resets the game state while pressed.
- `KEY_LEFT`, `KEY_RIGHT`, `KEY_DOWN`, `BTN_A`, and `BTN_B` are top-level input ports for control.
- No pin assignments were added for those control inputs in the provided `.cst` file.

Control behavior:

- `KEY_LEFT`: move left on rising edge
- `KEY_RIGHT`: move right on rising edge
- `KEY_DOWN`: soft drop while held
- `BTN_A`: rotate right on rising edge
- `BTN_B`: rotate left on rising edge

Integration:

1. Add `rtl/matrix_led_top.v` to the Gowin project as the top module.
2. Add `constraints/tang_primer_25k_pmod1_led_matrix.cst` to the project.
3. Add pin constraints for `KEY_LEFT`, `KEY_RIGHT`, `KEY_DOWN`, `BTN_A`, and `BTN_B` if you want live controls.

Because no Verilog toolchain is available in this workspace, the file has not been compiled locally.
