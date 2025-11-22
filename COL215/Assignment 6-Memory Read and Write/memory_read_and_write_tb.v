`timescale 1ns / 1ps

module tb_controller;

    // Inputs
    reg clk;
    reg btnC;
    reg [15:0] sw;

    // Outputs
    wire [3:0] an;
    wire [6:0] seg;

    // Instantiate the Unit Under Test (UUT)
    controller uut (
        .clk(clk),
        .btnC(btnC),
        .sw(sw),
        .an(an),
        .seg(seg)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 50MHz clock
    end

    // Test sequence
    initial begin
        // Initialize Inputs
        btnC = 0;
        sw = 16'h0000;

        // 1. Test Reset functionality
        $display("Testing Reset...");
        btnC = 1;
        #20; // Press button
        btnC = 0;
        #100; // Wait for debounce and some time

        // Wait for reset to finish.
        $display("Waiting for reset to de-assert...");
        wait (uut.reset_active == 0);
        $display("Reset finished.");

        // 2. Test Read Mode based on .coe files
        $display("\n--- Testing Read Mode ---");
        $display("Reading from address 0x0A5 (165)...");
        $display("Expected from .coe files: ROM[165]=5, RAM0[165]=A. Sum C=5+A=F.");
        sw = 16'h4A50; // Mode 01 (Read), Address 0x0A5
        #100;
        $display("Read complete. Verify display shows A=5, B=A, C=0F.");

        // 3. Test Write Mode
        $display("\n--- Testing Write Mode ---");
        $display("Reading from address 0x1FF (511) before write...");
        $display("Expected from .coe files: RAM0[511]=0.");
        sw = 16'h5FF0; // Mode 01 (Read), Address 0x1FF
        #100;

        $display("Writing 0x7 to address 0x1FF...");
        sw = 16'h9FF7; // Mode 10 (Write), Address 0x1FF, Data 0x7
        #100;
        $display("Write pulse sent.");

        // Verify the write by reading back
        $display("Verifying write by reading back from 0x1FF...");
        $display("Expected: ROM[511]=F, RAM0[511]=7. Sum C=F+7=16h.");
        sw = 16'h5FF0; // Mode 01 (Read), Address 0x1FF
        #100;
        $display("Read back complete. Verify display shows A=F, B=7, C=16.");


        // 4. Test Increment Mode
        $display("\n--- Testing Increment Mode ---");
        $display("Incrementing value at address 0x1FF (current value is 7)...");
        sw = 16'hDFF0; // Mode 11 (Increment), Address 0x1FF
        #100;
        $display("Increment pulse sent.");

        // Verify the increment by reading back
        $display("Verifying increment by reading back from 0x1FF...");
        $display("Expected: RAM0[511] is now 8. ROM[511]=F. Sum C=F+8=17h.");
        sw = 16'h5FF0; // Mode 01 (Read), Address 0x1FF
        #100;
        $display("Read back complete. Verify display shows A=F, B=8, C=17.");

        $display("\nSimulation finished.");
        $stop;
    end
    
endmodule

