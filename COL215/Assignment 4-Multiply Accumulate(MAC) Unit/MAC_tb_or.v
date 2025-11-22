`timescale 1ns/1ps

module tb_mac;
    // Clock and reset (btnc) signals
    reg clk;
    reg btnc;
    // Switch inputs (13-bit: [7:0]=data, 10=b_enable, 11=c_enable, 12=MAC enable)
    reg [12:0] sw;
    wire [15:0] led;
    wire [3:0] an;
    wire [6:0] seg;

    // Instantiate the top-level MAC module
    // (Assumes modified mac_or.v is compiled together with this testbench)
    mac_top uut (
        .clk(clk),
        .btnc(btnc),
        .sw(sw),
        .led(led),
        .an(an),
        .seg(seg)
    );

    // Clock generation: 100 MHz (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Function to decode a 7-seg pattern to an ASCII character
    function [7:0] decodeChar;
        input [6:0] seg;
        begin
            if (seg === 7'b0000111)      decodeChar = "t"; // "-rSt"
            else if (seg === 7'b0010010) decodeChar = "S";
            else if (seg === 7'b0101111) decodeChar = "r";
            else if (seg === 7'b0111111) decodeChar = "-";
            else if (seg === 7'b1000000) decodeChar = "O"; // "OFLO"
            else if (seg === 7'b1000111) decodeChar = "L";
            else if (seg === 7'b0001110) decodeChar = "F";
            else                         decodeChar = "?"; // unknown
        end
    endfunction

    // Task to capture all 4 digits of the 7-seg display and print as a string
    task decode_display;
        reg [7:0] chars [3:0];
        reg [3:0] cur_an;
        integer i;
        begin
            // Initialize collected chars to spaces
            for (i = 0; i < 4; i++) chars[i] = " ";
            // Sample on each clock for up to 100 cycles or until all found
            for (i = 0; i < 100; i++) begin
                @(posedge clk); #1;  // wait a bit for outputs to settle
                cur_an = an;
                if (cur_an != 4'b1111) begin
                    // Identify which digit is active (active-low an)
                    if (cur_an == 4'b0111) chars[3] = decodeChar(seg);
                    else if (cur_an == 4'b1011) chars[2] = decodeChar(seg);
                    else if (cur_an == 4'b1101) chars[1] = decodeChar(seg);
                    else if (cur_an == 4'b1110) chars[0] = decodeChar(seg);
                end
                // If all digits captured, print the string
                if ((chars[0] != " ") && (chars[1] != " ") && (chars[2] != " ") && (chars[3] != " ")) begin
                    $display("%0t ns: 7-seg display shows \"%c%c%c%c\"", $time, chars[3], chars[2], chars[1], chars[0]);
                    disable decode_display;
                end
            end
            // If timeout, still print what was found
            $display("%0t ns: 7-seg incomplete: \"%c%c%c%c\"", $time, chars[3], chars[2], chars[1], chars[0]);
        end
    endtask

    initial begin
        // VCD dump for waveform viewing
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_mac);

        // Initialize switches and reset
        sw     = 13'b0;
        btnc   = 0;
        // Initial reset pulse (2 cycles high) to clear X states
        btnc = 1;
        @(posedge clk);
        @(posedge clk);
        btnc = 0;
        #10;

        // ==== Case 1: 1 bounce ON (5ns), 2 bounces OFF (2ns), push = 30ns ====
        btnc = 1;
        #5  btnc = 0;  #5  btnc = 1;    // 1 bounce ON (5ns glitch)
        #20;                         // total ON = 30ns
        btnc = 0;
        #2  btnc = 1;  #2  btnc = 0;    // 2 bounces OFF (2ns each)
        #10; decode_display();        // expect display "-rSt"
        #20;

        // ==== Case 2: 2 bounces ON (2ns), 2 bounces OFF (5ns), push = 30ns ====
        btnc = 1;
        #2  btnc = 0;  #2  btnc = 1;  // first bounce ON (2ns)
        #2  btnc = 0;  #2  btnc = 1;  // second bounce ON (2ns)
        #22;                         // remaining ON to total 30ns (8ns used above)
        btnc = 0;
        #5  btnc = 1;  #5  btnc = 0;  // 1st OFF bounce (5ns)
        #5  btnc = 1;  #5  btnc = 0;  // 2nd OFF bounce (5ns)
        #10; decode_display();
        #20;

        // ==== Case 3: 2 bounces ON (5ns), 2 bounces OFF (5ns), push = 40ns ====
        btnc = 1;
        #5  btnc = 0;  #5  btnc = 1;  // 1st bounce ON
        #5  btnc = 0;  #5  btnc = 1;  // 2nd bounce ON
        #20;                         // remaining ON to 40ns (20ns bounces + 20ns stable)
        btnc = 0;
        #5  btnc = 1;  #5  btnc = 0;  // 1st OFF bounce
        #5  btnc = 1;  #5  btnc = 0;  // 2nd OFF bounce
        #10; decode_display();
        #20;

        // ==== Case 4: 3 bounces ON (2ns), 3 bounces OFF (2ns), push = 40ns ====
        btnc = 1;
        #2  btnc = 0;  #2  btnc = 1;  // 1st bounce ON
        #2  btnc = 0;  #2  btnc = 1;  // 2nd bounce ON
        #2  btnc = 0;  #2  btnc = 1;  // 3rd bounce ON (total 12ns of bounce)
        #28;                         // remaining ON to 40ns (12ns + 28ns)
        btnc = 0;
        #2  btnc = 1;  #2  btnc = 0;  // 1st OFF bounce
        #2  btnc = 1;  #2  btnc = 0;  // 2nd OFF bounce
        #2  btnc = 1;  #2  btnc = 0;  // 3rd OFF bounce
        #10; decode_display();
        #20;

        // ==== MAC Operation: load operands and accumulate ====
        // First accumulate (no overflow expected)
        sw = 13'b0;
        sw[7:0] = 8'd255; sw[10] = 1; @(posedge clk); sw[10] = 0;  // Load b=255
        sw[7:0] = 8'd255; sw[11] = 1; @(posedge clk); sw[11] = 0;  // Load c=255
        sw[12] = 1; @(posedge clk); sw[12] = 0;                       // MAC enable (rising edge)
        $display("%0t ns: Accumulator after 255*255 = %h", $time, led);

        // Second accumulate to trigger overflow
        sw[7:0] = 8'd255; sw[10] = 1; @(posedge clk); sw[10] = 0;  // b=255
        sw[7:0] = 8'd3;   sw[11] = 1; @(posedge clk); sw[11] = 0;  // c=3
        sw[12] = 1; @(posedge clk); sw[12] = 0;                       // MAC enable (overflow should occur)
        $display("%0t ns: Accumulator after overflow = %h", $time, led);

        #10; decode_display();  // expect display "OFLO"
        $display("Simulation completed at %0t ns", $time);
        $finish;
    end

endmodule
