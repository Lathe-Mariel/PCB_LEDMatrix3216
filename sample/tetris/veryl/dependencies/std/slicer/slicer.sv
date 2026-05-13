module __std_slicer #(
    parameter int unsigned WIDTH           = 1                ,
    parameter type         TYPE            = logic [WIDTH-1:0],
    parameter int unsigned STAGES          = 1                ,
    parameter bit          ASCENDING_ORDER = 1'b1             ,
    parameter bit          FULL_BANDWIDTH  = 1'b1             ,
    parameter bit          DISABLE_MBFF    = 1'b0             ,
    parameter bit          USE_RESET       = 1'b0         
) (
    input  var logic i_clk  ,
    input  var logic i_rst  ,
    output var logic o_ready,
    input  var logic i_valid,
    input  var TYPE  i_data ,
    input  var logic i_ready,
    output var logic o_valid,
    output var TYPE  o_data 
);
    localparam int unsigned W = $bits(TYPE);

    logic         ready [STAGES + 1];
    logic         valid [STAGES + 1];
    logic [W-1:0] data  [STAGES + 1];

    if (ASCENDING_ORDER) begin :g
        always_comb begin
            o_ready  = ready[0];
            valid[0] = i_valid;
            data[0]  = i_data;
        end

        always_comb begin
            ready[STAGES] = i_ready;
            o_valid       = valid[STAGES];
            o_data        = data[STAGES];
        end

        for (genvar i = 0; i < STAGES; i++) begin :g
            localparam bit RESET = USE_RESET && (i == (STAGES - 1));

            if (FULL_BANDWIDTH) begin :g
                __std_slicer_unit_fb #(
                    .WIDTH        (W           ),
                    .DISABLE_MBFF (DISABLE_MBFF),
                    .USE_RESET    (RESET       )
                ) u_slicer (
                    .i_clk   (i_clk       ),
                    .i_rst   (i_rst       ),
                    .o_ready (ready[i + 0]),
                    .i_valid (valid[i + 0]),
                    .i_data  (data[i + 0] ),
                    .i_ready (ready[i + 1]),
                    .o_valid (valid[i + 1]),
                    .o_data  (data[i + 1] )
                );
            end else begin :g
                __std_slicer_unit_hb #(
                    .WIDTH        (W           ),
                    .DISABLE_MBFF (DISABLE_MBFF),
                    .USE_RESET    (RESET       )
                ) u_slicer (
                    .i_clk   (i_clk       ),
                    .i_rst   (i_rst       ),
                    .o_ready (ready[i + 0]),
                    .i_valid (valid[i + 0]),
                    .i_data  (data[i + 0] ),
                    .i_ready (ready[i + 1]),
                    .o_valid (valid[i + 1]),
                    .o_data  (data[i + 1] )
                );
            end
        end
    end else begin :g
        always_comb begin
            o_ready       = ready[STAGES];
            valid[STAGES] = i_valid;
            data[STAGES]  = i_data;
        end

        always_comb begin
            ready[0] = i_ready;
            o_valid  = valid[0];
            o_data   = data[0];
        end

        for (genvar i = 0; i < STAGES; i++) begin :g
            localparam bit RESET = USE_RESET && (i == 0);

            if (FULL_BANDWIDTH) begin :g
                __std_slicer_unit_fb #(
                    .WIDTH        (W           ),
                    .DISABLE_MBFF (DISABLE_MBFF),
                    .USE_RESET    (RESET       )
                ) u_slicer (
                    .i_clk   (i_clk       ),
                    .i_rst   (i_rst       ),
                    .o_ready (ready[i + 1]),
                    .i_valid (valid[i + 1]),
                    .i_data  (data[i + 1] ),
                    .i_ready (ready[i + 0]),
                    .o_valid (valid[i + 0]),
                    .o_data  (data[i + 0] )
                );
            end else begin :g
                __std_slicer_unit_hb #(
                    .WIDTH        (W           ),
                    .DISABLE_MBFF (DISABLE_MBFF),
                    .USE_RESET    (RESET       )
                ) u_slicer (
                    .i_clk   (i_clk       ),
                    .i_rst   (i_rst       ),
                    .o_ready (ready[i + 1]),
                    .i_valid (valid[i + 1]),
                    .i_data  (data[i + 1] ),
                    .i_ready (ready[i + 0]),
                    .o_valid (valid[i + 0]),
                    .o_data  (data[i + 0] )
                );
            end
        end
    end
endmodule

`ifdef __veryl_test_tetris_test_std_slicer__
    `ifdef __veryl_wavedump_tetris_test_std_slicer__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_std_slicer.vcd");
                $dumpvars();
            end
        endmodule
    `endif
`ifndef SYNTHESIS
module test_std_slicer;
`ifndef VERILATOR
  timeunit 1ns/1ps;

  bit clk;
  bit rst_n;

  always #1 begin
    clk ^=1;
  end

  initial begin
    rst_n = 1;
    @(posedge clk);
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
  end

  bit       ready_a;
  bit       valid_a;
  bit [7:0] data_a;
  bit       ack_a;
  bit       ready_b;
  bit       valid_b;
  bit [7:0] data_b;
  bit       ready_c;
  bit       valid_c;
  bit [7:0] data_c;
  bit       ack_c;

  assign  ack_a = ready_a && valid_a;
  assign  ack_c = ready_c && valid_c;

  clocking cb @(posedge clk);
    input   ready_a;
    output  valid_a;
    output  data_a;
    input   ack_a;
    output  ready_c;
    input   valid_c;
    input   data_c;
    input   ack_c;
  endclocking

  initial begin
    cb.valid_a  <= '0;
    cb.data_a   <= '0;

    @(negedge rst_n);
    @(posedge rst_n);

    for (int i = 0;i < 10;++i) begin
      cb.valid_a  <= '1;
      cb.data_a   <= i;
      do begin
        @(cb);
      end while (!cb.ack_a);
    end

    cb.valid_a  <= '0;
    cb.data_a   <= '0;
  end

  initial begin
    cb.ready_c  <= '0;

    @(negedge rst_n);
    @(posedge rst_n);

    forever begin
      cb.ready_c  <= $urandom_range(0, 1);
      @(cb);
    end
  end

  initial begin
    for (int i = 0;i < 10;++i) begin
      do begin
        @(cb);
      end while (!cb.ack_c);

      assert (cb.data_c == i)
      else $error("data is not matched");
    end

    $finish;
  end

  std_slicer #(
    .WIDTH          (8  ),
    .STAGES         (2  ),
    .FULL_BANDWIDTH (1  )
  ) u_slicer_fb (
    .i_clk    (clk      ),
    .i_rst    (rst_n    ),
    .o_ready  (ready_a  ),
    .i_valid  (valid_a  ),
    .i_data   (data_a   ),
    .i_ready  (ready_b  ),
    .o_valid  (valid_b  ),
    .o_data   (data_b   )
  );

  std_slicer #(
    .WIDTH          (8  ),
    .STAGES         (2  ),
    .FULL_BANDWIDTH (0  )
  ) u_slicer_hb (
    .i_clk    (clk      ),
    .i_rst    (rst_n    ),
    .o_ready  (ready_b  ),
    .i_valid  (valid_b  ),
    .i_data   (data_b   ),
    .i_ready  (ready_c  ),
    .o_valid  (valid_c  ),
    .o_data   (data_c   )
  );
`endif
endmodule
`endif
`endif
//# sourceMappingURL=slicer.sv.map
