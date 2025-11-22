`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2025 12:20:02 AM
// Design Name: 
// Module Name: seven_segment_display
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


module seven_segment_display(
    input [9:0] sw,
    output reg [6:0] cat,
    output reg [3:0] anode,
    output wire dp
    );
    
always @(*) begin
    anode=4'b1110;
    if (sw[9])
        cat = 7'b0001100;
    else if (sw[8]) 
        cat = 7'b0000000;
    else if (sw[7])
        cat = 7'b0001111;
    else if (sw[6]) 
        cat = 7'b0100000;
    else if (sw[5])
        cat = 7'b0100100;
    else if (sw[4]) 
        cat = 7'b1001100;
    else if (sw[3])
        cat = 7'b0000110;
    else if (sw[2]) 
        cat = 7'b0010010;
    else if (sw[1])
        cat = 7'b1001111;
    else if (sw[0]) 
        cat = 7'b0000001;
    else
        cat = 7'b1111111;
    
end


endmodule
