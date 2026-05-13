



`ifdef __veryl_test_tetris_test_extend__
    `ifdef __veryl_wavedump_tetris_test_extend__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_extend.vcd");
                $dumpvars();
            end
        endmodule
    `endif

`endif
//# sourceMappingURL=extend.sv.map
