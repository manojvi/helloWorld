`timescale 1ns / 1ps

module tb;

    // Parameters
    localparam FIFO_DEPTH      = 17;
    localparam DATA_WIDTH      = 8;
    localparam ADDR_WIDTH      = $clog2(FIFO_DEPTH);
    localparam CREDIT_WIDTH    = 5; // Minimum width to hold FIFO_DEPTH

    // Signals
    reg                   push_clk;
    reg                   push_rst;
    reg                   pop_clk;
    reg                   pop_rst;
    reg                   push_sender_in_reset;
    wire                  push_receiver_in_reset;
    reg                   push_credit_stall;
    wire                  push_credit;
    reg                   push_valid;
    reg                   pop_ready;
    wire                  pop_valid;
    wire                  push_full;
    wire                  pop_empty;
    reg  [DATA_WIDTH-1:0]  push_data;
    wire [DATA_WIDTH-1:0]  pop_data;
    wire [CREDIT_WIDTH-1:0] push_slots;
    reg  [CREDIT_WIDTH-1:0] credit_initial_push;
    reg  [CREDIT_WIDTH-1:0] credit_withhold_push;
    wire [CREDIT_WIDTH-1:0] credit_count_push;
    wire [CREDIT_WIDTH-1:0] credit_available_push;
    wire [CREDIT_WIDTH-1:0] pop_items;

    // Internal Testbench Variables
    integer                push_count;
    integer                pop_count;
    integer                expected_push_slots;
    integer                expected_pop_items;
    reg    [DATA_WIDTH-1:0] expected_pop_data;
    integer                test_count;
    integer                error_count;

    // Instantiate the DUT
    cdc_fifo_flops_push_credit #(
        .data_width(DATA_WIDTH),
        .fifo_depth(FIFO_DEPTH)
    ) dut (
        .push_clk              (push_clk),
        .push_rst              (push_rst),
        .pop_clk               (pop_clk),
        .pop_rst               (pop_rst),
        .push_sender_in_reset  (push_sender_in_reset),
        .push_receiver_in_reset (push_receiver_in_reset),
        .push_credit_stall     (push_credit_stall),
        .push_credit           (push_credit),
        .push_valid            (push_valid),
        .pop_ready             (pop_ready),
        .pop_valid             (pop_valid),
        .push_full             (push_full),
        .pop_empty             (pop_empty),
        .push_data             (push_data),
        .pop_data              (pop_data),
        .push_slots            (push_slots),
        .credit_initial_push   (credit_initial_push),
        .credit_withhold_push  (credit_withhold_push),
        .credit_count_push     (credit_count_push),
        .credit_available_push (credit_available_push),
        .pop_items             (pop_items)
    );

    // Clock Generation
    always #5 push_clk = ~push_clk;
    always #7 pop_clk  = ~pop_clk;

    // Helper Function to display in binary format
    function string toBinary;
        input integer value;
        input integer width;
        integer i;
        string binaryString;
        begin
            binaryString = "";
            for (i = width - 1; i >= 0; i = i - 1) begin
                if ((value >> i) & 1) begin
                    binaryString = {binaryString, "1"};
                end else begin
                    binaryString = {binaryString, "0"};
                end
            end
            toBinary = binaryString;
        end
    endfunction

    // Task to perform a push transaction
    task push(input [DATA_WIDTH-1:0] data);
        push_data = data;
        push_valid = 1;
        @(posedge push_clk);
        push_valid = 0;
    endtask

    // Task to perform a pop transaction
    task pop();
        pop_ready = 1;
        @(posedge pop_clk);
        pop_ready = 0;
    endtask

    // Task to reset the FIFO
    task reset_fifo();
        push_rst = 1;
        pop_rst  = 1;
        push_sender_in_reset = 1;
        @(posedge push_clk);
        @(posedge pop_clk);
        push_rst = 0;
        pop_rst  = 0;
        @(posedge push_clk);
        push_sender_in_reset = 0; // End Push Sender Reset
        @(posedge push_clk);
    endtask

    // Task to compare data and report results
    task compare(input [DATA_WIDTH-1:0] expected_data, input integer test_number);
        if (pop_data == expected_data) begin
            $display("PASS: Test %0d: Expected data %0h, Actual data %0h", test_number, expected_data, pop_data);
        end else begin
            $display("FAIL: Test %0d: Expected data %0h, Actual data %0h", test_number, expected_data, pop_data);
            error_count = error_count + 1;
        end
    endtask


    // Initial block (Testbench Code)
    initial begin
        // Initialize signals
        push_clk             = 0;
        pop_clk              = 0;
        push_rst             = 0;
        pop_rst              = 0;
        push_sender_in_reset = 0;
        push_credit_stall    = 0;
        push_valid           = 0;
        pop_ready            = 0;
        push_data            = 0;
        expected_pop_data    = 0; // Initialize expected_pop_data
        push_count           = 0;
        pop_count            = 0;
        expected_push_slots  = FIFO_DEPTH;
        expected_pop_items   = 0;
        test_count           = 0;
        error_count          = 0;
        credit_initial_push  = FIFO_DEPTH;
        credit_withhold_push = 0;

        //Initial checks before reset
        #1;
        test_count = test_count + 1;
        if(push_receiver_in_reset == 0) begin
            $display("FAIL: Test %0d: Expected push_receiver_in_reset to be asserted before reset", test_count);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Test %0d: push_receiver_in_reset asserted before reset", test_count);
        end

        // Reset the FIFO
        reset_fifo();

        #1;
        test_count = test_count + 1;
        if(push_receiver_in_reset == 0) begin
            $display("FAIL: Test %0d: Expected push_receiver_in_reset to be asserted after reset", test_count);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Test %0d: push_receiver_in_reset asserted after reset", test_count);
        end

        // Test 1: Single push and pop
        #1;
        test_count = test_count + 1;
        push(8'h11);
        expected_push_slots = expected_push_slots - 1;
        @(posedge pop_clk);
        expected_pop_data = 8'h11;
        if (pop_valid != 1) begin
            $display("FAIL: Test %0d: Expected pop_valid to be high", test_count);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Test %0d: pop_valid is high after one push", test_count);
        end
        pop();
        expected_push_slots = expected_push_slots + 1;

        #1;
        test_count = test_count + 1;
        compare(expected_pop_data, test_count);

        // Test 2: Fill the FIFO and then empty it
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            push(8'h20 + i);
            @(posedge push_clk);
        end

        // Check if FIFO is full
        test_count = test_count + 1;
        if (push_full != 1) begin
            $display("FAIL: Test %0d: Expected push_full to be high", test_count);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Test %0d: FIFO is full when filled", test_count);
        end


        for (int i = 0; i < FIFO_DEPTH; i++) begin
            @(posedge pop_clk);
            pop();
        end

        // Check if FIFO is empty
        test_count = test_count + 1;
        if (pop_empty != 1) begin
            $display("FAIL: Test %0d: Expected pop_empty to be high", test_count);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Test %0d: FIFO is empty when emptied", test_count);
        end


        // Test 3: push_credit_stall test - stall the credit and make sure push_full doesn't deassert unexpectedly.
        // Fill up the FIFO
        reset_fifo();
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            push(8'h30 + i);
            @(posedge push_clk);
        end

        #1;
        push_credit_stall = 1; // Stall the credits

        // Try to push one more element. Should be blocked.
        test_count = test_count + 1;
        push(8'h3A);
        @(posedge push_clk); // Give it some time.
        if (push_full != 1) begin
            $display("FAIL: Test %0d: Expected push_full to remain high while stalled", test_count);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Test %0d: push_full remains asserted when stalled", test_count);
        end

        push_credit_stall = 0;

        // Test 4: Credit Withholding Test
        reset_fifo();
        credit_initial_push = FIFO_DEPTH;
        credit_withhold_push = 2;

        @(posedge push_clk);
        test_count = test_count + 1;
        if (credit_available_push != (credit_initial_push - credit_withhold_push)) begin
            $display("FAIL: Test %0d: Credit withhold test failed. Expected %0d got %0d", test_count, (credit_initial_push - credit_withhold_push), credit_available_push);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Test %0d: Credit withholding test passed", test_count);
        end

        // Final Result
        if (error_count == 0) begin
            $display("SUCCESS: All test cases passed!");
        end else begin
            $display("ERROR: %0d tests failed.", error_count);
        end

        $finish;
    end

endmodule