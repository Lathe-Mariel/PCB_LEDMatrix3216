# LED matrix scroller for Tang Primer 25K

Files:

- `rtl/matrix_led_top.v`: top-level RTL for the 16x128 LED matrix.
- `constraints/tang_primer_25k_pmod1_led_matrix.cst`: physical constraints for Pmod port 1.

Design summary:

- Target clock: 50 MHz
- Display size: 16 rows x 128 columns
- Text: `Stanford University Network.`
- Scroll speed: 1 pixel every 100 ms
- Brightness control: 2-bit BAM (4 levels including off)

Implementation notes:

- The text uses an 8x8 bitmap font expanded 2x in the vertical direction to fill 16 rows.
- The scroller keeps a 16x128 registered display buffer and shifts in one new text column per scroll tick, which reduces LUT pressure compared with regenerating the whole row combinationally on every scan.
- `SIN1` shifts four identical 16-bit row-select words, one per 16x32 module.
- `SIN2` uses the 64-bit mapping `{[127:112],[95:80],[63:48],[31:16]}` and is shifted LSB first.
- `SIN3` uses the 64-bit mapping `{[111:96],[79:64],[47:32],[15:0]}` and is shifted LSB first.
- Horizontal column order is mapped as `SIN3[15:0]`, `SIN2[15:0]`, `SIN3[31:16]`, `SIN2[31:16]`, `SIN3[47:32]`, `SIN2[47:32]`, `SIN3[63:48]`, `SIN2[63:48]`.
- `LATCH` captures the three shift registers after 64 serial clocks.
- `STROBE_` is active low and is used as the display enable during the row hold time.

Tunables inside `matrix_led_top.v`:

- `ROW0_IS_TOP`: flip vertical orientation if the panel is upside down.
- `COL0_IS_LEFT`: flip horizontal orientation if the panel is mirrored.
- `SHIFT_MSB_FIRST`: change serial bit order if the panel expects LSB-first data.
- `BASE_ON_TICKS`: changes the row dwell time and therefore the overall brightness / refresh tradeoff.

Reset behavior:

- `USER_KEY` is treated as an active-low reset.

Integration:

1. Add `rtl/matrix_led_top.v` to the Gowin project as the top module.
2. Add `constraints/tang_primer_25k_pmod1_led_matrix.cst` to the project.
3. Build for the Tang Primer 25K device.

Because no Verilog toolchain is available in this workspace, the file has not been compiled locally.
