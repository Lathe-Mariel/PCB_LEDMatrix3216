package __std___lzc_pkg__4;
    localparam int unsigned COUNT_WIDTH       = ((4 >= 2) ? ( $clog2(4) ) : ( 1 ));
    localparam int unsigned COUNT_UPPER_WIDTH = ((4 > 64) ? ( COUNT_WIDTH - 6 ) : ( 1 ));
    localparam int unsigned N_SPLITS          = ((4 > 64) ? ( (4 + 63) / 64 ) : ( 2 )); // 2 is to prevent verilator warning

    typedef __std_lzc_common_pkg::__result__4                   lzc_result;
    typedef logic                               [COUNT_WIDTH-1:0] lzc_count ;

    function automatic lzc_result lzc(
        input var logic [4-1:0] bits    ,
        input var logic           from_msb
    ) ;
        logic      [4-1:0] input_bits;
        lzc_result           ret       ;

        if (from_msb) begin
            input_bits = __std___bit_reverse__4(bits);
        end else begin
            input_bits = bits;
        end

        if (4 <= 4) begin
            __std_lzc_common_pkg::__result__4 ret4        ;
            ret4         = __std_lzc_common_pkg::lzc4(4'(input_bits));
            ret.all_zero = ret4.all_zero;
            ret.count    = COUNT_WIDTH'(ret4.count);
        end else if (4 <= 8) begin
            __std_lzc_common_pkg::__result__8 ret8        ;
            ret8         = __std_lzc_common_pkg::lzc8(8'(input_bits));
            ret.all_zero = ret8.all_zero;
            ret.count    = ret8.count;
        end else if (4 <= 16) begin
            __std_lzc_common_pkg::__result__16 ret16       ;
            ret16        = __std_lzc_common_pkg::lzc16(16'(input_bits));
            ret.all_zero = ret16.all_zero;
            ret.count    = ret16.count;
        end else if (4 <= 32) begin
            __std_lzc_common_pkg::__result__32 ret32       ;
            ret32        = __std_lzc_common_pkg::lzc32(32'(input_bits));
            ret.all_zero = ret32.all_zero;
            ret.count    = ret32.count;
        end else if (4 <= 64) begin
            __std_lzc_common_pkg::__result__64 ret64       ;
            ret64        = __std_lzc_common_pkg::lzc64(64'(input_bits));
            ret.all_zero = ret64.all_zero;
            ret.count    = ret64.count;
        end else begin
            lzc_count [N_SPLITS-1:0] count   ;
            logic     [N_SPLITS-1:0] all_zero;

            for (int i = 0; i < N_SPLITS; i++) begin
                logic                              [64-1:0] bits64;
                __std_lzc_common_pkg::__result__64          ret64 ;

                bits64 = 64'((input_bits >> (64 * i)));
                ret64  = __std_lzc_common_pkg::lzc64(bits64);

                count[i]    = {COUNT_UPPER_WIDTH'(i), ret64.count};
                all_zero[i] = ret64.all_zero;
            end

            ret.all_zero = all_zero == '1;
            ret.count    = __std___select_vector__N_SPLITS__lzc_count(~all_zero, count);
        end

        return ret;
    endfunction

    function automatic logic [4-1:0] __std___bit_reverse__4(
        input var logic [4-1:0] bits
    ) ;
        logic [4-1:0] ret;

        for (int i = 0; i < 4; i++) begin
            ret[i] = bits[4 - i - 1];
        end

        return ret;
    endfunction
    function automatic lzc_count __std___select_vector__N_SPLITS__lzc_count(
        input var logic     [N_SPLITS-1:0] sel ,
        input var lzc_count [N_SPLITS-1:0] data
    ) ;
        localparam int unsigned DEPTH = $clog2(N_SPLITS);
        int unsigned                current_n;
        logic        [N_SPLITS-1:0] current_s;
        lzc_count    [N_SPLITS-1:0] current_d;
        int unsigned                next_n   ;
        logic        [N_SPLITS-1:0] next_s   ;
        lzc_count    [N_SPLITS-1:0] next_d   ;

        next_n = N_SPLITS;
        next_s = sel;
        next_d = data;
        for (int _i = 0; _i < DEPTH; _i++) begin
            current_n = next_n;
            current_s = next_s;
            current_d = next_d;

            next_n = (current_n / 2) + (current_n % 2);
            for (int j = 0; j < next_n; j++) begin
                logic select_even;

                if ((j + 1) == next_n && (current_n % 2) == 1) begin
                    select_even = 1'b1;
                end else begin
                    select_even = current_s[2 * j + 0];
                end

                if (select_even) begin
                    next_s[j] = current_s[2 * j + 0];
                    next_d[j] = current_d[2 * j + 0];
                end else begin
                    next_s[j] = current_s[2 * j + 1];
                    next_d[j] = current_d[2 * j + 1];
                end
            end
        end

        return next_d[0];
    endfunction
endpackage
package __std___lzc_pkg__8;
    localparam int unsigned COUNT_WIDTH       = ((8 >= 2) ? ( $clog2(8) ) : ( 1 ));
    localparam int unsigned COUNT_UPPER_WIDTH = ((8 > 64) ? ( COUNT_WIDTH - 6 ) : ( 1 ));
    localparam int unsigned N_SPLITS          = ((8 > 64) ? ( (8 + 63) / 64 ) : ( 2 )); // 2 is to prevent verilator warning

    typedef __std_lzc_common_pkg::__result__8                   lzc_result;
    typedef logic                               [COUNT_WIDTH-1:0] lzc_count ;

    function automatic lzc_result lzc(
        input var logic [8-1:0] bits    ,
        input var logic           from_msb
    ) ;
        logic      [8-1:0] input_bits;
        lzc_result           ret       ;

        if (from_msb) begin
            input_bits = __std___bit_reverse__8(bits);
        end else begin
            input_bits = bits;
        end

        if (8 <= 4) begin
            __std_lzc_common_pkg::__result__4 ret4        ;
            ret4         = __std_lzc_common_pkg::lzc4(4'(input_bits));
            ret.all_zero = ret4.all_zero;
            ret.count    = COUNT_WIDTH'(ret4.count);
        end else if (8 <= 8) begin
            __std_lzc_common_pkg::__result__8 ret8        ;
            ret8         = __std_lzc_common_pkg::lzc8(8'(input_bits));
            ret.all_zero = ret8.all_zero;
            ret.count    = ret8.count;
        end else if (8 <= 16) begin
            __std_lzc_common_pkg::__result__16 ret16       ;
            ret16        = __std_lzc_common_pkg::lzc16(16'(input_bits));
            ret.all_zero = ret16.all_zero;
            ret.count    = ret16.count;
        end else if (8 <= 32) begin
            __std_lzc_common_pkg::__result__32 ret32       ;
            ret32        = __std_lzc_common_pkg::lzc32(32'(input_bits));
            ret.all_zero = ret32.all_zero;
            ret.count    = ret32.count;
        end else if (8 <= 64) begin
            __std_lzc_common_pkg::__result__64 ret64       ;
            ret64        = __std_lzc_common_pkg::lzc64(64'(input_bits));
            ret.all_zero = ret64.all_zero;
            ret.count    = ret64.count;
        end else begin
            lzc_count [N_SPLITS-1:0] count   ;
            logic     [N_SPLITS-1:0] all_zero;

            for (int i = 0; i < N_SPLITS; i++) begin
                logic                              [64-1:0] bits64;
                __std_lzc_common_pkg::__result__64          ret64 ;

                bits64 = 64'((input_bits >> (64 * i)));
                ret64  = __std_lzc_common_pkg::lzc64(bits64);

                count[i]    = {COUNT_UPPER_WIDTH'(i), ret64.count};
                all_zero[i] = ret64.all_zero;
            end

            ret.all_zero = all_zero == '1;
            ret.count    = __std___select_vector__N_SPLITS__lzc_count(~all_zero, count);
        end

        return ret;
    endfunction

    function automatic logic [8-1:0] __std___bit_reverse__8(
        input var logic [8-1:0] bits
    ) ;
        logic [8-1:0] ret;

        for (int i = 0; i < 8; i++) begin
            ret[i] = bits[8 - i - 1];
        end

        return ret;
    endfunction
    function automatic lzc_count __std___select_vector__N_SPLITS__lzc_count(
        input var logic     [N_SPLITS-1:0] sel ,
        input var lzc_count [N_SPLITS-1:0] data
    ) ;
        localparam int unsigned DEPTH = $clog2(N_SPLITS);
        int unsigned                current_n;
        logic        [N_SPLITS-1:0] current_s;
        lzc_count    [N_SPLITS-1:0] current_d;
        int unsigned                next_n   ;
        logic        [N_SPLITS-1:0] next_s   ;
        lzc_count    [N_SPLITS-1:0] next_d   ;

        next_n = N_SPLITS;
        next_s = sel;
        next_d = data;
        for (int _i = 0; _i < DEPTH; _i++) begin
            current_n = next_n;
            current_s = next_s;
            current_d = next_d;

            next_n = (current_n / 2) + (current_n % 2);
            for (int j = 0; j < next_n; j++) begin
                logic select_even;

                if ((j + 1) == next_n && (current_n % 2) == 1) begin
                    select_even = 1'b1;
                end else begin
                    select_even = current_s[2 * j + 0];
                end

                if (select_even) begin
                    next_s[j] = current_s[2 * j + 0];
                    next_d[j] = current_d[2 * j + 0];
                end else begin
                    next_s[j] = current_s[2 * j + 1];
                    next_d[j] = current_d[2 * j + 1];
                end
            end
        end

        return next_d[0];
    endfunction
endpackage
package __std___lzc_pkg__16;
    localparam int unsigned COUNT_WIDTH       = ((16 >= 2) ? ( $clog2(16) ) : ( 1 ));
    localparam int unsigned COUNT_UPPER_WIDTH = ((16 > 64) ? ( COUNT_WIDTH - 6 ) : ( 1 ));
    localparam int unsigned N_SPLITS          = ((16 > 64) ? ( (16 + 63) / 64 ) : ( 2 )); // 2 is to prevent verilator warning

    typedef __std_lzc_common_pkg::__result__16                   lzc_result;
    typedef logic                               [COUNT_WIDTH-1:0] lzc_count ;

    function automatic lzc_result lzc(
        input var logic [16-1:0] bits    ,
        input var logic           from_msb
    ) ;
        logic      [16-1:0] input_bits;
        lzc_result           ret       ;

        if (from_msb) begin
            input_bits = __std___bit_reverse__16(bits);
        end else begin
            input_bits = bits;
        end

        if (16 <= 4) begin
            __std_lzc_common_pkg::__result__4 ret4        ;
            ret4         = __std_lzc_common_pkg::lzc4(4'(input_bits));
            ret.all_zero = ret4.all_zero;
            ret.count    = COUNT_WIDTH'(ret4.count);
        end else if (16 <= 8) begin
            __std_lzc_common_pkg::__result__8 ret8        ;
            ret8         = __std_lzc_common_pkg::lzc8(8'(input_bits));
            ret.all_zero = ret8.all_zero;
            ret.count    = ret8.count;
        end else if (16 <= 16) begin
            __std_lzc_common_pkg::__result__16 ret16       ;
            ret16        = __std_lzc_common_pkg::lzc16(16'(input_bits));
            ret.all_zero = ret16.all_zero;
            ret.count    = ret16.count;
        end else if (16 <= 32) begin
            __std_lzc_common_pkg::__result__32 ret32       ;
            ret32        = __std_lzc_common_pkg::lzc32(32'(input_bits));
            ret.all_zero = ret32.all_zero;
            ret.count    = ret32.count;
        end else if (16 <= 64) begin
            __std_lzc_common_pkg::__result__64 ret64       ;
            ret64        = __std_lzc_common_pkg::lzc64(64'(input_bits));
            ret.all_zero = ret64.all_zero;
            ret.count    = ret64.count;
        end else begin
            lzc_count [N_SPLITS-1:0] count   ;
            logic     [N_SPLITS-1:0] all_zero;

            for (int i = 0; i < N_SPLITS; i++) begin
                logic                              [64-1:0] bits64;
                __std_lzc_common_pkg::__result__64          ret64 ;

                bits64 = 64'((input_bits >> (64 * i)));
                ret64  = __std_lzc_common_pkg::lzc64(bits64);

                count[i]    = {COUNT_UPPER_WIDTH'(i), ret64.count};
                all_zero[i] = ret64.all_zero;
            end

            ret.all_zero = all_zero == '1;
            ret.count    = __std___select_vector__N_SPLITS__lzc_count(~all_zero, count);
        end

        return ret;
    endfunction

    function automatic logic [16-1:0] __std___bit_reverse__16(
        input var logic [16-1:0] bits
    ) ;
        logic [16-1:0] ret;

        for (int i = 0; i < 16; i++) begin
            ret[i] = bits[16 - i - 1];
        end

        return ret;
    endfunction
    function automatic lzc_count __std___select_vector__N_SPLITS__lzc_count(
        input var logic     [N_SPLITS-1:0] sel ,
        input var lzc_count [N_SPLITS-1:0] data
    ) ;
        localparam int unsigned DEPTH = $clog2(N_SPLITS);
        int unsigned                current_n;
        logic        [N_SPLITS-1:0] current_s;
        lzc_count    [N_SPLITS-1:0] current_d;
        int unsigned                next_n   ;
        logic        [N_SPLITS-1:0] next_s   ;
        lzc_count    [N_SPLITS-1:0] next_d   ;

        next_n = N_SPLITS;
        next_s = sel;
        next_d = data;
        for (int _i = 0; _i < DEPTH; _i++) begin
            current_n = next_n;
            current_s = next_s;
            current_d = next_d;

            next_n = (current_n / 2) + (current_n % 2);
            for (int j = 0; j < next_n; j++) begin
                logic select_even;

                if ((j + 1) == next_n && (current_n % 2) == 1) begin
                    select_even = 1'b1;
                end else begin
                    select_even = current_s[2 * j + 0];
                end

                if (select_even) begin
                    next_s[j] = current_s[2 * j + 0];
                    next_d[j] = current_d[2 * j + 0];
                end else begin
                    next_s[j] = current_s[2 * j + 1];
                    next_d[j] = current_d[2 * j + 1];
                end
            end
        end

        return next_d[0];
    endfunction
endpackage
package __std___lzc_pkg__32;
    localparam int unsigned COUNT_WIDTH       = ((32 >= 2) ? ( $clog2(32) ) : ( 1 ));
    localparam int unsigned COUNT_UPPER_WIDTH = ((32 > 64) ? ( COUNT_WIDTH - 6 ) : ( 1 ));
    localparam int unsigned N_SPLITS          = ((32 > 64) ? ( (32 + 63) / 64 ) : ( 2 )); // 2 is to prevent verilator warning

    typedef __std_lzc_common_pkg::__result__32                   lzc_result;
    typedef logic                               [COUNT_WIDTH-1:0] lzc_count ;

    function automatic lzc_result lzc(
        input var logic [32-1:0] bits    ,
        input var logic           from_msb
    ) ;
        logic      [32-1:0] input_bits;
        lzc_result           ret       ;

        if (from_msb) begin
            input_bits = __std___bit_reverse__32(bits);
        end else begin
            input_bits = bits;
        end

        if (32 <= 4) begin
            __std_lzc_common_pkg::__result__4 ret4        ;
            ret4         = __std_lzc_common_pkg::lzc4(4'(input_bits));
            ret.all_zero = ret4.all_zero;
            ret.count    = COUNT_WIDTH'(ret4.count);
        end else if (32 <= 8) begin
            __std_lzc_common_pkg::__result__8 ret8        ;
            ret8         = __std_lzc_common_pkg::lzc8(8'(input_bits));
            ret.all_zero = ret8.all_zero;
            ret.count    = ret8.count;
        end else if (32 <= 16) begin
            __std_lzc_common_pkg::__result__16 ret16       ;
            ret16        = __std_lzc_common_pkg::lzc16(16'(input_bits));
            ret.all_zero = ret16.all_zero;
            ret.count    = ret16.count;
        end else if (32 <= 32) begin
            __std_lzc_common_pkg::__result__32 ret32       ;
            ret32        = __std_lzc_common_pkg::lzc32(32'(input_bits));
            ret.all_zero = ret32.all_zero;
            ret.count    = ret32.count;
        end else if (32 <= 64) begin
            __std_lzc_common_pkg::__result__64 ret64       ;
            ret64        = __std_lzc_common_pkg::lzc64(64'(input_bits));
            ret.all_zero = ret64.all_zero;
            ret.count    = ret64.count;
        end else begin
            lzc_count [N_SPLITS-1:0] count   ;
            logic     [N_SPLITS-1:0] all_zero;

            for (int i = 0; i < N_SPLITS; i++) begin
                logic                              [64-1:0] bits64;
                __std_lzc_common_pkg::__result__64          ret64 ;

                bits64 = 64'((input_bits >> (64 * i)));
                ret64  = __std_lzc_common_pkg::lzc64(bits64);

                count[i]    = {COUNT_UPPER_WIDTH'(i), ret64.count};
                all_zero[i] = ret64.all_zero;
            end

            ret.all_zero = all_zero == '1;
            ret.count    = __std___select_vector__N_SPLITS__lzc_count(~all_zero, count);
        end

        return ret;
    endfunction

    function automatic logic [32-1:0] __std___bit_reverse__32(
        input var logic [32-1:0] bits
    ) ;
        logic [32-1:0] ret;

        for (int i = 0; i < 32; i++) begin
            ret[i] = bits[32 - i - 1];
        end

        return ret;
    endfunction
    function automatic lzc_count __std___select_vector__N_SPLITS__lzc_count(
        input var logic     [N_SPLITS-1:0] sel ,
        input var lzc_count [N_SPLITS-1:0] data
    ) ;
        localparam int unsigned DEPTH = $clog2(N_SPLITS);
        int unsigned                current_n;
        logic        [N_SPLITS-1:0] current_s;
        lzc_count    [N_SPLITS-1:0] current_d;
        int unsigned                next_n   ;
        logic        [N_SPLITS-1:0] next_s   ;
        lzc_count    [N_SPLITS-1:0] next_d   ;

        next_n = N_SPLITS;
        next_s = sel;
        next_d = data;
        for (int _i = 0; _i < DEPTH; _i++) begin
            current_n = next_n;
            current_s = next_s;
            current_d = next_d;

            next_n = (current_n / 2) + (current_n % 2);
            for (int j = 0; j < next_n; j++) begin
                logic select_even;

                if ((j + 1) == next_n && (current_n % 2) == 1) begin
                    select_even = 1'b1;
                end else begin
                    select_even = current_s[2 * j + 0];
                end

                if (select_even) begin
                    next_s[j] = current_s[2 * j + 0];
                    next_d[j] = current_d[2 * j + 0];
                end else begin
                    next_s[j] = current_s[2 * j + 1];
                    next_d[j] = current_d[2 * j + 1];
                end
            end
        end

        return next_d[0];
    endfunction
endpackage
package __std___lzc_pkg__64;
    localparam int unsigned COUNT_WIDTH       = ((64 >= 2) ? ( $clog2(64) ) : ( 1 ));
    localparam int unsigned COUNT_UPPER_WIDTH = ((64 > 64) ? ( COUNT_WIDTH - 6 ) : ( 1 ));
    localparam int unsigned N_SPLITS          = ((64 > 64) ? ( (64 + 63) / 64 ) : ( 2 )); // 2 is to prevent verilator warning

    typedef __std_lzc_common_pkg::__result__64                   lzc_result;
    typedef logic                               [COUNT_WIDTH-1:0] lzc_count ;

    function automatic lzc_result lzc(
        input var logic [64-1:0] bits    ,
        input var logic           from_msb
    ) ;
        logic      [64-1:0] input_bits;
        lzc_result           ret       ;

        if (from_msb) begin
            input_bits = __std___bit_reverse__64(bits);
        end else begin
            input_bits = bits;
        end

        if (64 <= 4) begin
            __std_lzc_common_pkg::__result__4 ret4        ;
            ret4         = __std_lzc_common_pkg::lzc4(4'(input_bits));
            ret.all_zero = ret4.all_zero;
            ret.count    = COUNT_WIDTH'(ret4.count);
        end else if (64 <= 8) begin
            __std_lzc_common_pkg::__result__8 ret8        ;
            ret8         = __std_lzc_common_pkg::lzc8(8'(input_bits));
            ret.all_zero = ret8.all_zero;
            ret.count    = ret8.count;
        end else if (64 <= 16) begin
            __std_lzc_common_pkg::__result__16 ret16       ;
            ret16        = __std_lzc_common_pkg::lzc16(16'(input_bits));
            ret.all_zero = ret16.all_zero;
            ret.count    = ret16.count;
        end else if (64 <= 32) begin
            __std_lzc_common_pkg::__result__32 ret32       ;
            ret32        = __std_lzc_common_pkg::lzc32(32'(input_bits));
            ret.all_zero = ret32.all_zero;
            ret.count    = ret32.count;
        end else if (64 <= 64) begin
            __std_lzc_common_pkg::__result__64 ret64       ;
            ret64        = __std_lzc_common_pkg::lzc64(64'(input_bits));
            ret.all_zero = ret64.all_zero;
            ret.count    = ret64.count;
        end else begin
            lzc_count [N_SPLITS-1:0] count   ;
            logic     [N_SPLITS-1:0] all_zero;

            for (int i = 0; i < N_SPLITS; i++) begin
                logic                              [64-1:0] bits64;
                __std_lzc_common_pkg::__result__64          ret64 ;

                bits64 = 64'((input_bits >> (64 * i)));
                ret64  = __std_lzc_common_pkg::lzc64(bits64);

                count[i]    = {COUNT_UPPER_WIDTH'(i), ret64.count};
                all_zero[i] = ret64.all_zero;
            end

            ret.all_zero = all_zero == '1;
            ret.count    = __std___select_vector__N_SPLITS__lzc_count(~all_zero, count);
        end

        return ret;
    endfunction

    function automatic logic [64-1:0] __std___bit_reverse__64(
        input var logic [64-1:0] bits
    ) ;
        logic [64-1:0] ret;

        for (int i = 0; i < 64; i++) begin
            ret[i] = bits[64 - i - 1];
        end

        return ret;
    endfunction
    function automatic lzc_count __std___select_vector__N_SPLITS__lzc_count(
        input var logic     [N_SPLITS-1:0] sel ,
        input var lzc_count [N_SPLITS-1:0] data
    ) ;
        localparam int unsigned DEPTH = $clog2(N_SPLITS);
        int unsigned                current_n;
        logic        [N_SPLITS-1:0] current_s;
        lzc_count    [N_SPLITS-1:0] current_d;
        int unsigned                next_n   ;
        logic        [N_SPLITS-1:0] next_s   ;
        lzc_count    [N_SPLITS-1:0] next_d   ;

        next_n = N_SPLITS;
        next_s = sel;
        next_d = data;
        for (int _i = 0; _i < DEPTH; _i++) begin
            current_n = next_n;
            current_s = next_s;
            current_d = next_d;

            next_n = (current_n / 2) + (current_n % 2);
            for (int j = 0; j < next_n; j++) begin
                logic select_even;

                if ((j + 1) == next_n && (current_n % 2) == 1) begin
                    select_even = 1'b1;
                end else begin
                    select_even = current_s[2 * j + 0];
                end

                if (select_even) begin
                    next_s[j] = current_s[2 * j + 0];
                    next_d[j] = current_d[2 * j + 0];
                end else begin
                    next_s[j] = current_s[2 * j + 1];
                    next_d[j] = current_d[2 * j + 1];
                end
            end
        end

        return next_d[0];
    endfunction
endpackage
package __std___lzc_pkg__128;
    localparam int unsigned COUNT_WIDTH       = ((128 >= 2) ? ( $clog2(128) ) : ( 1 ));
    localparam int unsigned COUNT_UPPER_WIDTH = ((128 > 64) ? ( COUNT_WIDTH - 6 ) : ( 1 ));
    localparam int unsigned N_SPLITS          = ((128 > 64) ? ( (128 + 63) / 64 ) : ( 2 )); // 2 is to prevent verilator warning

    typedef __std_lzc_common_pkg::__result__128                   lzc_result;
    typedef logic                               [COUNT_WIDTH-1:0] lzc_count ;

    function automatic lzc_result lzc(
        input var logic [128-1:0] bits    ,
        input var logic           from_msb
    ) ;
        logic      [128-1:0] input_bits;
        lzc_result           ret       ;

        if (from_msb) begin
            input_bits = __std___bit_reverse__128(bits);
        end else begin
            input_bits = bits;
        end

        if (128 <= 4) begin
            __std_lzc_common_pkg::__result__4 ret4        ;
            ret4         = __std_lzc_common_pkg::lzc4(4'(input_bits));
            ret.all_zero = ret4.all_zero;
            ret.count    = COUNT_WIDTH'(ret4.count);
        end else if (128 <= 8) begin
            __std_lzc_common_pkg::__result__8 ret8        ;
            ret8         = __std_lzc_common_pkg::lzc8(8'(input_bits));
            ret.all_zero = ret8.all_zero;
            ret.count    = ret8.count;
        end else if (128 <= 16) begin
            __std_lzc_common_pkg::__result__16 ret16       ;
            ret16        = __std_lzc_common_pkg::lzc16(16'(input_bits));
            ret.all_zero = ret16.all_zero;
            ret.count    = ret16.count;
        end else if (128 <= 32) begin
            __std_lzc_common_pkg::__result__32 ret32       ;
            ret32        = __std_lzc_common_pkg::lzc32(32'(input_bits));
            ret.all_zero = ret32.all_zero;
            ret.count    = ret32.count;
        end else if (128 <= 64) begin
            __std_lzc_common_pkg::__result__64 ret64       ;
            ret64        = __std_lzc_common_pkg::lzc64(64'(input_bits));
            ret.all_zero = ret64.all_zero;
            ret.count    = ret64.count;
        end else begin
            lzc_count [N_SPLITS-1:0] count   ;
            logic     [N_SPLITS-1:0] all_zero;

            for (int i = 0; i < N_SPLITS; i++) begin
                logic                              [64-1:0] bits64;
                __std_lzc_common_pkg::__result__64          ret64 ;

                bits64 = 64'((input_bits >> (64 * i)));
                ret64  = __std_lzc_common_pkg::lzc64(bits64);

                count[i]    = {COUNT_UPPER_WIDTH'(i), ret64.count};
                all_zero[i] = ret64.all_zero;
            end

            ret.all_zero = all_zero == '1;
            ret.count    = __std___select_vector__N_SPLITS__lzc_count(~all_zero, count);
        end

        return ret;
    endfunction

    function automatic logic [128-1:0] __std___bit_reverse__128(
        input var logic [128-1:0] bits
    ) ;
        logic [128-1:0] ret;

        for (int i = 0; i < 128; i++) begin
            ret[i] = bits[128 - i - 1];
        end

        return ret;
    endfunction
    function automatic lzc_count __std___select_vector__N_SPLITS__lzc_count(
        input var logic     [N_SPLITS-1:0] sel ,
        input var lzc_count [N_SPLITS-1:0] data
    ) ;
        localparam int unsigned DEPTH = $clog2(N_SPLITS);
        int unsigned                current_n;
        logic        [N_SPLITS-1:0] current_s;
        lzc_count    [N_SPLITS-1:0] current_d;
        int unsigned                next_n   ;
        logic        [N_SPLITS-1:0] next_s   ;
        lzc_count    [N_SPLITS-1:0] next_d   ;

        next_n = N_SPLITS;
        next_s = sel;
        next_d = data;
        for (int _i = 0; _i < DEPTH; _i++) begin
            current_n = next_n;
            current_s = next_s;
            current_d = next_d;

            next_n = (current_n / 2) + (current_n % 2);
            for (int j = 0; j < next_n; j++) begin
                logic select_even;

                if ((j + 1) == next_n && (current_n % 2) == 1) begin
                    select_even = 1'b1;
                end else begin
                    select_even = current_s[2 * j + 0];
                end

                if (select_even) begin
                    next_s[j] = current_s[2 * j + 0];
                    next_d[j] = current_d[2 * j + 0];
                end else begin
                    next_s[j] = current_s[2 * j + 1];
                    next_d[j] = current_d[2 * j + 1];
                end
            end
        end

        return next_d[0];
    endfunction
endpackage
//# sourceMappingURL=lzc_pkg.sv.map
