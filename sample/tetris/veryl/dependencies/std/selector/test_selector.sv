`ifdef __veryl_test_tetris_test_binary_mux__
    `ifdef __veryl_wavedump_tetris_test_binary_mux__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_binary_mux.vcd");
                $dumpvars();
            end
        endmodule
    `endif

`endif

`ifdef __veryl_test_tetris_test_vector_mux__
    `ifdef __veryl_wavedump_tetris_test_vector_mux__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_vector_mux.vcd");
                $dumpvars();
            end
        endmodule
    `endif

`endif

`ifdef __veryl_test_tetris_test_onehot_mux__
    `ifdef __veryl_wavedump_tetris_test_onehot_mux__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_onehot_mux.vcd");
                $dumpvars();
            end
        endmodule
    `endif

`endif
//# sourceMappingURL=test_selector.sv.map
