`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// MAC Unit - Multiply Accumulate Unit
// COL215 Lab Assignment 4
//////////////////////////////////////////////////////////////////////////////////

module mac_unit #(
    parameter INIT_VALUE = 16'h0000
)(
    input clk,
    input rst,
    input [7:0] sw,
    input sw10,     // b capture
    input sw11,     // c capture
    input sw12,     // MAC enable
    output [15:0] led,
    output [3:0] an,
    output [6:0] seg
);

    // Internal registers
    reg [7:0] b_reg, c_reg;
    reg [15:0] accumulator;
    reg sw12_del;
    reg overflow_detected;
    reg reset_display_active;
    reg [32:0] timer; // Reduced for simulation

    // Edge detection for sw12
    wire sw12_edge = sw12 & ~sw12_del;

    // Product calculation
    reg [15:0] product;

    // Overflow detection
    reg [16:0] sum;
    reg overflow;

    // Output assignments
    assign led = accumulator;

    // Main logic
    always @(posedge clk) begin
        if (rst) begin
            b_reg <= 8'h00;
            c_reg <= 8'h00;
            accumulator <= INIT_VALUE;
            sw12_del <= 1'b0;
            overflow_detected <= 1'b0;
            reset_display_active <= 1'b1;
            timer <= 32'd500_000_000;
        end else begin
            sw12_del <= sw12;

            // Input capture
            if (sw10) b_reg <= sw;
            if (sw11) c_reg <= sw;
            // Product calculation
            product = b_reg * c_reg;

                // Overflow detection
            sum = accumulator + product;
            overflow = sum[16];

            // MAC operation
            if (sw12_edge && !overflow_detected) begin
                if (overflow) begin
                    overflow_detected <= 1'b1;
                    accumulator <= 16'h0000;
                end else begin
                    accumulator <= sum[15:0];
                end
            end
            // Reset display timer
             if (reset_display_active) begin
                if (timer > 0)
                    timer <= timer - 1;
                else
                    reset_display_active <= 1'b0;

             end
       end
    end

    // 7-segment display
    display_controller disp_ctrl (
        .clk(clk),
        .reset_active(reset_display_active),
        .overflow_active(overflow_detected),
        .an(an),
        .seg(seg)
    );

endmodule

//////////////////////////////////////////////////////////////////////////////////
// 7-Segment Display Controller
//////////////////////////////////////////////////////////////////////////////////

module display_controller(
    input clk,
    input reset_active,
    input overflow_active,
    output reg [3:0] an,
    output reg [6:0] seg
);

    reg [19:0] refresh_counter;
    wire [1:0] digit_sel = refresh_counter[19:18];

    always @(posedge clk) refresh_counter <= refresh_counter + 1;

    always @(*) begin
        if (reset_active) begin
            // Display "-rSt"
            case (digit_sel)
                2'b00: {an, seg} = {4'b1110, 7'b0000111}; // 't'
                2'b01: {an, seg} = {4'b1101, 7'b0010010}; // 'S'
                2'b10: {an, seg} = {4'b1011, 7'b0101111}; // 'r'
                2'b11: {an, seg} = {4'b0111, 7'b0111111}; // '-'
            endcase
        end else if (overflow_active) begin
            // Display "OFLO"
            case (digit_sel)
                2'b00: {an, seg} = {4'b0111, 7'b1000000}; // 'O'
                2'b01: {an, seg} = {4'b1101, 7'b1000111}; // 'L'
                2'b10: {an, seg} = {4'b1011, 7'b0001110}; // 'F'
                2'b11: {an, seg} = {4'b1110, 7'b1000000}; // 'O'
            endcase
        end else begin
            {an, seg} = {4'b1111, 7'b1111111}; // Off
        end
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Debounce Module
//////////////////////////////////////////////////////////////////////////////////

module debounce #(
    parameter COUNTER_MAX = 20'd1000
)(
    input clk,
    input rst,
    input button_in,
    output reg button_out
);

    reg [19:0] counter;
    reg button_sync [1:0];

    always @(posedge clk) begin
        if (rst) begin
            button_sync[0] <= 1'b0;
            button_sync[1] <= 1'b0;
            counter <= 0;
            button_out <= 1'b0;
        end else begin
            button_sync[0] <= button_in;
            button_sync[1] <= button_sync[0];

            if (button_sync[1] == button_out) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
                if (counter >= COUNTER_MAX) begin
                    button_out <= button_sync[1];
                    counter <= 0;
                end
            end
        end
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Top Level Module
//////////////////////////////////////////////////////////////////////////////////

module mac_top #(
    parameter INIT_VALUE = 16'h0000
)(
    input clk,
    input btnc,
    input [12:0] sw,
    output [15:0] led,
    output [3:0] an,
    output [6:0] seg
);

    wire rst_debounced;

    debounce #(.COUNTER_MAX(20'd1000)) rst_debounce (
        .clk(clk),
        .rst(1'b0),
        .button_in(btnc),
        .button_out(rst_debounced)
    );

    mac_unit #(.INIT_VALUE(INIT_VALUE)) mac_inst (
        .clk(clk),
        .rst(rst_debounced),
        .sw(sw[7:0]),
        .sw10(sw[10]),
        .sw11(sw[11]),
        .sw12(sw[12]),
        .led(led),
        .an(an),
        .seg(seg)
    );

endmodule
