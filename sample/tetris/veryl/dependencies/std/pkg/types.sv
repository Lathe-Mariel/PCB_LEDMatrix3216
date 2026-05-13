/// A package for pre-defined types
package __std_types;
    typedef logic [8-1:0]  ul8 ; /// 8 bits unsigned logic vector
    typedef logic [16-1:0] ul16; /// 16 bits unsigned logic vector
    typedef logic [32-1:0] ul32; /// 32 bits unsigned logic vector
    typedef logic [64-1:0] ul64; /// 64 bits unsigned logic vector

    typedef logic signed [8-1:0]  il8 ; /// 8 bits signed logic vector
    typedef logic signed [16-1:0] il16; /// 16 bits signed logic vector
    typedef logic signed [32-1:0] il32; /// 32 bits signed logic vector
    typedef logic signed [64-1:0] il64; /// 64 bits signed logic vector

    typedef bit [8-1:0]  ub8 ; /// 8 bits unsigned bit vector
    typedef bit [16-1:0] ub16; /// 16 bits unsigned bit vector
    typedef bit [32-1:0] ub32; /// 32 bits unsigned bit vector
    typedef bit [64-1:0] ub64; /// 64 bits unsigned bit vector

    typedef bit signed [8-1:0]  ib8 ; /// 8 bits signed bit vector
    typedef bit signed [16-1:0] ib16; /// 16 bits signed bit vector
    typedef bit signed [32-1:0] ib32; /// 32 bits signed bit vector
    typedef bit signed [64-1:0] ib64; /// 64 bits signed bit vector
endpackage

`ifdef __veryl_test_tetris_test_std_types_pkg__
    `ifdef __veryl_wavedump_tetris_test_std_types_pkg__
        module __veryl_wavedump;
            initial begin
                $dumpfile("test_std_types_pkg.vcd");
                $dumpvars();
            end
        endmodule
    `endif
`ifndef SYNTHESIS
module test_std_types_pkg;
    std_types::ul8  a;
    std_types::ul16 b;
    std_types::ul32 c;
    std_types::ul64 d;

    std_types::il8  e;
    std_types::il16 f;
    std_types::il32 g;
    std_types::il64 h;

    std_types::ub8  i;
    std_types::ub16 j;
    std_types::ub32 k;
    std_types::ub64 l;

    std_types::ib8  m;
    std_types::ib16 n;
    std_types::ib32 o;
    std_types::ib64 p;

    `define test_unsigned_logic(VARIABLE, WIDTH) \
    begin \
        assert($bits(VARIABLE) == WIDTH) \
        else $error("error detected"); \
        VARIABLE = '0; \
        VARIABLE[WIDTH-1] = '1; \
        assert(VARIABLE > 0) \
        else $error("error detected"); \
        `ifndef VERILATOR \
            VARIABLE = 'x; \
            assert(VARIABLE === 'x) \
            else $error("error detected"); \
        `endif \
    end

    `define test_signed_logic(VARIABLE, WIDTH) \
    begin \
        assert($bits(VARIABLE) == WIDTH) \
        else $error("error detected"); \
        VARIABLE = '0; \
        VARIABLE[WIDTH-1] = '1; \
        assert(VARIABLE < 0) \
        else $error("error detected"); \
        `ifndef VERILATOR \
            VARIABLE = 'x; \
            assert(VARIABLE === 'x) \
            else $error("error detected"); \
        `endif \
    end

    `define test_unsigned_bit(VARIABLE, WIDTH) \
    begin \
        assert($bits(VARIABLE) == WIDTH) \
        else $error("error detected"); \
        VARIABLE = '0; \
        VARIABLE[WIDTH-1] = '1; \
        assert(VARIABLE > 0) \
        else $error("error detected"); \
        `ifndef VERILATOR \
            VARIABLE = 'x; \
            assert((!$isunknown(VARIABLE)) && (VARIABLE == '0)) \
            else $error("error detected"); \
        `endif \
    end

    `define test_signed_bit(VARIABLE, WIDTH) \
    begin \
        assert($bits(VARIABLE) == WIDTH) \
        else $error("error detected"); \
        VARIABLE = '0; \
        VARIABLE[WIDTH-1] = '1; \
        assert(VARIABLE < 0) \
        else $error("error detected"); \
        `ifndef VERILATOR \
            VARIABLE = 'x; \
            assert((!$isunknown(VARIABLE)) && (VARIABLE == '0)) \
            else $error("error detected"); \
        `endif \
    end

    initial begin
        `test_unsigned_logic(a, 8)
        `test_unsigned_logic(b, 16)
        `test_unsigned_logic(c, 32)
        `test_unsigned_logic(d, 64)

        `test_signed_logic(e, 8)
        `test_signed_logic(f, 16)
        `test_signed_logic(g, 32)
        `test_signed_logic(h, 64)

        `test_unsigned_bit(i, 8)
        `test_unsigned_bit(j, 16)
        `test_unsigned_bit(k, 32)
        `test_unsigned_bit(l, 64)

        `test_signed_bit(m, 8)
        `test_signed_bit(n, 16)
        `test_signed_bit(o, 32)
        `test_signed_bit(p, 64)

        $finish;
    end
endmodule
`endif
`endif
//# sourceMappingURL=types.sv.map
