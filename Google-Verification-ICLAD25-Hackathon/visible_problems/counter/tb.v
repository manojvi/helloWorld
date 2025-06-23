module tb;

  reg clk;
  reg rst;
  reg reinit;
  reg incr_valid;
  reg decr_valid;
  reg [3:0] initial_value;
  reg [1:0] incr;
  reg [1:0] decr;
  wire [3:0] value;
  wire [3:0] value_next;

  // Instantiate the counter module
  counter dut (
    .clk(clk),
    .rst(rst),
    .reinit(reinit),
    .incr_valid(incr_valid),
    .decr_valid(decr_valid),
    .initial_value(initial_value),
    .incr(incr),
    .decr(decr),
    .value(value),
    .value_next(value_next)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Testbench code
  initial begin
    clk = 0;
    rst = 0;
    reinit = 0;
    incr_valid = 0;
    decr_valid = 0;
    initial_value = 0;
    incr = 0;
    decr = 0;

    // Reset sequence
    rst = 1;
    #10;
    rst = 0;
    #10;

    // Test Case 1: Initialization
    initial_value = 5;
    reinit = 1;
    #10;
    reinit = 0;
    #10;
    if (value == 5) begin
      $display("PASS: Test Case 1 (Initialization) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 1 (Initialization) - Expected 5, got %d", value);
    end

    // Test Case 2: Increment
    incr_valid = 1;
    incr = 1;
    #10;
    incr_valid = 0;
    reg [3:0] expected_value;
    expected_value = 6;
    if (value == expected_value) begin
      $display("PASS: Test Case 2 (Increment by 1) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 2 (Increment by 1) - Expected %d, got %d", expected_value, value);
    end

    // Test Case 3: Decrement
    decr_valid = 1;
    decr = 1;
    #10;
    decr_valid = 0;
    expected_value = 5;
    if (value == expected_value) begin
      $display("PASS: Test Case 3 (Decrement by 1) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 3 (Decrement by 1) - Expected %d, got %d", expected_value, value);
    end

    // Test Case 4: Increment and Decrement Simultaneously (net 0 change)
    incr_valid = 1;
    decr_valid = 1;
    incr = 2;
    decr = 2;
    #10;
    incr_valid = 0;
    decr_valid = 0;
    expected_value = 5;
    if (value == expected_value) begin
      $display("PASS: Test Case 4 (Increment and Decrement) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 4 (Increment and Decrement) - Expected %d, got %d", expected_value, value);
    end

    // Test Case 5: Overflow
    initial_value = 9;
    reinit = 1;
    #10;
    reinit = 0;
    incr_valid = 1;
    incr = 3;
    #10; // Value should reach 12, then wrap to 2
    incr_valid = 0;
    expected_value = 2;
    if (value == expected_value) begin
      $display("PASS: Test Case 5 (Overflow) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 5 (Overflow) - Expected %d, got %d", value);
    end

    // Test Case 6: Underflow
    initial_value = 1;
    reinit = 1;
    #10;
    reinit = 0;
    decr_valid = 1;
    decr = 3;
    #10; // Value should wrap to 9
    decr_valid = 0;
    expected_value = 9;
    if (value == expected_value) begin
      $display("PASS: Test Case 6 (Underflow) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 6 (Underflow) - Expected %d, got %d", value);
    end

    // Test Case 7: No change
    incr_valid = 0;
    decr_valid = 0;
    #10;
    expected_value = 9;
    if (value == expected_value) begin
      $display("PASS: Test Case 7 (No Change) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 7 (No Change) - Expected %d, got %d", value);
    end

    // Test Case 8: Max Increment
    initial_value = 9;
    reinit = 1;
    #10;
    reinit = 0;
    incr_valid = 1;
    incr = 3;
    #10;
    incr_valid = 0;
    expected_value = 2;

   if (value == expected_value) begin
      $display("PASS: Test Case 8 (Max Increment Wrap) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 8 (Max Increment Wrap) - Expected %d, got %d", value);
    end

     // Test Case 9: Max Decrement
    initial_value = 1;
    reinit = 1;
    #10;
    reinit = 0;
    decr_valid = 1;
    decr = 3;
    #10;
    decr_valid = 0;
    expected_value = 9;

    if (value == expected_value) begin
          $display("PASS: Test Case 9 (Max Decrement Wrap) - value = %d", value);
        } else begin
          $display("FAIL: Test Case 9 (Max Decrement Wrap) - Expected %d, got %d", value);
    end

    // Test Case 10: Reinit overrides incr/decr
    initial_value = 2;
    reinit = 1;
    incr_valid = 1;
    incr = 1;
    decr_valid = 1;
    decr = 1;
    #10;
    reinit = 0;
    incr_valid = 0;
    decr_valid = 0;
    expected_value = 2;
    if (value == expected_value) begin
      $display("PASS: Test Case 10 (Reinit Override) - value = %d", value);
    } else begin
      $display("FAIL: Test Case 10 (Reinit Override) - Expected %d, got %d", value);
    end

    $display("SUCCESS: All test cases passed!");
    $finish;
  end

endmodule