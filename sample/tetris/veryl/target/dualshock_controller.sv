// -------------------------------------------------------------------
//
// PLAYSTATION CONTROLLER (DUALSHOCK TYPE) INTERFACE
//
// Original Version : 2.00
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
// Ported to Veryl
//
// Poll controller status every 2^Timer_siz clock cycles
// 250KHz / 2^12 = 61Hz
//
// -------------------------------------------------------------------

// Timer size: 12 for synthesis, 18 for simulation

// ---------------------------------------------------------------------------
// ps_rxd : Serial receive shift register
// ---------------------------------------------------------------------------
module tetris_ps_rxd (
    input  var logic         i_clk    ,
    input  var logic         i_rstn   ,
    input  var logic         i_wt     ,
    input  var logic         i_ps_rxd ,
    output var logic [8-1:0] o_rxd_dat
);
    logic [8-1:0] sp;


    // Shift register: shift in MSB from i_ps_rxd on rising edge of i_clk
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            sp <= 8'h01;
        end else begin
            sp <= {i_ps_rxd, sp[7:1]};
        end
    end

    // Latch on rising edge of i_wt
    always_ff @ (posedge i_wt, negedge i_rstn) begin
        if (!i_rstn) begin
            o_rxd_dat <= 8'h01;
        end else begin
            o_rxd_dat <= sp;
        end
    end
endmodule

// ---------------------------------------------------------------------------
// ps_txd : Serial transmit shift register
// ---------------------------------------------------------------------------
module tetris_ps_txd (
    input  var logic         i_clk    ,
    input  var logic         i_rstn   ,
    input  var logic         i_wt     ,
    input  var logic         i_en     ,
    input  var logic [8-1:0] i_txd_dat,
    output var logic         o_ps_txd 
);
    logic [8-1:0] ps;

    // Shift out LSB first on falling edge of i_clk
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            o_ps_txd <= 1'b1;
            ps       <= 8'h00;
        end else begin
            if (i_wt) begin
                ps <= i_txd_dat;
            end else begin
                if (i_en) begin
                    o_ps_txd <= ps[0];
                    ps       <= {1'b1, ps[7:1]};
                end else begin
                    o_ps_txd <= 1'b1;
                end
            end
        end
    end
endmodule

// ---------------------------------------------------------------------------
// ps_pls_gan : Pulse / timing generator
// ---------------------------------------------------------------------------
module tetris_ps_pls_gan #(
    localparam int unsigned TIMER_SIZ = 12,

    parameter int unsigned TIMER_SIZE = TIMER_SIZ
) (
    input  var logic                  i_clk         ,
    input  var logic                  i_rstn        ,
    input  var logic                  i_type        , // 0=digital, 1=analog
    output var logic                  o_scan_seq_pls,
    output var logic                  o_rxwt        ,
    output var logic                  o_txwt        ,
    output var logic                  o_txset       ,
    output var logic                  o_txen        ,
    output var logic                  o_ps_clk      ,
    output var logic                  o_ps_sel      ,
    output var logic [4-1:0]          o_byte_cnt    ,
    output var logic [TIMER_SIZE-1:0] o_timer   
);
    logic [TIMER_SIZE-1:0] timer      ;
    logic                  ps_clk_gate;
    logic                  ps_sel     ;
    logic                  rxwt       ;
    logic                  txwt       ;
    logic                  txset      ;

    // Timer counter
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            timer <= '0;
        end else begin
            timer <= timer + 1'b1;
        end
    end

    // Scan sequence pulse (one cycle at timer==0)
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            o_scan_seq_pls <= 1'b0;
        end else begin
            if (timer == '0) begin
                o_scan_seq_pls <= 1'b1;
            end else begin
                o_scan_seq_pls <= 1'b0;
            end
        end
    end

    // CLK gate / RXWT / TXWT / TXSET timing (lower 5 bits of timer)
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            ps_clk_gate <= 1'b1;
            rxwt        <= 1'b0;
            txwt        <= 1'b0;
            txset       <= 1'b0;
        end else begin
            case (timer[4:0])
                5'd6   : txset       <= 1'b1;
                5'd8   : txset       <= 1'b0;
                5'd9   : txwt        <= 1'b1;
                5'd11  : txwt        <= 1'b0;
                5'd12  : ps_clk_gate <= 1'b0;
                5'd20  : ps_clk_gate <= 1'b1;
                5'd21  : rxwt        <= 1'b1;
                5'd23  : rxwt        <= 1'b0;
                default: begin
                end
            endcase
        end
    end

    // SEL (chip select, active-low to controller)
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            ps_sel <= 1'b1;
        end else begin
            if (o_scan_seq_pls == 1'b1) begin
                ps_sel <= 1'b0;
            end else if (i_type == 1'b0 && timer == 158) begin
                ps_sel <= 1'b1;
            end else if (i_type == 1'b1 && timer == 286) begin
                ps_sel <= 1'b1;
            end
        end
    end

    // Byte counter
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            o_byte_cnt <= 4'h0;
        end else begin
            if (o_scan_seq_pls == 1'b1) begin
                o_byte_cnt <= 4'h0;
            end else begin
                if (timer[4:0] == 5'b11111) begin
                    if (i_type == 1'b0 && o_byte_cnt == 4'd5) begin
                        // hold
                    end else if (i_type == 1'b1 && o_byte_cnt == 4'd9) begin
                        // hold
                    end else begin
                        o_byte_cnt <= o_byte_cnt + 4'h1;
                    end
                end
            end
        end
    end

    always_comb o_timer  = timer;
    always_comb o_ps_clk = ps_clk_gate | i_clk | ps_sel;
    always_comb o_ps_sel = ps_sel;
    always_comb o_rxwt   = ~ps_sel & rxwt;
    always_comb o_txset  = ~ps_sel & txset;
    always_comb o_txwt   = ~ps_sel & txwt;
    always_comb o_txen   = ~ps_sel & (~ps_clk_gate);
endmodule

// ---------------------------------------------------------------------------
// txd_commnd : Command / config state machine (DualShock)
// ---------------------------------------------------------------------------
module tetris_txd_commnd (
    input  var logic         i_clk     ,
    input  var logic         i_rstn    ,
    input  var logic [4-1:0] i_byte_cnt,
    input  var logic [3-1:0] i_mode    , // {conf_sw, ~mode_en, mode_sw}
    input  var logic [2-1:0] i_vib_sw  ,
    input  var logic [8-1:0] i_vib_dat ,
    input  var logic [8-1:0] i_rxd_dat ,
    output var logic [8-1:0] o_txd_dat ,
    output var logic         o_type    ,
    output var logic         o_conf_ent
);
    logic [2-1:0] pad_mode    ;
    logic         ds_sw       ;
    logic [3-1:0] conf_state  ;
    logic         conf_entry  ;
    logic         conf_ent_reg;
    logic         conf_done   ;
    logic         pad_status  ;
    logic         pad_id      ;

    always_comb pad_mode   = i_mode[1:0];
    always_comb ds_sw      = i_mode[2];
    always_comb o_type     = pad_id;
    always_comb o_conf_ent = conf_entry;

    // pad_id detection from RXD byte 2
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            pad_id <= 1'b0;
        end else begin
            if (i_byte_cnt == 4'd2) begin
                case (i_rxd_dat)
                    8'h23  : pad_id <= 1'b1;
                    8'h41  : pad_id <= 1'b0;
                    8'h53  : pad_id <= 1'b1;
                    8'h73  : pad_id <= 1'b1;
                    8'hE3  : pad_id <= 1'b1;
                    8'hF3  : pad_id <= 1'b1;
                    default: pad_id <= 1'b0;
                endcase
            end
        end
    end

    // Main command / config state machine
    always_ff @ (posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            o_txd_dat    <= 8'h00;
            conf_entry   <= 1'b0;
            conf_ent_reg <= 1'b0;
            conf_done    <= 1'b1;
            conf_state   <= 3'd0;
            pad_status   <= 1'b0;
        end else begin
            if (~conf_entry) begin
                // Normal polling mode
                case (i_byte_cnt)
                    4'd0: o_txd_dat <= 8'h01;
                    4'd1: o_txd_dat <= 8'h42;
                    4'd3: begin
                        if (i_rxd_dat == 8'h00) begin
                            conf_ent_reg <= 1'b1;
                        end
                        if (pad_status) begin
                            if (i_vib_sw[0]) begin
                                o_txd_dat <= 8'h01;
                            end else begin
                                o_txd_dat <= 8'h00;
                            end
                        end else begin
                            if (i_vib_sw[0] | i_vib_sw[1]) begin
                                o_txd_dat <= 8'h40;
                            end else begin
                                o_txd_dat <= 8'h00;
                            end
                        end
                    end
                    4'd4: begin
                        if (pad_status) begin
                            if (i_vib_sw[1]) begin
                                o_txd_dat <= i_vib_dat;
                            end else begin
                                o_txd_dat <= 8'h00;
                            end
                        end else begin
                            if (i_vib_sw[0] | i_vib_sw[1]) begin
                                o_txd_dat <= 8'h01;
                            end else begin
                                o_txd_dat <= 8'h00;
                            end
                        end
                        if (pad_id == 1'b0) begin
                            if (conf_state == 3'd0 && ds_sw) begin
                                conf_entry <= 1'b1;
                            end
                            if (conf_state == 3'd7 && (pad_status & conf_ent_reg)) begin
                                conf_state <= 3'd0;
                                conf_entry <= 1'b1;
                            end
                        end
                    end
                    4'd8: begin
                        o_txd_dat <= 8'h00;
                        if (pad_id == 1'b1) begin
                            if (conf_state == 3'd0 && ds_sw) begin
                                conf_entry <= 1'b1;
                            end
                            if (conf_state == 3'd7 && (pad_status & conf_ent_reg)) begin
                                conf_state <= 3'd0;
                                conf_entry <= 1'b1;
                            end
                        end
                    end
                    default: o_txd_dat <= 8'h00;
                endcase
            end else begin
                // Config mode
                case (conf_state)
                    // config_mode_enter (0x43): 01,43,00,01,00,...
                    3'd0: begin
                        case (i_byte_cnt)
                            4'd0: begin
                                o_txd_dat <= 8'h01;
                                conf_done <= 1'b0;
                            end
                            4'd1: o_txd_dat <= 8'h43;
                            4'd3: o_txd_dat <= 8'h01;
                            4'd4: begin
                                o_txd_dat <= 8'h00;
                                if (pad_id == 1'b0) begin
                                    if (pad_status) begin
                                        conf_state <= 3'd3;
                                    end else begin
                                        conf_state <= 3'd1;
                                    end
                                end
                            end
                            4'd8: begin
                                o_txd_dat <= 8'h00;
                                if (pad_id == 1'b1) begin
                                    if (pad_status) begin
                                        conf_state <= 3'd3;
                                    end else begin
                                        conf_state <= 3'd1;
                                    end
                                end
                            end
                            default: o_txd_dat <= 8'h00;
                        endcase
                    end
                    // query_model_and_mode (0x45): 01,45,00,5A,...
                    3'd1: begin
                        case (i_byte_cnt)
                            4'd0: o_txd_dat <= 8'h01;
                            4'd1: o_txd_dat <= 8'h45;
                            4'd2: begin
                                o_txd_dat <= 8'h00;
                                conf_done <= ((i_rxd_dat == 8'hF3) ? ( 1'b0 ) : ( 1'b1 ));
                            end
                            4'd4: begin
                                o_txd_dat <= 8'h00;
                                if (i_rxd_dat == 8'h01 | i_rxd_dat == 8'h03) begin
                                    pad_status <= 1'b1;
                                end
                                if (pad_id == 1'b0 && conf_done == 1'b1) begin
                                    conf_state <= 3'd7;
                                    conf_entry <= 1'b0;
                                end
                            end
                            4'd8: begin
                                o_txd_dat  <= 8'h00;
                                conf_state <= 3'd2;
                                if (pad_id == 1'b1 && conf_done == 1'b1) begin
                                    conf_state <= 3'd7;
                                    conf_entry <= 1'b0;
                                end
                            end
                            default: o_txd_dat <= 8'h00;
                        endcase
                    end
                    // set_mode_and_lock (0x44)
                    3'd2: begin
                        case (i_byte_cnt)
                            4'd0: o_txd_dat <= 8'h01;
                            4'd1: o_txd_dat <= 8'h44;
                            4'd3: o_txd_dat <= ((pad_mode[0]) ? ( 8'h01 ) : ( 8'h00 ));
                            4'd4: o_txd_dat <= ((pad_mode[1]) ? ( 8'h03 ) : ( 8'h00 ));
                            4'd8: begin
                                o_txd_dat  <= 8'h00;
                                conf_state <= 3'd3;
                            end
                            default: o_txd_dat <= 8'h00;
                        endcase
                    end
                    // vibration_enable (0x4D)
                    3'd3: begin
                        case (i_byte_cnt)
                            4'd0: o_txd_dat <= 8'h01;
                            4'd1: o_txd_dat <= 8'h4D;
                            4'd4: o_txd_dat <= 8'h01;
                            4'd8: begin
                                o_txd_dat  <= 8'hFF;
                                conf_state <= 3'd6;
                            end
                            default: o_txd_dat <= 8'hFF;
                        endcase
                    end
                    // config_mode_exit (0x43 with exit flag)
                    3'd6: begin
                        case (i_byte_cnt)
                            4'd0: o_txd_dat <= 8'h01;
                            4'd1: o_txd_dat <= 8'h43;
                            4'd8: begin
                                o_txd_dat    <= 8'h5A;
                                conf_state   <= 3'd7;
                                conf_entry   <= 1'b0;
                                conf_done    <= 1'b1;
                                conf_ent_reg <= 1'b0;
                            end
                            default: o_txd_dat <= 8'h5A;
                        endcase
                    end
                    default: begin
                    end
                endcase
            end
        end
    end
endmodule

// ---------------------------------------------------------------------------
// dualshock_controller : Top-level controller
// ---------------------------------------------------------------------------
module tetris_dualshock_controller (
    input  var logic         i_clk250k,
    input  var logic         i_rstn   ,
    output var logic         o_ps_clk ,
    output var logic         o_ps_sel ,
    output var logic         o_ps_txd ,
    input  var logic         i_ps_rxd ,
    output var logic [8-1:0] o_rxd_1  ,
    output var logic [8-1:0] o_rxd_2  ,
    output var logic [8-1:0] o_rxd_3  ,
    output var logic [8-1:0] o_rxd_4  ,
    output var logic [8-1:0] o_rxd_5  ,
    output var logic [8-1:0] o_rxd_6  ,
    input  var logic         i_conf_sw, // DualShock config, active-hi
    input  var logic         i_mode_sw, // 0=digital, 1=analog
    input  var logic         i_mode_en, // mode control enable
    input  var logic [2-1:0] i_vib_sw ,
    input  var logic [8-1:0] i_vib_dat
);
    // Internal wires
    logic         w_scan_seq_pls;
    logic         w_type        ;
    logic [4-1:0] w_byte_cnt    ;
    logic         w_rxwt        ;
    logic         w_txwt        ;
    logic         w_txset       ;
    logic         w_txen        ;
    logic [8-1:0] w_txd_dat     ;
    logic [8-1:0] w_rxd_dat     ;
    logic         w_conf_ent    ;
    logic         w_rxd_mask    ;

    // Pulse / timing generator
    tetris_ps_pls_gan pls (
        .i_clk          (i_clk250k     ),
        .i_rstn         (i_rstn        ),
        .i_type         (w_type        ),
        .o_scan_seq_pls (w_scan_seq_pls),
        .o_rxwt         (w_rxwt        ),
        .o_txwt         (w_txwt        ),
        .o_txset        (w_txset       ),
        .o_txen         (w_txen        ),
        .o_ps_clk       (o_ps_clk      ),
        .o_ps_sel       (o_ps_sel      ),
        .o_byte_cnt     (w_byte_cnt    ),
        .o_timer        (              )
    );

    // Command state machine
    tetris_txd_commnd cmd (
        .i_clk      (w_txset                           ),
        .i_rstn     (i_rstn                            ),
        .i_byte_cnt (w_byte_cnt                        ),
        .i_mode     ({i_conf_sw, ~i_mode_en, i_mode_sw}),
        .i_vib_sw   (i_vib_sw                          ),
        .i_vib_dat  (i_vib_dat                         ),
        .i_rxd_dat  (w_rxd_dat                         ),
        .o_txd_dat  (w_txd_dat                         ),
        .o_type     (w_type                            ),
        .o_conf_ent (w_conf_ent                        )
    );

    // Transmitter
    tetris_ps_txd txd (
        .i_clk     (i_clk250k),
        .i_rstn    (i_rstn   ),
        .i_wt      (w_txwt   ),
        .i_en      (w_txen   ),
        .i_txd_dat (w_txd_dat),
        .o_ps_txd  (o_ps_txd )
    );

    // Receiver
    tetris_ps_rxd rxd (
        .i_clk     (o_ps_clk ),
        .i_rstn    (i_rstn   ),
        .i_wt      (w_rxwt   ),
        .i_ps_rxd  (i_ps_rxd ),
        .o_rxd_dat (w_rxd_dat)
    );

    // RXD mask latch (mask when config entry active)
    always_ff @ (posedge w_scan_seq_pls, negedge i_rstn) begin
        if (!i_rstn) begin
            w_rxd_mask <= 1'b0;
        end else begin
            w_rxd_mask <= ~w_conf_ent;
        end
    end

    // Decode received bytes into output registers
    always_ff @ (posedge w_rxwt, negedge i_rstn) begin
        if (!i_rstn) begin
            o_rxd_1 <= 8'hFF;
            o_rxd_2 <= 8'hFF;
            o_rxd_3 <= 8'hFF;
            o_rxd_4 <= 8'hFF;
            o_rxd_5 <= 8'hFF;
            o_rxd_6 <= 8'hFF;
        end else begin
            if (w_rxd_mask) begin
                case (w_byte_cnt)
                    4'd3   : o_rxd_1 <= w_rxd_dat;
                    4'd4   : o_rxd_2 <= w_rxd_dat;
                    4'd5   : o_rxd_3 <= w_rxd_dat;
                    4'd6   : o_rxd_4 <= w_rxd_dat;
                    4'd7   : o_rxd_5 <= w_rxd_dat;
                    4'd8   : o_rxd_6 <= w_rxd_dat;
                    default: begin
                    end
                endcase
            end
        end
    end
endmodule
//# sourceMappingURL=dualshock_controller.sv.map
