`timescale 1ns / 1ps

//=================================================================
//
// Module: Display_sprite
// Description: Main module for Road Fighter game 
//              Drives VGA, handles main car, scrolling background,
//              and a moving rival car with collision detection.
//
//=================================================================
module Display_sprite #(
        // Size of signal to store  horizontal and vertical pixel coordinate
        parameter pixel_counter_width = 10,
        parameter OFFSET_BG_X = 200,
        parameter OFFSET_BG_Y = 150
    )
    (
        input clk,
        input BTNC,
        input BTNR,
        input BTNL,
        output HS, VS,
        output [11:0] vgaRGB
    );

    // Background dimensions
    localparam bg1_width = 160;
    localparam bg1_height = 240;

    // Main Car dimensions
    localparam main_car_width = 14;
    localparam main_car_height = 16;

    // --- Part 3: Rival Car ---
    localparam rival_car_width = 14;
    localparam rival_car_height = 16;
    localparam RIVAL_PINK = 12'b101000001010; // Pink color for rival car
    localparam RIVAL_ROAD_LEFT = 44;  // Left-most spawn pixel (relative to BG)
    localparam RIVAL_ROAD_RIGHT = 104; // Right-most spawn pixel (relative to BG)
    localparam RIVAL_RANDOM_RANGE = RIVAL_ROAD_RIGHT - RIVAL_ROAD_LEFT + 1; // = 61
    localparam RIVAL_FRAME_SPEED = 1; // Rival car moves 1px every 1 frames
    // ---------------------------

    // VGA driver signals
    wire pixel_clock;
    wire [3:0] vgaRed, vgaGreen, vgaBlue;
    wire [pixel_counter_width-1:0] hor_pix, ver_pix;
    reg [11:0] output_color;
    reg [11:0] next_color;

    // ROM signals
    reg [15:0] bg_rom_addr;
    wire [11:0] bg_color;
    reg [7:0] car_rom_addr;
    wire [11:0] car_color;
    reg [7:0] rival_rom_addr;
    wire [11:0] rival_color;

    // Sprite drawing logic
    reg bg_on, car_on, rival_on;
    wire [pixel_counter_width-1:0] car_x, car_y;

    // Button signals
    wire debounced_reset;
    wire debounced_right;
    wire debounced_left;

    // FSM state
    wire [2:0] car_fsm_state;
    localparam FSM_COLLIDE = 2;
    localparam FSM_START = 0;

    // Background Scrolling Logic
    reg [7:0] bg_y_offset = bg1_height-1;
    reg [24:0] scroll_counter = 0;
    // TO CHANGE SPEED: Change this value. Smaller = Faster.
    localparam SCROLL_PERIOD = 500000; // 1px move every 5ms @ 100MHz

    // Background ROM address calculation
    wire [9:0] hor_addr_on_screen = hor_pix - OFFSET_BG_X;
    wire [9:0] ver_addr_on_screen = ver_pix - OFFSET_BG_Y;
    wire [10:0] wrapped_ver_addr = ver_addr_on_screen + bg_y_offset;
    wire [7:0] ver_addr_in_rom = (wrapped_ver_addr >= bg1_height) ? (wrapped_ver_addr - bg1_height) : wrapped_ver_addr;

    // --- Part 3: Rival Car Logic ---
    wire [7:0] lfsr_out; // Random number
    reg [9:0] rival_x_reg;
    reg [9:0] rival_y_reg;
    reg [3:0] frame_counter = 0;

    // Vertical Sync (VS) signal synchronization for frame counting
    reg vs_sync_0, vs_sync_1;
    wire vs_falling_edge = vs_sync_0 & ~vs_sync_1; // 1 -> 0 edge detection

    // Trigger to move rival car 1 pixel down
    wire rival_move_trigger = (vs_falling_edge && (frame_counter == RIVAL_FRAME_SPEED - 1));

    // Map 8-bit LFSR (0-255) to the 61-pixel horizontal range (0-60)
    // This is a hardware-friendly way to do (lfsr_out % 61)
    // We only take a new random number when respawning.
    reg [5:0] random_base_x; // Stores 0-60
    always @(posedge clk) begin
        if (lfsr_out < 244) begin // 244 is 4 * 61, prevents modulo bias
            random_base_x <= lfsr_out % RIVAL_RANDOM_RANGE;
        end
    end

    // Main vs Rival Collision Detection (2D Bounding Box)
    wire x_overlap = (car_x < rival_x_reg + rival_car_width) && (car_x + main_car_width > rival_x_reg);
    wire y_overlap = (car_y < rival_y_reg + rival_car_height) && (car_y + main_car_height > rival_y_reg);
    wire main_vs_rival_collision = x_overlap && y_overlap && rival_on; // Only collide if rival is drawn
    // ---------------------------------

    // Debouncer instantiations
    debouncer reset_debouncer( .clk(clk), .button_in(BTNC), .button_out(debounced_reset) );
    debouncer left_debouncer( .clk(clk), .button_in(BTNL), .button_out(debounced_left) );
    debouncer right_debouncer( .clk(clk), .button_in(BTNR), .button_out(debounced_right) );

    // LFSR instantiation (Part 3)
    lfsr lfsr_inst ( .clk(clk), .rst(car_fsm_state == FSM_START), .data(lfsr_out) );

    //Main display driver
    VGA_driver #( .WIDTH(pixel_counter_width) ) display_driver (
        .clk(clk), .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue),
        .HS(HS), .VS(VS), .vgaRGB(vgaRGB), .pixel_clock(pixel_clock),
        .hor_pix(hor_pix), .ver_pix(ver_pix)
    );

    // ROM for background image
    bg_rom bg1_rom ( .clka(clk), .addra(bg_rom_addr), .douta(bg_color) );
    // ROM for main car
    main_car_rom car1_rom ( .clka(clk), .addra(car_rom_addr), .douta(car_color) );
    // ROM for rival car (Part 3)
    rival_car_rom car2_rom ( .clka(clk), .addra(rival_rom_addr), .douta(rival_color) );

    // FSM instantiation (Augmented for Part 3)
    fsm_car_state fsm(
        .clk(clk), .rst(1'b0), .BTNC(debounced_reset),
        .BTNL(debounced_left), .BTNR(debounced_right),
        .rival_collision(main_vs_rival_collision), // New collision input
        .car_x(car_x), .state(car_fsm_state)
    );

    // Car's vertical position is fixed
    assign car_y = 300;

    // --- Part 3: VS Synchronizer & Frame Counter ---
    always @(posedge clk) begin
        vs_sync_0 <= VS;
        vs_sync_1 <= vs_sync_0;

        if (car_fsm_state != FSM_COLLIDE && car_fsm_state != FSM_START) begin
            if (vs_falling_edge) begin
                if (frame_counter == RIVAL_FRAME_SPEED - 1) begin
                    frame_counter <= 0;
                end else begin
                    frame_counter <= frame_counter + 1;
                end
            end
        end else if (car_fsm_state == FSM_START) begin
            frame_counter <= 0; // Reset counter
        end
    end

    // --- Part 3: Rival Car Spawning and Movement ---
    always @(posedge clk) begin : RIVAL_CAR_LOGIC
        if (car_fsm_state == FSM_START) begin
            // Reset on game start
            rival_y_reg <= OFFSET_BG_Y;
            rival_x_reg <= (RIVAL_ROAD_LEFT + random_base_x) + OFFSET_BG_X;
        end
        else if (car_fsm_state != FSM_COLLIDE) begin
            // Game is running
            if (rival_move_trigger) begin
                rival_y_reg <= rival_y_reg + 1; // Move down 1 pixel
            end

            // Check for respawn (if off-screen)
            if (rival_y_reg > (OFFSET_BG_Y + bg1_height - rival_car_height)) begin
                rival_y_reg <= OFFSET_BG_Y; // Respawn at top
                rival_x_reg <= (RIVAL_ROAD_LEFT + random_base_x) + OFFSET_BG_X; // Get new random X
            end
        end
        // On collide, rival_x_reg and rival_y_reg freeze
    end

    // Background scrolling
    always @ (posedge clk) begin : BG_SCROLL_LOGIC
        if (car_fsm_state == FSM_COLLIDE) begin
            scroll_counter <= scroll_counter; // Freeze
        end
        else if (car_fsm_state == FSM_START) begin
            scroll_counter <= 0; // Reset
            bg_y_offset <= 0;
        end
        else begin
            // Game is running
            if (scroll_counter == SCROLL_PERIOD - 1) begin
                scroll_counter <= 0;
                if (bg_y_offset == 0) begin
                    bg_y_offset <= bg1_height-1;
                end else begin
                    bg_y_offset <= bg_y_offset - 1;
                end
            end else begin
                scroll_counter <= scroll_counter + 1;
            end
        end
    end

    // Calculates address for main car sprite
    always @ (posedge clk) begin : CAR_LOCATION
        if (hor_pix >= car_x && hor_pix < (car_x + main_car_width) && ver_pix >= car_y && ver_pix < (car_y + main_car_height)) begin
            car_rom_addr <= (hor_pix - car_x) + (ver_pix - car_y)*main_car_width;
            car_on <= 1;
        end
        else begin
            car_on <= 0;
        end
    end

    // Calculates address for rival car sprite (Part 3)
    always @ (posedge clk) begin : RIVAL_CAR_LOCATION
        if (hor_pix >= rival_x_reg && hor_pix < (rival_x_reg + rival_car_width) &&
            ver_pix >= rival_y_reg && ver_pix < (rival_y_reg + rival_car_height)) begin
            rival_rom_addr <= (hor_pix - rival_x_reg) + (ver_pix - rival_y_reg)*rival_car_width;
            rival_on <= 1;
        end
        else begin
            rival_on <= 0;
        end
    end

    // Calculates address for background sprite (with scrolling)
    always @ (posedge clk) begin : BG_LOCATION
        if (hor_pix >= 0 + OFFSET_BG_X && hor_pix < bg1_width + OFFSET_BG_X &&
            ver_pix >= 0 + OFFSET_BG_Y && ver_pix < bg1_height + OFFSET_BG_Y)
        begin
            bg_on <= 1;
            bg_rom_addr <= hor_addr_on_screen + (ver_addr_in_rom * bg1_width);
        end
        else
        begin
            bg_on <= 0;
        end
    end

    // MUX for deciding which color to send to VGA (with Part 3)
    always @ (posedge clk) begin : MUX_VGA_OUTPUT
        if (car_on && car_color != 12'b101000001010) begin // Main car 
            next_color <= car_color;
        end
        else if (rival_on && rival_color != RIVAL_PINK) begin // Rival car 
            next_color <= rival_color;
        end
        else if (bg_on) begin // Background 
            next_color <= bg_color;
        end
        else // Black border
            next_color <= 0;
    end

    // Register output color on the pixel clock
    always @ (posedge pixel_clock) begin
        output_color <= next_color;
    end

    assign vgaRed = output_color[11:8];
    assign vgaGreen = output_color[7:4];
    assign vgaBlue = output_color[3:0];


endmodule


//=================================================================
//
// Module: fsm_car_state
// Description: FSM (car fsm states and rival car)
//=================================================================
module fsm_car_state(
        input clk,
        input rst,
        input BTNL,
        input BTNR,
        input BTNC,
        input rival_collision, 
        output reg [9:0] car_x,
        output reg [2:0] state
    );

    // State encoding
    localparam START=0;
    localparam IDLE=1;
    localparam COLLIDE=2;
    localparam LEFT_CAR=3;
    localparam RIGHT_CAR=4;

    reg [2:0] current_state, next_state;
    localparam MOVE_STEP = 1;

    reg [24:0] move_counter = 0;
    localparam MOVE_PERIOD = 2000000; // 5 pixels every 20M cycles

    // Combinational block: next state logic
    always @(*) begin

        // Give BTNC (reset) the highest priority. This acts as a global reset
        // that can interrupt any state (e.g., IDLE, LEFT_CAR) and force a
       
        if (BTNC) begin
            next_state = START;
        end
        else begin // Original logic is now nested in this 'else' block
            next_state = current_state; // Default: stay in same state
            case (current_state)
                START: begin
                    next_state = IDLE;
                end

                IDLE: begin
                    if (rival_collision) next_state = COLLIDE; // Part 3 check
                    else if (BTNL) next_state = LEFT_CAR;
                    else if (BTNR) next_state = RIGHT_CAR;
                end

                COLLIDE: begin
                    // If BTNC is not pressed (handled by the global 'if' above),
                    // will remain in the COLLIDE state.
                    next_state = COLLIDE;
                end

                LEFT_CAR: begin
                    if (car_x <= 244) next_state = COLLIDE; // Wall collision
                    else if (rival_collision) next_state = COLLIDE; // Part 3 check
                    else if (!BTNL) next_state = IDLE;
                end

                RIGHT_CAR: begin
                    if (car_x + 14 >= 318) next_state = COLLIDE; // Wall collision
                    else if (rival_collision) next_state = COLLIDE; // Part 3 check
                    else if (!BTNR) next_state = IDLE;
                end

                default: begin
                    next_state = START;
                end
            endcase
        end
    end

    // Sequential block: update state and outputs
    always @(posedge clk) begin
        if (rst) begin // Hard reset (if ever used)
            current_state <= START;
            car_x <= 270;
            move_counter <= 0;
            state <= START;
        end else begin
            current_state <= next_state;
            state <= current_state;

            case (next_state)
                START: begin
                    car_x <= 270;
                    move_counter <= 0;
                end

                IDLE: begin
                    move_counter <= 0;
                end

                COLLIDE: begin
                    move_counter <= 0;
                end

                LEFT_CAR: begin
                    if (current_state != LEFT_CAR) begin
                        move_counter <= 0;
                    end
                    else if (move_counter == MOVE_PERIOD - 1) begin
                        car_x <= car_x - MOVE_STEP;
                        move_counter <= 0;
                    end
                    else begin
                        move_counter <= move_counter + 1;
                    end
                end

                RIGHT_CAR: begin
                    if (current_state != RIGHT_CAR) begin
                        move_counter <= 0;
                    end
                    else if (move_counter == MOVE_PERIOD - 1) begin
                        car_x <= car_x + MOVE_STEP;
                        move_counter <= 0;
                    end
                    else begin
                        move_counter <= move_counter + 1;
                    end
                end

                default: begin
                    move_counter <= 0;
                end
            endcase
        end
    end
endmodule


//=================================================================
//
// Module: debouncer
// Description: Debounces a single button input.
//
//=================================================================
module debouncer(
    input clk,
    input button_in,
    output reg button_out
);

    reg [19:0] counter = 0;
    reg internal_state = 0;
    localparam DEBOUNCE_LIMIT = 1000000; 

    always @(posedge clk) begin
        if (button_in != internal_state) begin
            if (counter >= DEBOUNCE_LIMIT) begin
                internal_state <= button_in;
                button_out <= button_in;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;
        end
    end

endmodule

//=================================================================
//
// Module: lfsr (Part 3)
// Description: 8-bit Pseudo-Random Number Generator based on
//              Feedback: d7 ^ d5 ^ d4 ^ d3
//
//=================================================================
module lfsr(
    input clk,
    input rst, // Use to reset to SEED
    output [7:0] data
    );

    // CALCULATION FOR OUR IDs:
    // ID 1 (0875): 0875_dec = 0b01101011 (8 LSBs)
    // ID 2 (0499): 0499_dec = 0b11110011 (8 LSBs)
    //         XOR: 0b10011000
    //      Result: 8'h98
    parameter SEED = 8'h98;

    reg [7:0] lfsr_reg;

    // Feedback based on Figure 10: d7 ^ d5 ^ d4 ^ d3
    wire feedback;
    assign feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];

    always @(posedge clk)
    begin
        if (rst) begin
            lfsr_reg <= SEED;
        end
        else begin
            // Shift left, new LSB is the feedback bit
            lfsr_reg <= {lfsr_reg[6:0], feedback};
        end
    end

    assign data = lfsr_reg;

endmodule