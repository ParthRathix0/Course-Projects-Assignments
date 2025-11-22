`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2025 02:37:14 AM
// Design Name: 
// Module Name: AND_OR_NOT_gate
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


module AND_OR_NOT_gate(
    input a,
    input b,
    output c,
    output d,
    output e
    );
assign c=a&b;
assign d=a|b;
assign e=~a;
endmodule
