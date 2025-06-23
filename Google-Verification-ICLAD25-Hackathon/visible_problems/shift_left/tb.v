module tb;

  // Parameters
  parameter SYMBOL_WIDTH = 12;
  parameter NUM_SYMBOLS  = 8;
  parameter VECTOR_WIDTH = SYMBOL_WIDTH * NUM_SYMBOLS;

  // Inputs
  reg [VECTOR_WIDTH-1:0] in;
  reg [2:0] shift;
  reg [SYMBOL_WIDTH-1:0] fill;

  // Outputs
  wire [VECTOR_WIDTH-1:0] out;
  wire out_valid;

  // Instantiate the DUT
  shift_left dut (
      .in(in),
      .shift(shift),
      .fill(fill),
      .out(out),
      .out_valid(out_valid)
  );

  // Internal variables for testbench
  integer i;
  reg [VECTOR_WIDTH-1:0] expected_out;
  reg expected_out_valid;
  integer test_count;
  integer error_count;


  // Function to calculate expected output
  function automatic [VECTOR_WIDTH-1:0] calculate_expected_out;
    input [VECTOR_WIDTH-1:0] input_vector;
    input [2:0] shift_amount;
    input [SYMBOL_WIDTH-1:0] fill_value;
    integer j;
    reg [VECTOR_WIDTH-1:0] temp_out;
    reg [SYMBOL_WIDTH-1:0] symbol;

    begin
      temp_out = '0;  // Initialize to zero

      for (j = 0; j < NUM_SYMBOLS; j++) begin
        if (j >= shift_amount) begin
          symbol = input_vector[SYMBOL_WIDTH*(NUM_SYMBOLS - 1 - (j - shift_amount)) +: SYMBOL_WIDTH];
          temp_out[SYMBOL_WIDTH*(NUM_SYMBOLS - 1 - j) +: SYMBOL_WIDTH] = symbol;
        end else begin
          temp_out[SYMBOL_WIDTH*(NUM_SYMBOLS - 1 - j) +: SYMBOL_WIDTH] = fill_value;
        end
      end

      calculate_expected_out = temp_out;
    end
  endfunction


  initial begin
    // Initialize signals
    in = 0;
    shift = 0;
    fill = 0;
    test_count = 0;
    error_count = 0;
    expected_out = 0;
    expected_out_valid = 0; // Initialize


    // Test Case 1: shift = 0
    test_count = test_count + 1;
    in = {NUM_SYMBOLS{12'h123}};
    shift = 0;
    fill = 12'h456;
    expected_out = {NUM_SYMBOLS{12'h123}};
    expected_out_valid = 1;
    #1;
    if (out !== expected_out || out_valid !== expected_out_valid) begin
      $display("FAIL: Test Case %0d (shift=0)", test_count);
      $display("  in = %h, shift = %0d, fill = %h", in, shift, fill);
      $display("  out = %h, out_valid = %0d", out, out_valid);
      $display("  Expected out = %h, Expected out_valid = %0d", expected_out, expected_out_valid);
      error_count = error_count + 1;
    end else begin
      $display("PASS: Test Case %0d (shift=0)", test_count);
    end

    // Test Case 2: shift = 1
    test_count = test_count + 1;
    in = {NUM_SYMBOLS{12'h123}};
    shift = 1;
    fill = 12'h456;
    expected_out = calculate_expected_out(in, shift, fill);
    expected_out_valid = 1;
    #1;
    if (out !== expected_out || out_valid !== expected_out_valid) begin
      $display("FAIL: Test Case %0d (shift=1)", test_count);
      $display("  in = %h, shift = %0d, fill = %h", in, shift, fill);
      $display("  out = %h, out_valid = %0d", out, out_valid);
      $display("  Expected out = %h, Expected out_valid = %0d", expected_out, expected_out_valid);
      error_count = error_count + 1;
    end else begin
      $display("PASS: Test Case %0d (shift=1)", test_count);
    end

    // Test Case 3: shift = 5 (max valid shift)
    test_count = test_count + 1;
    in = {NUM_SYMBOLS{12'h123}};
    shift = 5;
    fill = 12'h456;
    expected_out = calculate_expected_out(in, shift, fill);
    expected_out_valid = 1;
    #1;
    if (out !== expected_out || out_valid !== expected_out_valid) begin
      $display("FAIL: Test Case %0d (shift=5)", test_count);
      $display("  in = %h, shift = %0d, fill = %h", in, shift, fill);
      $display("  out = %h, out_valid = %0d", out, out_valid);
      $display("  Expected out = %h, Expected out_valid = %0d", expected_out, expected_out_valid);
      error_count = error_count + 1;
    end else begin
      $display("PASS: Test Case %0d (shift=5)", test_count);
    end

    // Test Case 4: shift = 6 (invalid shift)
    test_count = test_count + 1;
    in = {NUM_SYMBOLS{12'h123}};
    shift = 6;
    fill = 12'h456;
    expected_out_valid = 0;
    #1;
    if (out_valid !== expected_out_valid) begin
      $display("FAIL: Test Case %0d (shift=6 - invalid)", test_count);
      $display("  in = %h, shift = %0d, fill = %h", in, shift, fill);
      $display("  out = %h, out_valid = %0d", out, out_valid);
      $display("  Expected out_valid = %0d", expected_out_valid);
      error_count = error_count + 1;
    end else begin
      $display("PASS: Test Case %0d (shift=6 - invalid)", test_count);
    end

    // Test Case 5: shift = 7 (invalid shift)
    test_count = test_count + 1;
    in = {NUM_SYMBOLS{12'h123}};
    shift = 7;
    fill = 12'h456;
    expected_out_valid = 0;
    #1;
    if (out_valid !== expected_out_valid) begin
      $display("FAIL: Test Case %0d (shift=7 - invalid)", test_count);
      $display("  in = %h, shift = %0d, fill = %h", in, shift, fill);
      $display("  out = %h, out_valid = %0d", out, out_valid);
      $display("  Expected out_valid = %0d", expected_out_valid);
      error_count = error_count + 1;
    end else begin
      $display("PASS: Test Case %0d (shift=7 - invalid)", test_count);
    end

    // Test Case 6: Different input values and fill
    test_count = test_count + 1;
    in = {8{12'hABC}};
    shift = 3;
    fill = 12'hDEF;
    expected_out = calculate_expected_out(in, shift, fill);
    expected_out_valid = 1;
    #1;
    if (out !== expected_out || out_valid !== expected_out_valid) begin
      $display("FAIL: Test Case %0d (different values)", test_count);
      $display("  in = %h, shift = %0d, fill = %h", in, shift, fill);
      $display("  out = %h, out_valid = %0d", out, out_valid);
      $display("  Expected out = %h, Expected out_valid = %0d", expected_out, expected_out_valid);
      error_count = error_count + 1;
    end else begin
      $display("PASS: Test Case %0d (different values)", test_count);
    end

    // Test Case 7: Edge case - shift = 2, MSB of in set
    test_count = test_count + 1;
    in = {NUM_SYMBOLS{12'h800}};
    shift = 2;
    fill = 12'h000;
    expected_out = calculate_expected_out(in, shift, fill);
    expected_out_valid = 1;
    #1;
    if (out !== expected_out || out_valid !== expected_out_valid) begin
      $display("FAIL: Test Case %0d (MSB set)", test_count);
      $display("  in = %h, shift = %0d, fill = %h", in, shift, fill);
      $display("  out = %h, out_valid = %0d", out, out_valid);
      $display("  Expected out = %h, Expected out_valid = %0d", expected_out, expected_out_valid);
      error_count = error_count + 1;
    end else begin
      $display("PASS: Test Case %0d (MSB set)", test_count);
    end


    // Final result
    if (error_count == 0) begin
      $display("SUCCESS: All test cases passed!");
    end else begin
      $display("ERROR: %0d test cases failed.", error_count);
    end

    $finish;
  end

endmodule