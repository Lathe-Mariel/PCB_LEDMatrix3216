/// Basic synchronizer implementation using single-bit FF scheme
module __std_synchronizer_basic #(
    parameter int unsigned             WIDTH         = 8 ,
    parameter bit          [WIDTH-1:0] INITIAL_VALUE = '0,
    parameter int unsigned             STAGES        = 2 
) (
    input  var logic             i_clk,
    input  var logic             i_rst,
    input  var logic [WIDTH-1:0] i_d  ,
    output var logic [WIDTH-1:0] o_d  
);
    for (genvar i = 0; i < WIDTH; i++) begin :g
        logic [STAGES-1:0] rg;

        always_comb begin
            o_d[i] = rg[($size(rg, 1) - 1)];
        end

        always_ff @ (posedge i_clk, negedge i_rst) begin
            if (!i_rst) begin
                rg <= {STAGES{INITIAL_VALUE[i]}};
            end else begin
                rg <= STAGES'({rg, i_d[i]});
            end
        end

    end
endmodule

`ifdef __veryl_test_tetris_test_synchronizer_basic__
    `ifdef __veryl_wavedump_tetris_test_synchronizer_basic__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_synchronizer_basic.vcd");
                $dumpvars();
            end
        endmodule
    `endif
`ifndef SYNTHESIS
module test_synchronizer_basic;
`ifndef VERILATOR
    timeunit 1ns/1ps;

    localparam int WIDTH  = 8;
    localparam int STAGES = 2;

    bit               clk_s;
    bit               clk_d;
    bit               rst_n;
    bit               do_check;
    logic [WIDTH-1:0] d;
    logic [WIDTH-1:0] q;

    always #(501ps) begin
        clk_s ^= 1;
    end

    always #(500ps) begin
        clk_d ^= 1;
    end

    initial begin
        rst_n    = 1;
        do_check = 0;
        @(posedge clk_d);
        rst_n = 0;
        @(posedge clk_d);
        @(posedge clk_d);
        rst_n = 1;

        repeat (STAGES) begin
        @(posedge clk_d);
        end
        do_check = 1;

        repeat (200) begin
        @(posedge clk_d);
        end
        $finish;
    end

    always @(posedge clk_s) begin
        d <= $urandom;
    end

    ast_match_data:
    assert property (
        @(posedge clk_d) disable iff (!do_check)
        q == $past(d, STAGES)
    );

    std_synchronizer_basic duv (
        .i_clk (clk_d),
        .i_rst (rst_n),
        .i_d   (d    ),
        .o_d   (q    )
    );
`endif
endmodule
`endif
`endif
//# sourceMappingURL=synchronizer_basic.sv.map
