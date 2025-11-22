`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.08.2025 22:41:52
// Design Name: 
// Module Name: dotproduct_controller_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dot_product_top_tb;

  // ----------------------------
  // 100 MHz clock (10 ns period)
  // ----------------------------
  reg clk = 0;
  always #5 clk = ~clk;

  // ----------------------------
  // DUT I/O (mimic board pins)
  // ----------------------------
  reg         btnC;
  reg  [7:0]  sw;     // SW7..SW0 = data byte
  reg         SW8;    // index[0]
  reg         SW9;    // index[1]
  reg         SW12;   // write A
  reg         SW13;   // write B
  reg         SW14;   // read A (not required for checks)
  reg         SW15;   // read B (not required for checks)
  wire [15:0] led;
  wire [6:0]  seg;
  wire [3:0]  an;

  integer errors;

  // Instantiate TOP with small debounce & banner timings for fast sim
  dot_product_top #(
    .CLK_FREQ   (100_000_000),
    .DB_CYCLES  (4),            // ~4 cycles debounce for sim
    .SCAN_HZ    (1000),
    .RST_TICKS  (50)            // ~50 cycles banner for sim
  ) dut (
    .clk (clk),
    .btnC(btnC),
    .sw  (sw),
    .SW8 (SW8),
    .SW9 (SW9),
    .SW12(SW12),
    .SW13(SW13),
    .SW14(SW14),
    .SW15(SW15),
    .led (led),
    .seg (seg),
    .an  (an)
  );

  // ----------------------------
  // Utilities / Tasks
  // ----------------------------
  task pulse_reset;
    begin
      btnC = 1'b1;
      repeat (6) @(posedge clk); // > DB_CYCLES
      btnC = 1'b0;
      repeat (2) @(posedge clk);
    end
  endtask

  task set_index;
    input [1:0] idx;
    begin
      SW9 = idx[1];
      SW8 = idx[0];
      @(posedge clk);
    end
  endtask

  task write_A;
    input [1:0] idx;
    input [7:0] val;
    begin
      set_index(idx);
      sw   = val;
      SW12 = 1'b1; @(posedge clk);
      SW12 = 1'b0; @(posedge clk);
    end
  endtask

  task write_B;
    input [1:0] idx;
    input [7:0] val;
    begin
      set_index(idx);
      sw   = val;
      SW13 = 1'b1; @(posedge clk);
      SW13 = 1'b0; @(posedge clk);
    end
  endtask

  // Re-write A[0] to nudge recompute if needed
  task recompute_nudge;
    reg [7:0] hold;
    begin
      hold = sw;
      set_index(2'b00);
      sw   = hold;
      SW12 = 1'b1; @(posedge clk);
      SW12 = 1'b0; @(posedge clk);
    end
  endtask

  // Wait for the internal compute sequence:
  // controller: 1 cycle mac_rst, then 4 en pulses
  task wait_for_compute_done;
    integer guard;
    begin
      // Wait for computing to go HIGH
      guard = 2000;
      while (guard > 0 && dut.computing !== 1'b1) begin
        @(posedge clk);
        guard = guard - 1;
      end
      if (guard == 0) begin
        $display("ERROR: Timeout waiting for computing=1");
        errors = errors + 1;
      end

      // Then wait for computing to return LOW
      guard = 2000;
      while (guard > 0 && dut.computing !== 1'b0) begin
        @(posedge clk);
        guard = guard - 1;
      end
      if (guard == 0) begin
        $display("ERROR: Timeout waiting for computing=0");
        errors = errors + 1;
      end

      // one extra cycle for LED/acc settle
      @(posedge clk);
    end
  endtask

  // ----------------------------
  // Test sequence
  // ----------------------------
  initial begin
    // Optional VCD
    `ifdef DUMPVCD
      $dumpfile("dot_product_top.vcd");
      $dumpvars(0, tb_dot_product_top);
    `endif

    errors = 0;

    // Defaults
    btnC = 0;
    sw   = 8'h00;
    SW8  = 0; SW9  = 0;
    SW12 = 0; SW13 = 0; SW14 = 0; SW15 = 0;

    // Reset
    repeat (5) @(posedge clk);
    pulse_reset();

    // ------------------------
    // Test 1: Normal dot product
    // A = [1,2,3,4], B = [5,6,7,8]
    // dot = 1*5 + 2*6 + 3*7 + 4*8 = 70 (0x0046)
    // ------------------------
    write_A(2'b00, 8'd1);
    write_A(2'b01, 8'd2);
    write_A(2'b10, 8'd3);
    write_A(2'b11, 8'd4);

    write_B(2'b00, 8'd5);
    write_B(2'b01, 8'd6);
    write_B(2'b10, 8'd7);
    write_B(2'b11, 8'd8);

    recompute_nudge();
    wait_for_compute_done();

    if (led !== 16'd70) begin
      $display("ERROR: Normal case mismatch. Got %0d (0x%04h), expected 70 (0x0046)", led, led);
      errors = errors + 1;
    end else begin
      $display("[PASS] Normal case: dot=70 (LED=0x%04h)", led);
    end

    // ------------------------
    // Test 2: Overflow case
    // A = [255,255,255,255], B = [255,255,255,255]
    // Each product = 65025; sum=260100; mod 2^16 = 63492 (0xF804)
    // Expect oflo latched (=1) and LED showing 0xF804.
    // ------------------------
    write_A(2'b00, 8'd255); write_B(2'b00, 8'd255);
    write_A(2'b01, 8'd255); write_B(2'b01, 8'd255);
    write_A(2'b10, 8'd255); write_B(2'b10, 8'd255);
    write_A(2'b11, 8'd255); write_B(2'b11, 8'd255);

    recompute_nudge();
    wait_for_compute_done();

    if (led !== 16'hF804) begin
      $display("ERROR: Overflow case mismatch. Got 0x%04h, expected 0xF804", led);
      errors = errors + 1;
    end

    if (dut.u_mac.oflo !== 1'b1) begin
      $display("ERROR: Expected oflo=1, got %b", dut.u_mac.oflo);
      errors = errors + 1;
    end else begin
      $display("[PASS] Overflow case: LED=0x%04h, oflo=%b", led, dut.u_mac.oflo);
    end

    if (errors == 0) begin
      $display("All tests PASSED.");
    end else begin
      $display("TESTS FAILED. errors=%0d", errors);
    end

    #50;
    $finish;
  end

endmodule
