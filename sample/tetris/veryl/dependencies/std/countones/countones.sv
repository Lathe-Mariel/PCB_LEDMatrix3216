module __std_countones #(
    parameter  int unsigned W     = 16                                   ,
    localparam int unsigned CLOGW = ((W > 1) ? ( $clog2(W) + 1 ) : ( 1 ))
) (
    input  var logic [W-1:0]     i_data,
    output var logic [CLOGW-1:0] o_ones
);
    if ((W == 1)) begin :gen_base_case
        always_comb o_ones = i_data;
    end else begin :gen_rec_case
        localparam int unsigned            WBOT     = W / 2;
        localparam int unsigned            WTOP     = W - WBOT;
        logic        [WBOT-1:0] data_bot; always_comb data_bot = i_data[WBOT - 1:0];
        logic        [WTOP-1:0] data_top; always_comb data_top = i_data[W - 1:WBOT];

        localparam int unsigned                CLOGWBOT = ((WBOT > 1) ? ( $clog2(WBOT) + 1 ) : ( 1 ));
        localparam int unsigned                CLOGWTOP = ((WTOP > 1) ? ( $clog2(WTOP) + 1 ) : ( 1 ));
        logic        [CLOGWBOT-1:0] ones_bot;
        logic        [CLOGWTOP-1:0] ones_top;

        __std_countones #(
            .W (WBOT)
        ) u_bot (
            .i_data (data_bot),
            .o_ones (ones_bot)
        );
        __std_countones #(
            .W (WTOP)
        ) u_top (
            .i_data (data_top),
            .o_ones (ones_top)
        );
        always_comb o_ones = {{(W - WTOP){1'b0}}, ones_top} + {{(W - WBOT){1'b0}}, ones_bot};
        // initial {
        //     $monitor("i_data: %b, data_top: %b, data_bot: %b\n", i_data, data_top, data_bot, "o_ones: %d, ones_top: %d, ones_bot: %d\n", o_ones, ones_top, ones_bot);
        // }
    end
endmodule

`ifdef __veryl_test_tetris_test_countones__
    `ifdef __veryl_wavedump_tetris_test_countones__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_countones.vcd");
                $dumpvars();
            end
        endmodule
    `endif
`ifndef SYNTHESIS
module test_countones;

  parameter MIN = 1;
  parameter MAX = 20;
  logic [MAX:MIN] done;

  // initial begin $display("Hello, World!\n"); $finish; end
  for (genvar i = MIN; i <= MAX; ++i) begin : gen_duts
    bit [i-1:0] i_data;
    logic [((i > 1) ? $clog2(i) : 0):0] o_ones;
    std_countones #(i) u_dut(.*);

    initial begin
      done[i] = 1'b0;
      for (int j = 0; j < (1 << i); ++j) begin
        i_data = j;
        #1;
        assert(o_ones == $countones(i_data)) else begin
          $display("Expected %d, but got %d ones in %b of length %d", $countones(i_data), o_ones, i_data, i);
        end
      end
      $display("Done verifying countones#(%2d)", i);
      done[i] = 1'b1;
    end
  end

  always_comb begin
    if (done == '1)
      $finish;
  end

endmodule
`endif
`endif
//# sourceMappingURL=countones.sv.map
