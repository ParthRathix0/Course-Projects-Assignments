`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module dot_product_top #(
    parameter integer CLK_FREQ      = 100_000_000,
    parameter integer DB_CYCLES     = 1_000_000,
    parameter integer SCAN_HZ       = 1000,
    parameter integer RST_TICKS     = 500_000_000
)(
    input  wire        clk,
    input  wire        btnC,
    input  wire [7:0]  sw,
    input  wire        SW8, SW9,     // index
    input  wire        SW12, SW13,   // write A/B
    input  wire        SW14, SW15,   // read A/B
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    // debounce 
    wire rst_pulse;
    btn_debounce_onepulse #(.DB_CYCLES(DB_CYCLES)) u_rst (
        .clk(clk), .btn(btnC), .pulse(rst_pulse)
    );

    // storing vectors
    reg [7:0] A[0:3], B[0:3];
    reg [3:0] A_written, B_written;
    wire [1:0] idx = {SW9, SW8};

    integer k;
    always @(posedge clk) begin
        if (rst_pulse) begin
            for (k=0;k<4;k=k+1) begin A[k]<=8'h00; B[k]<=8'h00; end
            A_written <= 4'b0000;
            B_written <= 4'b0000;
        end else begin
            if (SW12) begin A[idx] <= sw; A_written[idx] <= 1'b1; end
            if (SW13) begin B[idx] <= sw; B_written[idx] <= 1'b1; end
        end
    end
    wire all_written = (&A_written) & (&B_written);
    
    // mac variables
    reg  [7:0] mac_b, mac_c;
    reg        mac_rst, mac_en;
    wire [15:0] acc;
    wire        oflo;

    mac_core u_mac (
        .clk(clk),
        .rst(mac_rst | rst_pulse),
        .en (mac_en),
        .b  (mac_b),
        .c  (mac_c),
        .acc(acc),
        .oflo(oflo)
    );

    reg [2:0] counter;
    always @(*) begin
        case (counter[1:0])
            2'd0: begin mac_b=A[0]; mac_c=B[0]; end
            2'd1: begin mac_b=A[1]; mac_c=B[1]; end
            2'd2: begin mac_b=A[2]; mac_c=B[2]; end
            2'd3: begin mac_b=A[3]; mac_c=B[3]; end
            default: begin mac_b=8'h00; mac_c=8'h00; end
        endcase
    end

    
    localparam S_IDLE  = 3'd0,
               S_CLEAR = 3'd1,
               S_RUN   = 3'd2;

    reg [2:0] state;
    reg       computing;
    reg       dirty;           

   
    wire set_dirty   = (SW12 || SW13);
    wire clear_dirty = (state == S_RUN) && (counter == 3); 

    always @(posedge clk) begin
        if (rst_pulse) begin
            state     <= S_IDLE;
            mac_rst   <= 1'b0;
            mac_en    <= 1'b0;
            counter   <= 3'd0;
            computing <= 1'b0;
            dirty     <= 1'b0;          
        end else begin
            
            mac_rst   <= 1'b0;
            mac_en    <= 1'b0;

            
            if (set_dirty)       dirty <= 1'b1;
            else if (clear_dirty) dirty <= 1'b0;

          
            case (state)
                S_IDLE: begin
                    computing <= 1'b0;
                    counter   <= 3'd0;
                    if (all_written && dirty) state <= S_CLEAR;
                end

                S_CLEAR: begin
                    mac_rst   <= 1'b1;    
                    computing <= 1'b1;
                    counter   <= 3'd0;
                    state     <= S_RUN;
                end

                S_RUN: begin
                    mac_en    <= 1'b1;    
                    computing <= 1'b1;
                    if (counter == 3) begin
                        state   <= S_IDLE; 
                        counter <= 3'd0;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // output
    assign led = acc;

    wire [7:0] read8 =
        (SW14 & ~SW15) ? A[idx] :
        (~SW14 & SW15) ? B[idx] : 8'h00;
    wire show_read8 = (SW14 ^ SW15);

    sevenseg_controller #(
        .CLK_FREQ (CLK_FREQ),
        .SCAN_HZ  (SCAN_HZ),
        .RST_TICKS(RST_TICKS)
    ) u_7seg (
        .clk       (clk),
        .rst_pulse (rst_pulse),
        .show_oflo (oflo),
        .result16  (acc),
        .read8     (read8),
        .show_read8(show_read8),
        .seg       (seg),
        .an        (an)
    );
endmodule



module btn_debounce_onepulse #(
    parameter integer DB_CYCLES = 1_000_000  
)(
    input  wire clk,
    input  wire btn,
    output reg  pulse  
);
    reg [31:0] cnt = 0;
    reg req = 1'b0, req_d = 1'b0;

    always @(posedge clk) begin
        if (btn) begin
            if (cnt < DB_CYCLES) begin
                cnt <= cnt + 1'b1;
            end else begin
                req <= 1'b1;
            end
        end else begin
            cnt <= 0;
            req <= 1'b0;
        end

        req_d  <= req;
        pulse  <= req & ~req_d;  // 1-cycle clean pulse on first stable press
    end
endmodule


module mac_core #(
    parameter integer W     = 8,
    parameter integer ACCW  = 16
)(
    input  wire                 clk,
    input  wire                 rst,      
    input  wire                 en,       
    input  wire [W-1:0]         b,
    input  wire [W-1:0]         c,
    output reg  [ACCW-1:0]      acc,
    output reg                  oflo
);
    wire [ACCW-1:0] product = b * c;           
    wire [ACCW:0]   sum_ext = {1'b0, acc} + {1'b0, product};

    always @(posedge clk) begin
        if (rst) begin
            acc  <= {ACCW{1'b0}};
            oflo <= 1'b0;
        end else begin
            if (en) begin
                acc  <= sum_ext[ACCW-1:0];     
                if (sum_ext[ACCW]) oflo <= 1'b1;
            end
        end
    end
endmodule


module sevenseg_controller #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer SCAN_HZ   = 1000,
    parameter integer RST_TICKS = 500_000_000  
)(
    input  wire        clk,
    input  wire        rst_pulse,      
    input  wire        show_oflo,      
    input  wire [15:0] result16,       
    input  wire [7:0]  read8,          
    input  wire        show_read8,     
    output reg  [6:0]  seg,
    output reg  [3:0]  an
);
    
    reg [31:0] rst_timer = 0;
    reg        show_rst  = 1'b0;

    always @(posedge clk) begin
        if (rst_pulse) begin
            rst_timer <= 0;
            show_rst  <= 1'b1;
        end else if (show_rst) begin
            if (rst_timer < RST_TICKS) rst_timer <= rst_timer + 1'b1;
            else show_rst <= 1'b0;
        end
    end

   
    localparam integer SCAN_DIV = (CLK_FREQ / SCAN_HZ);
    reg [31:0] scan_cnt = 0;
    reg [1:0]  digit    = 0;

    always @(posedge clk) begin
        if (scan_cnt == SCAN_DIV-1) begin
            scan_cnt <= 0;
            digit    <= digit + 1'b1;
        end else begin
            scan_cnt <= scan_cnt + 1'b1;
        end
    end

    // seven segment
    function [6:0] hex7(input [3:0] x);
        case (x)
            4'h0: hex7 = 7'b1000000;
            4'h1: hex7 = 7'b1111001;
            4'h2: hex7 = 7'b0100100;
            4'h3: hex7 = 7'b0110000;
            4'h4: hex7 = 7'b0011001;
            4'h5: hex7 = 7'b0010010;
            4'h6: hex7 = 7'b0000010;
            4'h7: hex7 = 7'b1111000;
            4'h8: hex7 = 7'b0000000;
            4'h9: hex7 = 7'b0010000;
            4'hA: hex7 = 7'b0001000; // A
            4'hB: hex7 = 7'b0000011; // b
            4'hC: hex7 = 7'b1000110; // C
            4'hD: hex7 = 7'b0100001; // d
            4'hE: hex7 = 7'b0000110; // E
            4'hF: hex7 = 7'b0001110; // F
            default: hex7 = 7'b1111111;
        endcase
    endfunction

    function [6:0] letter(input [7:0] ch);
        case (ch)
            "O": letter = 7'b1000000; 
            "F": letter = 7'b0001110;
            "L": letter = 7'b1000111;
            "r": letter = 7'b0101111; 
            "S": letter = 7'b0010010; 
            "t": letter = 7'b0000111; 
            "-": letter = 7'b0111111; 
            default: letter = 7'b1111111;
        endcase
    endfunction

    // displaying digit
    wire [3:0] nib0 = result16[3:0];
    wire [3:0] nib1 = result16[7:4];
    wire [3:0] nib2 = result16[11:8];
    wire [3:0] nib3 = result16[15:12];

    // an[0] 
    always @(*) begin
        an  = 4'b1111;
        seg = 7'b1111111;

        // default select digit
        case (digit)
            2'd0: an = 4'b1110;
            2'd1: an = 4'b1101;
            2'd2: an = 4'b1011;
            2'd3: an = 4'b0111;
        endcase

        if (show_oflo) begin
            
            case (digit)
                2'd3: seg = letter("O");
                2'd2: seg = letter("F");
                2'd1: seg = letter("L");
                2'd0: seg = letter("O");
            endcase
        end else if (show_rst) begin
            
            case (digit)
                2'd3: seg = letter("-");
                2'd2: seg = letter("r");
                2'd1: seg = letter("S");
                2'd0: seg = letter("t");
            endcase
        end else if (show_read8) begin
           
            case (digit)
                2'd0: seg = hex7(read8[3:0]);
                2'd1: seg = hex7(read8[7:4]);
                2'd2: seg = 7'b1111111;
                2'd3: seg = 7'b1111111;
            endcase
        end else begin
           
            case (digit)
                2'd0: seg = hex7(nib0);
                2'd1: seg = hex7(nib1);
                2'd2: seg = hex7(nib2);
                2'd3: seg = hex7(nib3);
            endcase
        end
    end
endmodule

