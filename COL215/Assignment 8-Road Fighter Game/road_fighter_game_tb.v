`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Module: Display_sprite_tb
// Description: Testbench for the complete Road Fighter game (Parts 3).
//
//
//              It tests:
//              1. Main car movement (L/R)
//              2. Wall collision (L/R)
//              3. Reset functionality (BTNC)
//              4. Rival car random spawning (using a fixed seed)
//              5. Rival car vertical movement (timed by VGA frames)
//              6. Rival-vs-Main car collision
//
//////////////////////////////////////////////////////////////////////////////////

module Display_sprite_tb;

    // Inputs to UUT
    reg clk;
    reg BTNC;
    reg BTNR;
    reg BTNL;

    // Outputs from UUT
    wire HS;
    wire VS;
    wire [11:0] vgaRGB;

    // Instantiate the Unit Under Test (UUT)
    Display_sprite uut (
        .clk(clk),
        .BTNC(BTNC),
        .BTNR(BTNR),
        .BTNL(BTNL),
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB)
    );



    defparam uut.lfsr_inst.SEED = 8'h48;




    //=================================================================
    // INTERNAL SIGNAL MONITORING
    // We monitor internal signals to verify FSM state and positions.
    //=================================================================
    wire [9:0] car_x_monitor = uut.car_x;
    wire [2:0] car_state_monitor = uut.car_fsm_state;
    wire [9:0] rival_x_monitor = uut.rival_x_reg;
    wire [9:0] rival_y_monitor = uut.rival_y_reg;
    wire rival_collision_monitor = uut.main_vs_rival_collision;


    // Clock generation (100MHz, 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task to pulse the center button (Reset)
    task pulse_btnC;
    begin
        BTNC = 1;
        #20; // Hold for 2 clock cycles
        BTNC = 0;
    end
    endtask

    // Main stimulus
    initial begin
        // Monitor signals to track FSM state and car position
        $monitor("Time: %0t ns | BTNL:%b BTNR:%b BTNC:%b | FSM State: %d | car_x: %d | rival_x: %d | rival_y: %d | rival_coll: %b",
                 $time, BTNL, BTNR, BTNC, car_state_monitor, car_x_monitor, rival_x_monitor, rival_y_monitor, rival_collision_monitor);

        // 1. Initialize all inputs
        $display("--- Starting Testbench (with overridden parameters) ---");
        BTNC = 0;
        BTNR = 0;
        BTNL = 0;
        #10;

        // --- Initial Reset Pulse ---
        $display("--- Applying initial reset pulse (BTNC) ---");
        BTNC=1;



        #110; // Wait for debounce and FSM to transition START -> IDLE
        BTNC=0;

        $display("--- Initial state set. FSM is IDLE, car_x = 270. ---");
        #100;

        // --- TEST 1: Move LEFT (Part 2 Test) ---
        $display("--- Test 1: Pressing BTNL (Move Left) ---");
        BTNL = 1;
        #110; // Wait for debounce. State -> LEFT_CAR (3)
        #210; // Wait for one move. car_x -> 270 - 5 = 265
        #210; // Wait for second move. car_x -> 265 - 5 = 260
        BTNL = 0;
        #110; // Wait for debounce. State -> IDLE (1)
        #1000;

        // --- TEST 2: Move RIGHT (Part 2 Test) ---
        $display("--- Test 2: Pressing BTNR (Move Right) ---");
        BTNR = 1;
        #110; // Wait for debounce. State -> RIGHT_CAR (4)
        #210; // Wait for one move. car_x -> 260 + 5 = 265
        #210; // Wait for second move. car_x -> 265 + 5 = 270
        BTNR = 0;
        #110; // Wait for debounce. State -> IDLE (1)
        #1000;

        // --- TEST 3: LEFT Wall Collision (Part 2 Test) ---
        $display("--- Test 3: Holding BTNL to trigger LEFT collision (at x <= 244) ---");
        BTNL = 1;
        #110; // Wait for debounce. State -> LEFT_CAR (3)
        // car_x = 270. Moves: 265, 260, 255, 250, 245
        $display("...moving left 5 times...");
        repeat (5) #210;
        $display("Current car_x = %d. Next move (to 240) should collide.", car_x_monitor);
        #210; // car_x becomes 240. FSM should see car_x <= 244 and go to COLLIDE (2)
        #210; // Wait another move period. car_x should NOT change.
        BTNL = 0;
        #1000; // Wait. State should remain COLLIDE (2).

        // --- TEST 4: Reset from Wall Collision (Part 2 Test) ---
        $display("--- Test 4: Pressing BTNC to Reset from wall collision ---");
        BTNC=1;
        #110; // Wait for debounce
        BTNC=0;
        $display("--- Test 4: Reset complete. car_x should be 270. ---");
        #1000;

        // --- TEST 5: RIGHT Wall Collision (Part 2 Test) ---
        $display("--- Test 5: Holding BTNR to trigger RIGHT collision (at x >= 304) ---");
        BTNR = 1;
        #110; // Wait for debounce. State -> RIGHT_CAR (4)
        // car_x = 270. Moves: 275, 280, 285, 290, 295, 300
        $display("...moving right 6 times...");
        repeat (6) #210;
        $display("Current car_x = %d. Next move (to 305) should collide.", car_x_monitor);
        #210; // car_x becomes 305. FSM should see 305+14 >= 318 and go to COLLIDE (2)
        #210; // Wait another move period. car_x should NOT change.
        BTNR = 0;
        #1000; // Wait. State should remain COLLIDE (2).

        // --- TEST 6: Rival Spawning, Movement, and Collision (Part 3 Test) ---
        $display("--- Test 6: Resetting game to test rival car ---");
        BTNC=1; // Reset game
        #110; // Wait for debounce and FSM to go IDLE
        BTNC=0;
        $display("...Game reset. FSM is IDLE, main car_x=270.");


        $display("...Checking rival spawn: y=%d, x=%d", rival_y_monitor, rival_x_monitor);
        if (rival_y_monitor != 150) $display("!!! TEST 6 FAILED: Rival Y spawn != 150 !!!");
        if (rival_x_monitor != 282) $display("!!! TEST 6 FAILED: Rival X spawn != 282 (check seed/LFSR logic) !!!");

        // Wait for rival to move (proves VS/frame_counter logic)
        $display("...Waiting for rival to move 50 pixels down...");
        wait (rival_y_monitor >= 200); // Wait until rival_y has clearly moved
        $display("...Rival Y has moved (y=%d). Frame counter logic is working.", rival_y_monitor);


        $display("...Waiting for rival collision...");
        wait (rival_collision_monitor == 1);
        #50; // Give time for FSM to see collision and update
        $display("!!! --- Test 6: Rival Collision Detected! --- !!!");
        if (car_state_monitor != 2) $display("!!! TEST 6 FAILED: FSM did not go to COLLIDE (2) state !!!");

        #1000; // Wait in COLLIDE state

        // --- TEST 7: Reset and Respawn (Part 3 Test) ---
        $display("--- Test 7: Resetting from rival collision. ---");
        pulse_btnC();
        #110; // Wait for debounce and reset
        $display("...Game reset. Checking if rival respawned correctly.");
        if (rival_y_monitor != 150) $display("!!! TEST 7 FAILED: Rival Y respawn != 150 !!!");
        if (rival_x_monitor != 282) $display("!!! TEST 7 FAILED: Rival X respawn != 282 (LFSR reset failed) !!!");
        $display("...Rival respawned at y=150, x=282 as expected.");

        $display("--- All Tests Finished ---");
        $stop;
    end

endmodule
