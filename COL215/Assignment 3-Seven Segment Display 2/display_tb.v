`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 12:33:16 AM
// Design Name: 
// Module Name: display_tb
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


module display_tb;
    reg clk;
    reg [13:0] sw;

 

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    display UUT (
        .clk(clk),
        .sw(sw)
        
    
    ); 

    initial begin
        sw = 14'd0;
        #10;

        // Capture 8,4,2,6 into digits 0..3 respectively
        // Drive as BCD in sw[3:0] for simplicity
        sw[9:0] = 10'b0000_000_1000; sw[10] = 1; #10; sw[7] = 0; // digit0=8
        sw[9:0] = 10'b0000_000_0100; sw[11] = 1; #10; sw[1] = 0; // digit1=4
        sw[9:0] = 10'b0000_000_0010; sw[12] = 1; #10; sw[2] = 0; // digit2=2
        sw[9:0] = 10'b0000_000_0110; sw[13] = 1; #10; sw[3] = 0; // digit3=6

       
        #1000 $finish;
    end

    
   
endmodule