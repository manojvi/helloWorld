`timescale 1ns/1ps

module tb;

  // Parameters
  localparam DATA_WIDTH = 8;

  // Inputs
  reg clk;
  reg rst;
  reg push_sender_in_reset;
  reg push_credit_stall;
  reg push_valid;
  reg pop_credit;
  reg credit_initial;
  reg credit_withhold;
  reg [DATA_WIDTH-1:0] push_data;

  // Outputs
  wire push_credit;
  wire pop_valid;
  wire [DATA_WIDTH-1:0] pop_data;
  wire push_receiver_in_reset;
  wire credit_count;
  wire credit_available;

  // Instantiate the DUT
  credit_receiver dut (
    .clk(clk),
    .rst(rst),
    .push_sender_in_reset(push_sender_in_reset),
    .push_credit_stall(push_credit_stall),
    .push_valid(push_valid),
    .pop_credit(pop_credit),
    .credit_initial(credit_initial),
    .credit_withhold(credit_withhold),
    .push_data(push_data),
    .pop_data(pop_data),
    .push_receiver_in_reset(push_receiver_in_reset),
    .push_credit(push_credit),
    .credit_count(credit_count),
    .credit_available(credit_available),
    .pop_valid(pop_valid)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Testbench signals
  reg [DATA_WIDTH-1:0] expected_pop_data;
  reg expected_pop_valid;
  reg expected_push_credit;
  reg expected_credit_count;
  reg expected_credit_available;
  reg expected_push_receiver_in_reset;

  // Error counter
  integer errors;

  // Function to compare expected and actual values
  task compare;
    input string test_name;
    input [DATA_WIDTH-1:0] expected_data;
    input [DATA_WIDTH-1:0] actual_data;
    input bit expected_valid;
    input bit actual_valid;
    input bit expected_credit;
    input bit actual_credit;
    input bit expected_count;
    input bit actual_count;
    input bit expected_avail;
    input bit actual_avail;
    input bit expected_reset;
    input bit actual_reset;
    begin
      if (expected_data !== actual_data ||
          expected_valid !== actual_valid ||
          expected_credit !== actual_credit ||
          expected_count !== actual_count ||
          expected_avail !== actual_avail ||
          expected_reset !== actual_reset
         )
      begin
        $display("FAIL: Test %s failed!", test_name);
        $display("  Expected: pop_data=%h, pop_valid=%b, push_credit=%b, credit_count=%b, credit_available=%b, push_receiver_in_reset=%b",
                 expected_data, expected_valid, expected_credit, expected_count, expected_avail, expected_reset);
        $display("  Actual:   pop_data=%h, pop_valid=%b, push_credit=%b, credit_count=%b, credit_available=%b, push_receiver_in_reset=%b",
                 actual_data, actual_valid, actual_credit, actual_count, actual_avail, actual_reset);
        errors = errors + 1;
      end
      else
      begin
        $display("PASS: Test %s passed.", test_name);
      end
    end
  endtask

  initial begin
    // Initialize signals
    clk = 0;
    rst = 0;
    push_sender_in_reset = 0;
    push_credit_stall = 0;
    push_valid = 0;
    pop_credit = 0;
    credit_initial = 0;
    credit_withhold = 0;
    push_data = 0;

    errors = 0;

    // Reset sequence
    rst = 1;
    #10;
    rst = 0;
    #10;

    // Test cases

    // Test 1: Basic data transfer with initial credit.
    credit_initial = 1;
    push_valid = 1;
    push_data = 8'h55;
    #10;
    expected_pop_data = 8'h55;
    expected_pop_valid = 1;
    expected_push_credit = 1;
    expected_credit_count = 1;
    expected_credit_available = 1;
    expected_push_receiver_in_reset = 0;
    compare("1", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);

    // Test 2: Pop credit received, credit count goes to 0
    pop_credit = 1;
    #10;
    expected_pop_data = 8'h55; //Data remains the same from push_data
    expected_pop_valid = 1;
    expected_push_credit = 0;
    expected_credit_count = 0;
    expected_credit_available = 0;
    expected_push_receiver_in_reset = 0;
    compare("2", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);
    pop_credit = 0;

    // Test 3: No credit, no data transfer
    push_data = 8'hAA;
    push_valid = 1;
    #10;
    expected_pop_data = 8'hAA;
    expected_pop_valid = 0;
    expected_push_credit = 0;
    expected_credit_count = 0;
    expected_credit_available = 0;
    expected_push_receiver_in_reset = 0;
    compare("3", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);
    push_valid = 0;

    // Test 4: Reset during data transfer
    rst = 1;
    #10;
    expected_pop_data = 8'hAA;
    expected_pop_valid = 0;
    expected_push_credit = 0;
    expected_credit_count = 1; // Credit count resets to initial value!
    expected_credit_available = 1;
    expected_push_receiver_in_reset = 1;
    compare("4", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);
    rst = 0;
    credit_initial = 1;
    #10;

    // Test 5: push_sender_in_reset during data transfer
    push_valid = 1;
    push_data = 8'hBB;
    push_sender_in_reset = 1;
    #10;
    expected_pop_data = 8'hBB;
    expected_pop_valid = 0;
    expected_push_credit = 0;
    expected_credit_count = 1; //Credit_count remains old value
    expected_credit_available = 1;
    expected_push_receiver_in_reset = 0;
    compare("5", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);
    push_sender_in_reset = 0;
    push_valid = 0;
    #10;

    // Test 6: Credit Withhold
    credit_withhold = 1;
    push_valid = 0;
    #10;
    expected_pop_data = 8'hBB;
    expected_pop_valid = 0;
    expected_push_credit = 0;
    expected_credit_count = 1;
    expected_credit_available = 0;
    expected_push_receiver_in_reset = 0;
    compare("6", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);

    // Test 7: push_credit_stall
    credit_withhold = 0;
    push_credit_stall = 1;
    push_valid = 1;
    push_data = 8'hCC;
    #10;
    expected_pop_data = 8'hCC;
    expected_pop_valid = 1;
    expected_push_credit = 0;
    expected_credit_count = 1;
    expected_credit_available = 1;
    expected_push_receiver_in_reset = 0;
    compare("7", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);
    push_credit_stall = 0;
    push_valid = 0;
    #10;

    // Test 8: Credit initial 0, no transfer possible
    credit_initial = 0;
    rst = 1;
    #10;
    rst = 0;
    push_valid = 1;
    push_data = 8'hDD;
    #10;
    expected_pop_data = 8'hDD;
    expected_pop_valid = 0;
    expected_push_credit = 0;
    expected_credit_count = 0;
    expected_credit_available = 0;
    expected_push_receiver_in_reset = 0;
    compare("8", expected_pop_data, pop_data, expected_pop_valid, pop_valid, expected_push_credit, push_credit, expected_credit_count, credit_count, expected_credit_available, credit_available, expected_push_receiver_in_reset, push_receiver_in_reset);

    // Final check and message
    if (errors == 0) begin
      $display("SUCCESS: All test cases passed!");
    end else begin
      $display("ERROR: %d tests failed.", errors);
    end

    $finish;
  end

endmodule

module credit_receiver (
  input clk,
  input rst,
  input push_sender_in_reset,
  input push_credit_stall,
  input push_valid,
  input pop_credit,
  input credit_initial,
  input credit_withhold,
  input [7:0] push_data,
  output pop_valid,
  output [7:0] pop_data,
  output push_receiver_in_reset,
  output push_credit,
  output credit_count,
  output credit_available
);

  reg credit_count_reg;

  assign push_receiver_in_reset = rst;
  assign pop_data = push_data;
  assign pop_valid = push_valid & ~(rst | push_sender_in_reset);
  assign credit_available = credit_count_reg & ~credit_withhold;
  assign credit_count = credit_count_reg;
  assign push_credit = ~((rst | push_sender_in_reset) | push_credit_stall) & credit_available;

  always @(posedge clk) begin
    if (rst | push_sender_in_reset) begin
      credit_count_reg <= credit_initial;
    end else if (pop_credit) begin
      credit_count_reg <= 0;
    end else if (push_credit) begin
      credit_count_reg <= 1;
    end
  end

endmodule