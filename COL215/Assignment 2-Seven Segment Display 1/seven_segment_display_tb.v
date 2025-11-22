`timescale 1ns / 1ps



module seven_segment_display_tb;

    reg [9:0] sw;
    wire [6:0] cat;
    wire [3:0] anode;
seven_catment_display uut (
    .sw(sw),
    .cat(cat),
    .anode(anode) 
);
initial begin 
    sw=0;
    #10 sw=10'b0000000001;
    #10 sw=10'b0000000010;
    #10 sw=10'b0000000100;
    #10 sw=10'b0000001000;
    #10 sw=10'b0000010000;
    #10 sw=10'b0000100000;
    #10 sw=10'b0001000000;
    #10 sw=10'b0010000000;
    #10 sw=10'b0100000000;
    #10 sw=10'b1000000000;
    #10 sw=10'b0001010100; //testing priority order
    #10 sw=10'b0101010101; 
    
end 
always @(sw or cat or anode) begin
    $display("time: %0t | Switches: %b | Cathodes: %b | Anode: %b", $time, sw, cat, anode);
end 

endmodule
