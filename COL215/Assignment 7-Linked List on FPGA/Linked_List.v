`timescale 1ns / 1ps

module linked_list_top #(
    parameter SIZE = 32
) (
    input  wire        clk,
    input  wire [15:0] sw,
    input  wire        btnC,
    output wire [1:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);

    wire btn_reset_pulse;
    wire led_overflow_flag;
    wire led_underflow_flag;

    wire display_reset_active;
    wire display_on;
    wire [3:0] display_d3;
    wire [3:0] display_d2;
    wire [3:0] display_d1;
    wire [3:0] display_d0;

    debouncer rst_debouncer (
        .clk(clk),
        .button_in(btnC),
        .button_out(btn_reset_pulse)
    );

    linked_list_core #(
        .SIZE(SIZE)
    ) core_logic (
        .clk(clk),
        .rst_pulse(btn_reset_pulse),
        .op_code(sw[15:13]),
        .data_in(sw[7:0]),
        .led_overflow(led_overflow_flag),
        .led_underflow(led_underflow_flag),
        .display_reset_active(display_reset_active),
        .display_on(display_on),
        .display_digit3(display_d3),
        .display_digit2(display_d2),
        .display_digit1(display_d1),
        .display_digit0(display_d0)
    );

    seven_segment_driver display_driver (
        .clk(clk),
        .reset_active(display_reset_active),
        .display_on(display_on),
        .digit3(display_d3),
        .digit2(display_d2),
        .digit1(display_d1),
        .digit0(display_d0),
        .an(an),
        .seg(seg)
    );
    assign led[0] = led_overflow_flag;
    assign led[1] = led_underflow_flag;

endmodule

module linked_list_core #(
    parameter SIZE = 32
) (
    input  wire        clk,
    input  wire        rst_pulse,
    input  wire [2:0]  op_code,
    input  wire [7:0]  data_in,

    output wire        led_overflow,
    output wire        led_underflow,

    output reg         display_reset_active,
    output reg         display_on,
    output reg [3:0]   display_digit3,
    output reg [3:0]   display_digit2,
    output reg [3:0]   display_digit1,
    output reg [3:0]   display_digit0
);

    localparam PTR_WIDTH = $clog2(SIZE + 1);
    localparam INVALID_PTR = SIZE;
    localparam CLK_FREQ = 100_000_000;
    localparam TRAVERSE_SECONDS = 2;
    localparam RESET_SECONDS = 5;
    // Fsm states
    localparam S_IDLE             = 4'h0;
    localparam S_INSERT_HEAD      = 4'h1;
    localparam S_INSERT_TAIL      = 4'h2;
    localparam S_DELETE_SEARCH    = 4'h3;
    localparam S_DELETE_EXEC      = 4'h4;
    localparam S_TRAVERSE_START   = 4'h5;
    localparam S_TRAVERSE_DISPLAY = 4'h6;
    localparam S_RESET_PULSE      = 4'hA;
    localparam S_RESET_DISPLAY    = 4'hB;
    localparam S_RESET_INIT       = 4'hC;
    //operations
    localparam OP_IDLE_1        = 3'b000;
    localparam OP_IDLE_2        = 3'b001;
    localparam OP_IDLE_3        = 3'b010;
    localparam OP_IDLE_4        = 3'b011;
    localparam OP_INSERT_HEAD   = 3'b100;
    localparam OP_INSERT_TAIL   = 3'b101;
    localparam OP_DELETE        = 3'b110;
    localparam OP_TRAVERSE      = 3'b111;

    reg [7:0] node_data [0:SIZE-1];
    reg [PTR_WIDTH-1:0] node_next [0:SIZE-1];

    reg [PTR_WIDTH-1:0] list_head;
    reg [PTR_WIDTH-1:0] list_tail;
    reg [PTR_WIDTH-1:0] free_head;
    reg [$clog2(SIZE+1)-1:0] list_size;

    reg [3:0] state,next_state;

    reg overflow_reg,underflow_reg;
    reg [PTR_WIDTH-1:0] current_ptr, prev_ptr;
    reg [31:0] timer_counter;

    reg [2:0] last_op_code;
    reg op_start_reg;

    integer i;

    assign led_overflow = overflow_reg;
    assign led_underflow = underflow_reg;

    always @(posedge clk) begin
        last_op_code<=op_code;
        op_start_reg<=(op_code != last_op_code) && (op_code[2] == 1'b1);
    end

    always @(posedge clk) begin
        if (state == S_RESET_INIT) begin
            state <= S_IDLE;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                node_next[i] <= i + 1;
            end
            node_next[SIZE-1] <= INVALID_PTR;

            free_head<=0;
            list_head<=INVALID_PTR;
            list_tail<=INVALID_PTR;
            list_size<=0;
            overflow_reg <= 0;
            underflow_reg <= 0;
            prev_ptr <= INVALID_PTR;
            current_ptr <= INVALID_PTR;
            timer_counter <= 0;
        end else begin
            state <= next_state;

            if (next_state == S_RESET_DISPLAY || next_state == S_TRAVERSE_DISPLAY) begin
                if (timer_counter >= ((state == S_RESET_DISPLAY ? RESET_SECONDS : TRAVERSE_SECONDS) * CLK_FREQ) - 1) begin
                    timer_counter <= 0;
                end else begin
                    timer_counter <= timer_counter + 1;
                end
            end else begin
                timer_counter <= 0;
            end

            if (op_start_reg) begin
                if ((op_code == OP_DELETE || op_code == OP_TRAVERSE) && list_head == INVALID_PTR) begin
                    underflow_reg <= 1;
                    overflow_reg <= 0;
                end else begin
                    underflow_reg <= 0;
                    overflow_reg <= 0;
                end
            end else if (state == S_DELETE_SEARCH && next_state == S_IDLE && current_ptr == INVALID_PTR) begin
                underflow_reg <= 1;
            end

            case (next_state)
                S_IDLE: begin
                end

                S_INSERT_HEAD: begin
                    if (free_head != INVALID_PTR) begin
                        node_data[free_head] <= data_in;
                        node_next[free_head] <= list_head;
                        list_head <= free_head;
                        if (list_tail == INVALID_PTR) begin
                            list_tail <= free_head;
                        end
                        list_size <= list_size + 1;
                        free_head <= node_next[free_head];
                    end else begin
                        overflow_reg <= 1;
                    end
                end

                S_INSERT_TAIL: begin
                    if (free_head != INVALID_PTR) begin
                        node_data[free_head] <= data_in;
                        node_next[free_head] <= INVALID_PTR;
                        if (list_tail != INVALID_PTR) begin
                            node_next[list_tail] <= free_head;
                        end else begin
                            list_head <= free_head;
                        end
                        list_tail <= free_head;
                        list_size <= list_size + 1;
                        free_head <= node_next[free_head];
                    end else begin
                        overflow_reg <= 1;
                    end
                end

                S_DELETE_SEARCH: begin
                    if (state != S_DELETE_SEARCH) begin
                        prev_ptr <= INVALID_PTR;
                        current_ptr <= list_head;
                    end else begin
                        prev_ptr <= current_ptr;
                        if (current_ptr != INVALID_PTR) begin
                            current_ptr <= node_next[current_ptr];
                        end
                    end
                end

                S_DELETE_EXEC: begin
                    if (prev_ptr == INVALID_PTR) begin
                        list_head <= node_next[current_ptr];
                    end else begin
                        node_next[prev_ptr] <= node_next[current_ptr];
                    end

                    if (node_next[current_ptr] == INVALID_PTR) begin
                        list_tail <= prev_ptr;
                    end

                    node_next[current_ptr] <= free_head;
                    free_head <= current_ptr;
                    list_size <= list_size - 1;
                end

                S_TRAVERSE_START: begin
                    current_ptr <= list_head;
                end

                S_TRAVERSE_DISPLAY: begin
                    if (timer_counter >= (TRAVERSE_SECONDS * CLK_FREQ) - 1) begin
                        if (current_ptr != INVALID_PTR) begin
                            current_ptr <= node_next[current_ptr];
                        end
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (rst_pulse) begin
                    next_state = S_RESET_PULSE;
                end else if (op_start_reg) begin
                    case (op_code)
                        OP_INSERT_HEAD: next_state = S_INSERT_HEAD;
                        OP_INSERT_TAIL: next_state = S_INSERT_TAIL;
                        OP_DELETE: begin
                            if (list_head == INVALID_PTR) begin
                                next_state = S_IDLE;
                            end else begin
                                next_state = S_DELETE_SEARCH;
                            end
                        end
                        OP_TRAVERSE: begin
                            if (list_head == INVALID_PTR) begin
                                next_state = S_IDLE;
                            end else begin
                                next_state = S_TRAVERSE_START;
                            end
                        end
                        default: next_state = S_IDLE;
                    endcase
                end
            end

            S_INSERT_HEAD, S_INSERT_TAIL: begin
                next_state = S_IDLE;
            end

            S_DELETE_SEARCH: begin
                if (current_ptr == INVALID_PTR) begin
                    next_state = S_IDLE;
                end else if (node_data[current_ptr] == data_in) begin
                    next_state = S_DELETE_EXEC;
                end else begin
                    next_state = S_DELETE_SEARCH;
                end
            end

            S_DELETE_EXEC: begin
                next_state = S_IDLE;
            end

            S_TRAVERSE_START: begin
                next_state = S_TRAVERSE_DISPLAY;
            end

            S_TRAVERSE_DISPLAY: begin
                if (timer_counter >= (TRAVERSE_SECONDS * CLK_FREQ) - 1) begin
                    if (current_ptr == INVALID_PTR) begin
                        next_state = S_IDLE;
                    end else if (node_next[current_ptr] == INVALID_PTR) begin
                        next_state = S_IDLE;
                    end else begin
                        next_state = S_TRAVERSE_DISPLAY;
                    end
                end else begin
                    next_state = S_TRAVERSE_DISPLAY;
                end
            end

            S_RESET_PULSE: begin
                next_state = S_RESET_DISPLAY;
            end

            S_RESET_DISPLAY: begin
                if (timer_counter >= (RESET_SECONDS * CLK_FREQ) - 1) begin
                    next_state = S_RESET_INIT;
                end else begin
                    next_state = S_RESET_DISPLAY;
                end
            end

            S_RESET_INIT: begin
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_RESET_INIT;
            end
        endcase
    end

    always @(*) begin
        display_reset_active = 0;
        display_on = 0;
        case (state)
            S_RESET_DISPLAY: begin
                display_reset_active = 1;
                display_on = 0;
            end

            S_TRAVERSE_DISPLAY: begin
                if (current_ptr != INVALID_PTR) begin
                    display_on = 1;
                    display_digit1 = node_data[current_ptr][7:4];
                    display_digit0 = node_data[current_ptr][3:0];
                end
            end

            default: begin
                display_reset_active = 0;
                display_on = 0;
            end
        endcase
    end

    initial begin
        state = S_RESET_INIT;
    end

endmodule

module seven_segment_driver(
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

    localparam REFRESH_MAX = (50_000_000 / 1000) - 1;
    reg [15:0] refresh_counter = 0;
    reg [1:0] active_digit = 0;

    always @(posedge clk) begin
        if (refresh_counter>= (REFRESH_MAX / 4)) begin
            refresh_counter <= 0;
            active_digit <= active_digit + 1;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    always @(*) begin
        case (active_digit)
            2'b00: seg = 7'b0001111;
            2'b01: seg = 7'b0010010;
            2'b10: seg = 7'b0101111;
            2'b11: seg = 7'b0111111;

            default: an = 4'b1111;
        endcase
    end

    always @(*) begin
        if (reset_active) begin
            case(active_digit)
                2'b00: seg = 7'b1111000;
                2'b01: seg = 7'b0100100;
                2'b10: seg = 7'b1111010;
                2'b11: seg = 7'b1111110;
                default: seg =7'b1111111;
            endcase
        end
        else if (!display_on) begin
             seg = 7'b1111111;
        end else begin
            case(active_digit)
                2'b00: seg = decode(digit0);
                2'b01: seg = decode(digit1);
                2'b10: seg = 7'b1111111;// so only an[0] and an[1] are active
                2'b11: seg = 7'b1111111;
                default: seg = 7'b1111111;
            endcase
        end
    end
    // To display the elements
    function [6:0] decode (input [3:0] data);
        case(data)
            4'h0: decode = 7'b1000000;
            4'h1: decode = 7'b1111001;
            4'h2: decode = 7'b0100100;
            4'h3: decode = 7'b0110000;
            4'h4: decode = 7'b0011001;
            4'h5: decode = 7'b0010010;
            4'h6: decode = 7'b0000010;
            4'h7: decode = 7'b1111000;
            4'h8: decode = 7'b0000000;
            4'h9: decode = 7'b0010000;
            4'hA: decode = 7'b0000100;
            4'hB: decode = 7'b0000011;
            4'hC: decode = 7'b1000110;
            4'hD: decode = 7'b0100001;
            4'hE: decode = 7'b0000110;
            4'hF: decode = 7'b0001110;

            default: decode = 7'b1111111;
        endcase
    endfunction
endmodule

module debouncer(
    input clk,
    input button_in,
    output reg button_out
);
    reg [19:0] counter = 0;
    reg internal_state = 0;
    always @(posedge clk) begin
        if (button_in!=internal_state) begin
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