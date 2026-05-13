module __std_onehot #(
    parameter int unsigned W = 16
) (
    input var logic [W-1:0] i_data,
    /// 1'b1 iff i_data contains exactly one set bit
    output var logic o_onehot,
    /// 1'b1 iff i_data is zero
    output var logic o_zero
);
    logic o_gt_one;

    __std__onehot #(
        .W (W)
    ) u_onehot (
        .i_data   (i_data  ),
        .o_zero   (o_zero  ),
        .o_onehot (o_onehot),
        .o_gt_one (o_gt_one)
    );
endmodule

module __std__onehot #(
    parameter int unsigned W = 16
) (
    input  var logic [W-1:0] i_data  ,
    output var logic         o_onehot,
    output var logic         o_zero  ,
    output var logic         o_gt_one
);
    if ((W == 1)) begin :gen_base_case
        always_comb o_onehot = i_data;
        always_comb o_zero   = ~i_data;
    end else begin :gen_rec_case
        localparam int unsigned            WBOT       = W / 2;
        localparam int unsigned            WTOP       = W - WBOT;
        logic        [WBOT-1:0] data_bot  ; always_comb data_bot   = i_data[WBOT - 1:0];
        logic        [WTOP-1:0] data_top  ; always_comb data_top   = i_data[W - 1:WBOT];
        logic                   onehot_top;
        logic                   onehot_bot;
        logic                   zero_top  ;
        logic                   zero_bot  ;
        logic                   gt_one_top;
        logic                   gt_one_bot;

        __std__onehot #(
            .W (WBOT)
        ) u_bot (
            .i_data   (data_bot  ),
            .o_onehot (onehot_bot),
            .o_zero   (zero_bot  ),
            .o_gt_one (gt_one_bot)
        );
        __std__onehot #(
            .W (WTOP)
        ) u_top (
            .i_data   (data_top  ),
            .o_onehot (onehot_top),
            .o_zero   (zero_top  ),
            .o_gt_one (gt_one_top)
        );
        always_comb o_zero   = zero_top & zero_bot;
        always_comb o_onehot = (onehot_top ^ onehot_bot) & ~gt_one_top & ~gt_one_bot;
        always_comb o_gt_one = gt_one_top | gt_one_bot | (onehot_top & onehot_bot);
    end

endmodule

`ifdef __veryl_test_tetris_test_onehot__
    `ifdef __veryl_wavedump_tetris_test_onehot__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_onehot.vcd");
                $dumpvars();
            end
        endmodule
    `endif
`ifndef SYNTHESIS
module test_onehot;

  parameter MIN = 1;
  parameter MAX = 20;
  logic [MAX:MIN] done;

  // initial begin $display("Hello, World!\n"); $finish; end
  for (genvar i = MIN; i <= MAX; ++i) begin : gen_duts
    bit [i-1:0] i_data;
    logic o_onehot, o_zero;
    std_onehot #(i) u_dut(.*);

    initial begin
      done[i] = 1'b0;
      for (int j = 0; j < (1 << i); ++j) begin
        i_data = j;
        #1;
        assert(o_onehot == $onehot(i_data)) else begin
          $display("$onehot(%b) == %b of len %d", i_data, o_onehot, i);
        end
        assert(o_zero == (i_data == '0)) else begin
          $display("zero(%b) == %b of len %d", i_data, o_zero, i_data, i);
        end
      end
      $display("Done verifying onehot#(%2d)", i);
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
//# sourceMappingURL=onehot.sv.map
