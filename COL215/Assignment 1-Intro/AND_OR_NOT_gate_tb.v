`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
module AND_OR_NOT_gate_tb ();
    reg a,b;
    wire c,d,e;
    AND_OR_NOT_gate UUT (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e)
    ); 
initial begin
    a=0;
    b=0;
    #20 a=1;
    #20 a=0; b=1;
    #20 a=1; b=1;
    end 
endmodule 