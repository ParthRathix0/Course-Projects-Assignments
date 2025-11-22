`timescale 1ns / 1ps

module linked_list_tb;

    // Clock and input signals
    reg clk;
    reg [15:0] sw;
    reg btnC;

    // Outputs
    wire [1:0] led;
    wire [6:0] seg;
    wire [3:0] an;

    // Instantiate the top-level design
    linked_list_top uut (
        .clk(clk),
        .sw(sw),
        .btnC(btnC),
        .led(led),
        .seg(seg),
        .an(an)
    );

    // Clock generation: 10ns period -> 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task to simulate a button press (reset pulse)
    task press_reset;
    begin
        btnC = 1;
        #20;         // hold reset for some time
        btnC = 0;
    end
    endtask

    // Task to perform an operation with switches
    task perform_op(input [2:0] opcode, input [7:0] data);
    begin
        sw[15:13] = opcode; // opcode bits
        sw[12:8]  = 0;      // unused
        sw[7:0]   = data;   // data bits
        #100;                // hold for 100ns
        sw[15:13] = 3'b000;  // return to idle
        #100;
    end
    endtask

    // Main stimulus
    initial begin
        $display("Starting Linked List Simulation...");

        // Initialize signals
        btnC = 0;
        sw = 0;

        // Apply global reset
        press_reset();
        #200;

        // ========== TEST 1: Insert at HEAD ==========
        $display("Inserting at HEAD...");
        perform_op(3'b100, 8'h11); // Insert data = 0x11 at head
        #100;
        perform_op(3'b100, 8'h22); // Insert data = 0x22 at head
        #100;

        // ========== TEST 2: Insert at TAIL ==========
        $display("Inserting at TAIL...");
        perform_op(3'b101, 8'h33); // Insert data = 0x33 at tail
        #100;
        perform_op(3'b101, 8'h44); // Insert data = 0x44 at tail
        #100;

        // ========== TEST 3: Delete a node ==========
        $display("Deleting a node (0x22)...");
        perform_op(3'b110, 8'h22); // Delete node with data = 0x22
        #100;

        // ========== TEST 4: Traverse linked list ==========
        $display("Traversing linked list...");
        perform_op(3'b111, 8'h00); // Traverse operation (data ignored)
        #5000;

        // End simulation
        $display("Simulation complete.");
        #1000;
        $stop;
    end

endmodule