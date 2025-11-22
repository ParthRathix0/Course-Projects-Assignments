`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2025 12:28:56 AM
// Design Name: 
// Module Name: display
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
module seven_segment (
    input  wire [9:0] sw,
    output reg  [6:0] seg  // {a,b,c,d,e,f,g}, active LOW
);
    always @(*) begin
        if (sw[9])
            seg = 7'b0001100;
        else if (sw[8]) 
            seg = 7'b0000000;
        else if (sw[7])
            seg = 7'b0001111;
        else if (sw[6]) 
            seg = 7'b0100000;
        else if (sw[5])
            seg = 7'b0100100;
        else if (sw[4]) 
            seg = 7'b1001100;
        else if (sw[3])
            seg = 7'b0000110;
        else if (sw[2]) 
            seg = 7'b0010010;
        else if (sw[1])
            seg = 7'b1001111;
        else if (sw[0]) 
            seg = 7'b0000001;
        else
            seg = 7'b1111111;

    end
endmodule

module display (
    input  wire        clk,        
    input  wire [13:0] sw,         
    output wire [6:0]  seg,      
    output wire [3:0]  an,
    output wire dp         
);
    reg [9:0] digit0 = 0, digit1 = 0, digit2 = 0, digit3 = 0;

    // Refresh timing: 100,000 cycles @100MHz = 1ms per anode -> 4ms per full scan (~250 Hz)
    reg [16:0] counter = 0;      
    reg [1:0]  active_anode = 0; 
    reg [9:0]  current_digit;    


    always @(posedge clk) begin
        if (sw[10]) digit0 <= sw[9:0]; // latch for digit 0
        if (sw[11]) digit1 <= sw[9:0]; // latch for digit 1
        if (sw[12]) digit2 <= sw[9:0]; // latch for digit 2
        if (sw[13]) digit3 <= sw[9:0]; // latch for digit 3
    end

    // 1 ms timebase and anode rotation
    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 17'd99_999) begin
            counter <= 0;
            active_anode <= (active_anode == 2'd3) ? 2'd0 : active_anode + 1;
        end
    end

    // Active-LOW anodes
    assign an[0] = ~(active_anode == 2'd0);
    assign an[1] = ~(active_anode == 2'd1);
    assign an[2] = ~(active_anode == 2'd2);
    assign an[3] = ~(active_anode == 2'd3);


    // Select which stored digit to show on the active anode
    always @(*) begin
        case (active_anode)
            2'd0: current_digit = digit0;
            2'd1: current_digit = digit1;
            2'd2: current_digit = digit2;
            2'd3: current_digit = digit3;
            default: current_digit = 4'd0;
        endcase
    end

    seven_segment decoder (
        .sw(current_digit),
        .seg(seg)
    );
endmodule

