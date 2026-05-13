/// Converts a binary encoded bit vector to a Gray encoded bit-vector
/// * Space Complexity: O(WIDTH)
/// * Time Complexity: O(1)
module __std_gray_encoder #(
    /// Input and output bit vector width
    parameter int unsigned WIDTH = 32
) (
    /// Input Binary encoded Bit Vector
    input var logic [WIDTH-1:0] i_bin,
    /// Output Gray encoded Bit Vector
    output var logic [WIDTH-1:0] o_gray
);
    always_comb o_gray = i_bin ^ (i_bin >> 1);
endmodule

`ifdef __veryl_test_tetris_test_gray__
    `ifdef __veryl_wavedump_tetris_test_gray__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_gray.vcd");
                $dumpvars();
            end
        endmodule
    `endif
`ifndef SYNTHESIS
module test_gray;
  localparam WIDTH = 16;
  logic [WIDTH-1:0] i_bin;
  logic [WIDTH-1:0] o_gray;
  logic [WIDTH-1:0] o_bin;
  logic [WIDTH-1:0] g_bin;

  always_comb begin
    g_bin = '0;
    for (int i = 0; i < WIDTH; ++i) begin
      g_bin ^= o_gray >> i;
    end
  end

  std_gray_encoder #(WIDTH) dut2(.i_bin, .o_gray);
  std_gray_decoder #(WIDTH) dut1(.i_gray(o_gray), .o_bin);

  initial begin
    for (longint i = 0; i < (1 << WIDTH); ++i) begin
      i_bin = i;
      #1;
      assert(o_bin == g_bin) else $error("error detected");
      assert(i_bin == o_bin) else $error("error detected");
      #1;
    end
  end

endmodule
`endif
`endif
//# sourceMappingURL=gray_encoder.sv.map
