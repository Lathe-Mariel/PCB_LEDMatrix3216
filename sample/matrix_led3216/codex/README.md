# LED matrix scroller for Tang Primer 25K

Files:

- `rtl/matrix_led_top.v`: top-level RTL for the 16x32 LED matrix.
- `constraints/tang_primer_25k_pmod1_led_matrix.cst`: physical constraints for Pmod port 1.

Design summary:

- Target clock: 50 MHz
- Display size: 16 rows x 32 columns
- Text: `Write once, run anywhere`
- Scroll speed: 1 pixel every 100 ms
- Brightness control: 2-bit BAM (4 levels including off)

Implementation notes:

- The text uses an 8x8 bitmap font expanded 2x in the vertical direction to fill 16 rows.
- `SIN1` shifts the active row select word.
- `SIN2` shifts columns 31..16.
- `SIN3` shifts columns 15..0.
- `LATCH` captures the three shift registers after 16 serial clocks.
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
