`timescale 1ns/1ps

// ==============================================
// Course: ELC 5312
// Name: Loc Nguyen
// CR2 Rection timer
// - Uses 8-digit display but shows only 4 digits (rightmost 4)
// - All BCD paths are 16-bit {d3,d2,d1,d0}
// ==============================================
module top (
  input  logic        clk_100mhz,
  input  logic        btn_clr_n,
  input  logic        btn_start_n,
  input  logic        btn_stop_n,
  output logic        led_stim,
  output logic [6:0]  seg,
  output logic        dp,
  output logic [7:0]  an   // 8-digit anodes, active-LOW
);
  // ===== ticks =====
  logic ms_tick, scan_tick;
  clk_div #( .INPUT_HZ(100_000_000), .TICK_HZ(1_000) ) u_div_ms   (.clk(clk_100mhz), .rst(1'b0), .tick(ms_tick));
  clk_div #( .INPUT_HZ(100_000_000), .TICK_HZ(8_000) ) u_div_scan (.clk(clk_100mhz), .rst(1'b0), .tick(scan_tick)); // 8kHz → ~1kHz/digit

  // ===== buttons (active-LOW on board → invert → debounce to pulses) =====
  logic btn_clr_p, btn_start_p, btn_stop_p;
  deb_pulse #(.STABLE_MS(10)) u_db_clr   (.clk(clk_100mhz), .ms_tick(ms_tick), .din(~btn_clr_n),   .pulse(btn_clr_p));
  deb_pulse #(.STABLE_MS(10)) u_db_start (.clk(clk_100mhz), .ms_tick(ms_tick), .din(~btn_start_n), .pulse(btn_start_p));
  deb_pulse #(.STABLE_MS(10)) u_db_stop  (.clk(clk_100mhz), .ms_tick(ms_tick), .din(~btn_stop_n),  .pulse(btn_stop_p));

  // random duration for wait time from 2 to 15 seconds =====
  logic [7:0] lfsr_q; 
  lfsr8 u_lfsr (.clk(clk_100mhz), .en(1'b1), .q(lfsr_q));

  function automatic [3:0] mod14_8 (input logic [7:0] x);
    logic [7:0] r;
    begin
      r = x;
      if (r >= 8'd112) r = r - 8'd112; // 8*14
      if (r >= 8'd56)  r = r - 8'd56;  // 4*14
      if (r >= 8'd28)  r = r - 8'd28;  // 2*14
      if (r >= 8'd14)  r = r - 8'd14;  // 1*14
      mod14_8 = r[3:0];                // 0 to 13
    end
  endfunction

  logic [3:0] rnd_s;           // 2..15
  always_comb rnd_s = mod14_8(lfsr_q) + 4'd2;

  // ===== FSM / datapath =====
  typedef enum logic [2:0] { S_RESET, S_WELCOME, S_ARMED, S_WAIT_RAND, S_COUNTING, S_SHOW } state_t;
  state_t state, state_n; initial state = S_RESET;

  logic [15:0] wait_ms, w_ms;
  logic [10:0] t_ms;
  logic        early_flag;

  // BCD helpers (16-bit)
  localparam [3:0] DIG_H = 4'd10, DIG_I = 4'd11;
  function automatic [15:0] pack_bcd(input [3:0] d3, d2, d1, d0); return {d3,d2,d1,d0}; endfunction
  function automatic [15:0] ms_to_bcd(input [10:0] ms);
    int unsigned m = (ms > 1000) ? 1000 : ms;
    int unsigned h = m / 100;
    int unsigned r = m % 100;
    int unsigned t = r / 10;
    int unsigned o = r % 10;
    return {4'd0, h[3:0], t[3:0], o[3:0]}; // "0.xxx"
  endfunction

  localparam [15:0] BCD_HI    = {DIG_I, DIG_H, 4'd15, 4'd15}; // "HI" on the far left digits
  localparam [15:0] BCD_EARLY = {4'd9, 4'd9, 4'd9, 4'd9};     // "9.999" (we just show 9999 and set dp)
  localparam [15:0] BCD_1000  = {4'd1, 4'd0, 4'd0, 4'd0};     // "1.000"

  logic [15:0] show_bcd, live_bcd;

  // seq
  always_ff @(posedge clk_100mhz) begin
    state <= state_n;
    if (state == S_RESET) begin
      w_ms       <= 16'd0;
      t_ms       <= 11'd0;
      early_flag <= 1'b0;
      wait_ms    <= 16'd0;
      show_bcd   <= BCD_HI;
    end
    if (state == S_ARMED) begin
      wait_ms    <= rnd_s * 16'd1000; // latch random wait
      w_ms       <= 16'd0;
      t_ms       <= 11'd0;
      early_flag <= 1'b0;
    end
    if (state == S_WAIT_RAND) begin
      if (ms_tick) w_ms <= w_ms + 16'd1;
      if (btn_stop_p) early_flag <= 1'b1;      // early press
    end
    if (state == S_COUNTING) begin
      if (ms_tick && (t_ms < 11'd1000)) t_ms <= t_ms + 11'd1;
    end
    if ((state != S_SHOW) && (state_n == S_SHOW)) begin
      if (early_flag)       show_bcd <= BCD_EARLY;
      else if (t_ms >= 1000) show_bcd <= BCD_1000;
      else                  show_bcd <= ms_to_bcd(t_ms);
    end
  end

  // comb
  always_comb begin
    state_n  = state;
    led_stim = 1'b0;

    unique case (state)
      S_RESET:      state_n = S_WELCOME;

      S_WELCOME: begin
        if (btn_clr_p)      state_n = S_RESET;
        else if (btn_start_p) state_n = S_ARMED;
      end

      S_ARMED:      state_n = S_WAIT_RAND;

      S_WAIT_RAND: begin
        if (btn_clr_p)             state_n = S_RESET;
        else if (btn_stop_p)       state_n = S_SHOW;      // early stop
        else if (w_ms >= wait_ms)  state_n = S_COUNTING;  // start timing
      end

      S_COUNTING: begin
        led_stim = 1'b1;
        if (btn_clr_p)             state_n = S_RESET;
        else if (btn_stop_p)       state_n = S_SHOW;
        else if (t_ms >= 1000)     state_n = S_SHOW;
      end

      S_SHOW: begin
        led_stim = 1'b1; // remains on after fired
        if (btn_clr_p)        state_n = S_RESET;
        else if (btn_start_p) state_n = S_ARMED;
      end

      default: state_n = S_RESET;
    endcase
  end

  // live/frozen display
  assign live_bcd = (state == S_COUNTING) ? ms_to_bcd(t_ms) :
                    (state == S_WELCOME)  ? BCD_HI :
                    (state == S_SHOW)     ? show_bcd :
                                            pack_bcd(4'd15,4'd15,4'd15,4'd15); // blank

  // Drive 8-digit display using wrapper (rightmost 4 digits active)
  sevenseg8_wrap u_seven (
    .clk(clk_100mhz), .scan_tick(scan_tick), .bcd(live_bcd),
    .show_dp0(1'b1), .show_dp1(1'b0), .show_dp2(1'b0), .show_dp3(1'b0),
    .seg(seg), .dp(dp), .an(an)
  );
endmodule

// ===== 8-digit wrapper (reuses 4-digit driver) =====
module sevenseg8_wrap (
  input  logic        clk,
  input  logic        scan_tick,
  input  logic [15:0] bcd,           // {d3,d2,d1,d0}
  input  logic        show_dp0, show_dp1, show_dp2, show_dp3,
  output logic [6:0]  seg,           // active-LOW
  output logic        dp,            // active-LOW
  output logic [7:0]  an             // 8 anodes, active-LOW
);
  logic [3:0] an4;
  sevenseg4_v2 u4 (
    .clk(clk), .scan_tick(scan_tick), .bcd(bcd),
    .show_dp0(show_dp0), .show_dp1(show_dp1), .show_dp2(show_dp2), .show_dp3(show_dp3),
    .seg(seg), .dp(dp), .an(an4)
  );
  assign an = {4'b1111, an4}; // left 4 off, right 4 drive {d3..d0}
endmodule

// ===== 4-digit seven-seg (active-LOW) =====
module sevenseg4_v2 (
  input  logic        clk,
  input  logic        scan_tick,
  input  logic [15:0] bcd,   // {d3,d2,d1,d0}
  input  logic        show_dp0, show_dp1, show_dp2, show_dp3,
  output logic [6:0]  seg,
  output logic        dp,
  output logic [3:0]  an
);
  logic [1:0] idx; 
  always_ff @(posedge clk) if (scan_tick) idx <= idx + 2'd1;

  logic [3:0] digit;
  always_comb begin
    unique case (idx)
      2'd0: digit = bcd[15:12];
      2'd1: digit = bcd[11:8];
      2'd2: digit = bcd[7:4];
      2'd3: digit = bcd[3:0];
      default: digit = 4'hF;
    endcase
  end

  always_comb begin
    an = 4'b1111;
    an[idx] = 1'b0; // enable selected
  end

  always_comb begin
    logic dp_sel;
    unique case (idx)
      2'd0: dp_sel = show_dp0;
      2'd1: dp_sel = show_dp1;
      2'd2: dp_sel = show_dp2;
      2'd3: dp_sel = show_dp3;
      default: dp_sel = 1'b0;
    endcase
    dp = ~dp_sel; // active-LOW
  end

  // digits: 0-9, H=10, I=11, 15=blank
  always_comb begin
    unique case (digit)
      4'd0:  seg = 7'b100_0000; 4'd1:  seg = 7'b111_1001; 4'd2: seg = 7'b010_0100; 4'd3: seg = 7'b011_0000;
      4'd4:  seg = 7'b001_1001; 4'd5:  seg = 7'b001_0010; 4'd6: seg = 7'b000_0010; 4'd7: seg = 7'b111_1000;
      4'd8:  seg = 7'b000_0000; 4'd9:  seg = 7'b001_0000; 4'd10: seg = 7'b000_1001; // H
      4'd11: seg = 7'b111_1001; // I (looks like 1)
      default: seg = 7'b111_1111; // blank
    endcase
  end
endmodule

// ===== clock divider  =====
module clk_div #(parameter int INPUT_HZ=100_000_000, parameter int TICK_HZ=1_000) (
  input  logic clk,
  input  logic rst,
  output logic tick
);
  localparam int DIVIDE = INPUT_HZ / TICK_HZ;
  localparam int CNTW   = $clog2(DIVIDE);
  logic [CNTW-1:0] cnt;
  always_ff @(posedge clk) begin
    if (rst) begin
      cnt  <= '0;
      tick <= 1'b0;
    end else begin
      if (cnt == DIVIDE-1) begin
        cnt  <= '0;
        tick <= 1'b1;
      end else begin
        cnt  <= cnt + 1'b1;
        tick <= 1'b0;
      end
    end
  end
endmodule

// ===== debouncer + rising-edge pulse =====
module deb_pulse #(parameter int STABLE_MS = 10) (
  input  logic clk,
  input  logic ms_tick,
  input  logic din,
  output logic pulse
);
  logic s0, s1;
  always_ff @(posedge clk) begin
    s0 <= din;
    s1 <= s0;
  end

  logic stable_state;
  logic [$clog2(STABLE_MS+1)-1:0] ms_cnt;
  always_ff @(posedge clk) begin
    if (ms_tick) begin
      if (s1 == stable_state) begin
        if (ms_cnt != STABLE_MS[$clog2(STABLE_MS+1)-1:0]) ms_cnt <= ms_cnt + 1'b1;
      end else begin
        ms_cnt <= '0;
      end
      if (ms_cnt == STABLE_MS[$clog2(STABLE_MS+1)-1:0]) begin
        stable_state <= s1;
      end
    end
  end

  logic stable_d;
  always_ff @(posedge clk) begin
    stable_d <= stable_state;
    pulse    <= (stable_state & ~stable_d);
  end
endmodule

// ===== 8-bit LFSR(Linear Feedback Shift Register =====
// Note: LFSR is a digital circuit used to generate pseudo-random sequence of bits.
// operation: on rising edge of clk, if en = 1, register shift << by 1 bit.
// With the width of 8 bit for the LFSR, this means that max # of state is 255 non zero states that it can cycle through.
module lfsr8 (
  input  logic clk,
  input  logic en,
  output logic [7:0] q
);
  always_ff @(posedge clk) begin
    if (en) begin
      q <= {q[6:0], q[7]^q[5]^q[4]^q[3]};
      if (q == 8'h00) q <= 8'hA5; // avoid lock at zero
    end
  end
  initial q = 8'h5A;
endmodule

