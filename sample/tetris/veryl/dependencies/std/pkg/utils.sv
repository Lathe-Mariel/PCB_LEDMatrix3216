package __std_utils;
    function automatic int unsigned clog2_clipped(
        input var int unsigned x  ,
        input var int unsigned min
    ) ;
        int unsigned result;
        result = $clog2(x);
        return ((result > min) ? ( result ) : ( min ));
    endfunction
endpackage

`ifdef __veryl_test_tetris_test_utils_clog2_clipped__
    `ifdef __veryl_wavedump_tetris_test_utils_clog2_clipped__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_utils_clog2_clipped.vcd");
                $dumpvars();
            end
        endmodule
    `endif

`endif
//# sourceMappingURL=utils.sv.map
