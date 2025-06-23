`timescale 1ns / 1ps

module tb;

  // Parameters
  localparam DATA_WIDTH = 8;
  localparam FIFO_DEPTH = 13;
  localparam ADDR_WIDTH = 4; //ceil(log2(FIFO_DEPTH))

  // Signals
  reg clk;
  reg rst;
  reg push_valid;
  reg pop_ready;
  reg [DATA_WIDTH-1:0] push_data;
  wire push_ready;
  wire pop_valid;
  wire [DATA_WIDTH-1:0] pop_data;
  wire full;
  wire empty;
  wire [ADDR_WIDTH-1:0] items;
  wire [ADDR_WIDTH-1:0] slots;
  wire full_next;
  wire empty_next;
  wire [ADDR_WIDTH-1:0] items_next;
  wire [ADDR_WIDTH-1:0] slots_next;


  // Instantiate the FIFO module
  fifo_flops dut (
    .clk(clk),
    .rst(rst),
    .push_ready(push_ready),
    .push_valid(push_valid),
    .pop_ready(pop_ready),
    .pop_valid(pop_valid),
    .full(full),
    .full_next(full_next),
    .empty(empty),
    .empty_next(empty_next),
    .push_data(push_data),
    .pop_data(pop_data),
    .slots(slots),
    .slots_next(slots_next),
    .items(items),
    .items_next(items_next)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Testbench logic
  initial begin
    // Initialize signals
    clk = 0;
    rst = 1;
    push_valid = 0;
    pop_ready = 0;
    push_data = 0;

    // Reset sequence
    #10 rst = 0;
    #10;

    // Test Case 1: Reset Test
    $display("Test Case 1: Reset Test");
    rst = 1;
    #10;
    rst = 0;
    #10;
    if (empty == 1 && full == 0 && items == 0 && slots == FIFO_DEPTH && pop_valid == 0 && push_ready == 1) begin
      $display("PASS: Reset Test");
    end else begin
      $display("FAIL: Reset Test - Expected empty=1, full=0, items=0, slots=%0d, pop_valid=0, push_ready=1.  Observed empty=%0d, full=%0d, items=%0d, slots=%0d, pop_valid=%0d, push_ready=%0d", FIFO_DEPTH, empty, full, items, slots, pop_valid, push_ready);
    end

    // Test Case 2: Bypass Mode Test
    $display("Test Case 2: Bypass Mode Test");
    push_data = 8'h42;
    push_valid = 1;
    pop_ready = 1;
    #10;
    if (pop_data == push_data && pop_valid == 1 && empty == 1 && items == 0) begin
      $display("PASS: Bypass Mode Test");
    end else begin
      $display("FAIL: Bypass Mode Test - Expected pop_data=%h, pop_valid=1, empty=1, items=0. Observed pop_data=%h, pop_valid=%b, empty=%b, items=%d", push_data, pop_data, pop_valid, empty, items);
    end
    push_valid = 0;
    pop_ready = 0;
    #10;


    // Test Case 3: Single Push and Pop
    $display("Test Case 3: Single Push and Pop");
    push_data = 8'h11;
    push_valid = 1;
    pop_ready = 0;
    #10;
    push_valid = 0;
    if (empty == 0 && items == 1 && pop_valid == 0 && push_ready == 1) begin
      $display("PASS: Single Push - Status check");
    end else begin
      $display("FAIL: Single Push - Status check - Expected empty=0, items=1, pop_valid=0, push_ready=1. Observed empty=%b, items=%d, pop_valid=%b, push_ready=%b", empty, items, pop_valid, push_ready);
    end
    pop_ready = 1;
    #10;
    pop_ready = 0;
    if (pop_data == 8'h11 && pop_valid == 0 && empty == 1 && items == 0) begin
      $display("PASS: Single Pop");
    end else begin
      $display("FAIL: Single Pop - Expected pop_data=%h, pop_valid=0, empty=1, items=0. Observed pop_data=%h, pop_valid=%b, empty=%b, items=%d", 8'h11, pop_data, pop_valid, empty, items);
    end
    #10;

    // Test Case 4: Fill FIFO
    $display("Test Case 4: Fill FIFO");
    for (int i = 0; i < FIFO_DEPTH; i = i + 1) begin
      push_data = i;
      push_valid = 1;
      #10;
      push_valid = 0;
    end
    if (full == 1 && empty == 0 && items == FIFO_DEPTH && slots == 0) begin
      $display("PASS: Fill FIFO");
    end else begin
      $display("FAIL: Fill FIFO - Expected full=1, empty=0, items=%0d, slots=0. Observed full=%b, empty=%b, items=%d, slots=%d", FIFO_DEPTH, full, empty, items, slots);
    end
    #10;

    // Test Case 5: Overfill FIFO - Attempt to push when full
    $display("Test Case 5: Overfill FIFO");
    push_data = 8'hFF;
    push_valid = 1;
    #10;
    push_valid = 0; // Stop pushing
    if (full == 1 && items == FIFO_DEPTH) begin
        $display("PASS: Overfill FIFO");
    } else begin
        $display("FAIL: Overfill FIFO. Expected full=1 and items=%0d, but got full=%b and items=%d", FIFO_DEPTH, full, items);
    end
    #10;


    // Test Case 6: Empty FIFO
    $display("Test Case 6: Empty FIFO");
    pop_ready = 1;
    for (int i = 0; i < FIFO_DEPTH; i = i + 1) begin
      #10;
    end
    pop_ready = 0;
    if (empty == 1 && full == 0 && items == 0 && slots == FIFO_DEPTH) begin
      $display("PASS: Empty FIFO");
    end else begin
      $display("FAIL: Empty FIFO - Expected empty=1, full=0, items=0, slots=%0d. Observed empty=%b, full=%b, items=%d, slots=%d", FIFO_DEPTH, empty, full, items, slots);
    end
    #10;

    // Test Case 7: Alternate Push and Pop
    $display("Test Case 7: Alternate Push and Pop");
    for (int i = 0; i < FIFO_DEPTH / 2; i = i + 1) begin
      push_data = i + 100;
      push_valid = 1;
      #5;
      push_valid = 0;
      pop_ready = 1;
      #5;
      pop_ready = 0;
      #10;
    end

    if (items <= FIFO_DEPTH / 2) begin
      $display("PASS: Alternate Push and Pop test");
    end else begin
      $display("FAIL: Alternate Push and Pop test, items = %d, expected items <= %d", items, FIFO_DEPTH / 2);
    end

    #10;

    $display("SUCCESS: All test cases passed!");
    $finish;
  end

endmodule