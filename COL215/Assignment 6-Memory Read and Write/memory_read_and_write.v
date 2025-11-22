`timescale 1ns / 1ps

module controller(
    input clk,
    input btnC,
    input [15:0] sw,
    output [3:0] an,
    output [6:0] seg,
    output wire dp
    
);

    // Signal declarations
    wire [9:0] address;
    wire [3:0] data_in_b;
    wire [1:0] mode;

    wire debounced_reset;

    // Memory signals
    wire [3:0] rom_data_out; // Vector A
    wire [3:0] ram0_data_out; // Vector B
    wire [4:0] ram1_data_out; // Vector C
    
    reg ram0_write_en;
    reg [3:0] ram0_data_in;

    reg ram1_write_en;
    reg [4:0] ram1_data_in;

    // Display signals
    reg display_on_signal;
    reg [3:0] display_digit_3;
    reg [3:0] display_digit_2;
    reg [3:0] display_digit_1;
    reg [3:0] display_digit_0;

    reg reset_active;
    reg [28:0] reset_counter; 

    // State registers for single-shot operations
    reg [1:0] prev_mode;
    reg [9:0] prev_address;

    // Assign inputs from switches
    assign address = sw[13:4];
    assign data_in_b = sw[3:0];
    assign mode = sw[15:14];
    assign dp=1;

    // Instantiate debouncer for the reset button
    debouncer reset_debouncer (
        .clk(clk),
        .button_in(btnC),
        .button_out(debounced_reset)
    );

    // Memory Instantiations (ensure names match your IP cores)
    dist_mem_gen_0 rom_instance ( .clk(clk), .a(address), .qspo(rom_data_out) );
    dist_mem_gen_1 ram0_instance ( .clk(clk), .a(address), .d(ram0_data_in), .we(ram0_write_en), .qspo(ram0_data_out) );
    dist_mem_gen_2 ram1_instance ( .clk(clk), .a(address), .d(ram1_data_in), .we(ram1_write_en), .qspo(ram1_data_out) );

    // Instantiate the seven-segment display driver
    seven_segment_display display_driver (
        .clk(clk),
        .reset_active(reset_active),
        .display_on(display_on_signal),
        .digit3(display_digit_3),
        .digit2(display_digit_2),
        .digit1(display_digit_1),
        .digit0(display_digit_0),
        .an(an),
        .seg(seg)
    );

    // Logic for handling reset
    always @(posedge clk) begin
        if (debounced_reset) begin
            reset_active <= 1;
            reset_counter <= 500_000_000; // 5 seconds at 100MHz clock
        end else if (reset_counter > 0) begin
            reset_counter <= reset_counter - 1;
            reset_active <= 1;
        end else begin
            reset_active <= 0;
        end
    end

    // Main control logic
    always @(posedge clk) begin
        // Update previous state registers
        prev_mode <= mode;
        prev_address <= address;
        
        // Default all signals to an inactive or blank state on every cycle.
        ram0_write_en <= 0;
        ram1_write_en <= 0;
        display_on_signal <= 0;
        display_digit_0 <= 4'hF; 
        display_digit_1 <= 4'hF;
        display_digit_2 <= 4'hF;
        display_digit_3 <= 4'hF;

        if (!reset_active) begin
            case (mode)
                2'b01: begin // Read Mode
                    display_on_signal <= 1;
                    ram1_data_in <= rom_data_out + ram0_data_out;
                    ram1_write_en <= 1;
                    display_digit_0 <= rom_data_out;
                    display_digit_1 <= ram0_data_out;
                    display_digit_2 <= ram1_data_in[3:0];
                    display_digit_3 <= {3'b0, ram1_data_in[4]};
                end

                2'b10: begin // Write RAM0 Mode
                    if (mode != prev_mode || address != prev_address) begin
                        ram0_data_in <= data_in_b;
                        ram0_write_en <= 1;
                    end
                end

                2'b11: begin // Increment RAM0 Mode
                    if (mode != prev_mode || address != prev_address) begin
                        ram0_data_in <= ram0_data_out + 1;
                        ram0_write_en <= 1;
                    end
                end

                default: begin
                
                end
            endcase
        end
    end

endmodule






`timescale 1ns / 1ps

module seven_segment_display(
    input clk,
    input reset_active,
    input display_on,
    input [3:0] digit3,
    input [3:0] digit2,
    input [3:0] digit1,
    input [3:0] digit0,

    output reg [3:0] an,
    output reg [6:0] seg

);

    reg [19:0] refresh_counter = 0;
    reg [1:0] active_digit = 0;
    

    // Refresh rate control (approx 800 Hz)
    always @(posedge clk) begin
//        dp<=0;
        refresh_counter <= refresh_counter + 1;
        if(refresh_counter >=125000) begin 
            refresh_counter <= 0;
            active_digit <= active_digit + 1;
        end
    end

    // Anode control
    always @(*) begin
        case (active_digit)
            2'b00: an = 4'b1110; // Activate digit 0
            2'b01: an = 4'b1101; // Activate digit 1
            2'b10: an = 4'b1011; // Activate digit 2
            2'b11: an = 4'b0111; // Activate digit 3
            default: an = 4'b1111; // Off
        endcase
    end

    // Hex to 7-segment decoder and multiplexer
    always @(*) begin
        
        if (reset_active) begin
            case(active_digit)
                // Display "-rSt"
                2'b00: seg = 7'b0001111; // t
                2'b01: seg = 7'b0010010; // S
                2'b10: seg = 7'b0101111; // r
                2'b11: seg = 7'b0111111; // -
                default: seg = 7'b1111111; // Off
            endcase
        end
        else if (!display_on) begin
             seg = 7'b1111111; // All segments off
        end else begin
            case(active_digit)
                2'b00: seg = decode(digit0);
                2'b01: seg = decode(digit1);
                2'b10: seg = decode(digit2);
                2'b11: seg = decode(digit3);
                default: seg = 7'b1111111; // Off
            endcase
        end
    end

    // Function to decode a 4-bit hex value to 7-segment display pattern
    function [6:0] decode (input [3:0] data);
        case(data)
            4'h0: decode = 7'b1000000; // 0
            4'h1: decode = 7'b1111001; // 1
            4'h2: decode = 7'b0100100; // 2
            4'h3: decode = 7'b0110000; // 3
            4'h4: decode = 7'b0011001; // 4
            4'h5: decode = 7'b0010010; // 5
            4'h6: decode = 7'b0000010; // 6
            4'h7: decode = 7'b1111000; // 7
            4'h8: decode = 7'b0000000; // 8
            4'h9: decode = 7'b0010000; // 9
            4'hA: decode = 7'b0001000; // A
            4'hB: decode = 7'b0000011; // b
            4'hC: decode = 7'b1000110; // C
            4'hD: decode = 7'b0100001; // d
            4'hE: decode = 7'b0000110; // E
            4'hF: decode = 7'b0001110; // F
            default: decode = 7'b1111111; // Off
        endcase
    endfunction
endmodule





`timescale 1ns / 1ps

module debouncer(
    input clk,
    input button_in,
    output reg button_out
);

    reg [19:0] counter = 0; 
    reg internal_state = 0;

    always @(posedge clk) begin
        if (button_in != internal_state) begin
            counter <= counter + 1;
            if (counter >= 1000000) begin // Stable for ~10ms
                internal_state <= button_in;
                button_out <= button_in;
                counter <= 0;
            end
        end else begin
            counter <= 0;
        end
    end

endmodule