module tb;

  // Parameters
  parameter SYMBOL_WIDTH = 5;
  parameter NUM_SYMBOLS  = 10;

  // Signals
  reg [SYMBOL_WIDTH*NUM_SYMBOLS-1:0] in;
  reg [2:0] shift;
  reg [SYMBOL_WIDTH-1:0] fill;
  wire out_valid;
  wire [SYMBOL_WIDTH*NUM_SYMBOLS-1:0] out;

  // Instantiate the DUT
  shift_right dut (
    .in(in),
    .shift(shift),
    .fill(fill),
    .out_valid(out_valid),
    .out(out)
  );


  // Helper function for array access
  function [SYMBOL_WIDTH-1:0] get_symbol;
    input integer index;
    input [SYMBOL_WIDTH*NUM_SYMBOLS-1:0] array;
    integer msb;
    integer lsb;
    begin
      msb = SYMBOL_WIDTH*(index+1)-1;
      lsb = SYMBOL_WIDTH*index;
      get_symbol = array[msb:lsb];
    end
  endfunction

  function [SYMBOL_WIDTH*NUM_SYMBOLS-1:0] set_symbol;
    input integer index;
    input [SYMBOL_WIDTH-1:0] value;
    input [SYMBOL_WIDTH*NUM_SYMBOLS-1:0] array;
    integer msb;
    integer lsb;
    reg [SYMBOL_WIDTH*NUM_SYMBOLS-1:0] temp_array;
    begin
      temp_array = array;
      msb = SYMBOL_WIDTH*(index+1)-1;
      lsb = SYMBOL_WIDTH*index;
      for (integer i = lsb; i <= msb; i++) begin
        temp_array[i] = value[i-lsb];
      end
      set_symbol = temp_array;
    end
  endfunction

  // Testbench Logic
  initial begin
    integer i;
    integer test_count = 0;
    integer error_count = 0;
    reg [SYMBOL_WIDTH*NUM_SYMBOLS-1:0] expected_out;
    reg expected_out_valid;

    // Initialize signals
    in = 0;
    shift = 0;
    fill = 0;
    expected_out = 0; // Initialize expected_out
    expected_out_valid = 0;


    // Test Case 1: Shift = 0, Fill = 0
    $display("Test Case %0d: Shift = 0, Fill = 0", test_count++);
    in = {10{5'h1}};
    shift = 0;
    fill = 5'h0;
    expected_out = {10{5'h1}};
    expected_out_valid = 1;

    #1;
    if (out === expected_out && out_valid === expected_out_valid) begin
      $display("  PASS");
    end else begin
      $display("  FAIL: out=%h, expected=%h, out_valid=%b, expected_valid=%b", out, expected_out, out_valid, expected_out_valid);
      error_count++;
    end



    // Test Case 2: Shift = 1, Fill = 1
    $display("Test Case %0d: Shift = 1, Fill = 1", test_count++);
    in = {10{5'h2}};
    shift = 1;
    fill = 5'h1;

    expected_out = 0;
    expected_out_valid = 1;

    for (i = 0; i < NUM_SYMBOLS; i++) begin
      if (i == 0) begin
        expected_out = set_symbol(i, fill, expected_out);
      end else begin
        expected_out = set_symbol(i, get_symbol(i-1,in), expected_out);
      end
    end

    #1;
    if (out === expected_out && out_valid === expected_out_valid) begin
      $display("  PASS");
    end else begin
      $display("  FAIL: out=%h, expected=%h, out_valid=%b, expected_valid=%b", out, expected_out, out_valid, expected_out_valid);
      error_count++;
    end

    // Test Case 3: Shift = 4, Fill = 5'hF
    $display("Test Case %0d: Shift = 4, Fill = F", test_count++);
    in = {10{5'h3}};
    shift = 4;
    fill = 5'hF;

    expected_out = 0;
    expected_out_valid = 1;
     for (i = 0; i < NUM_SYMBOLS; i++) begin
      if (i < shift) begin
        expected_out = set_symbol(i, fill, expected_out);
      end else begin
        expected_out = set_symbol(i, get_symbol(i-shift,in), expected_out);
      end
    end

    #1;
    if (out === expected_out && out_valid === expected_out_valid) begin
      $display("  PASS");
    end else begin
      $display("  FAIL: out=%h, expected=%h, out_valid=%b, expected_valid=%b", out, expected_out, out_valid, expected_out_valid);
      error_count++;
    end

    // Test Case 4: Shift = 5, Fill = 5'h7 (Invalid Shift)
    $display("Test Case %0d: Shift = 5, Fill = 7 (Invalid Shift)", test_count++);
    in = {10{5'h4}};
    shift = 5;
    fill = 5'h7;

    expected_out = 0;
    expected_out_valid = 0;

    #1;
    if (out_valid === expected_out_valid) begin
      $display("  PASS");
    end else begin
      $display("  FAIL: out_valid=%b, expected_valid=%b", out_valid, expected_out_valid);
      error_count++;
    end


    // Test Case 5: Shift = 7, Fill = 5'hA (Invalid Shift)
    $display("Test Case %0d: Shift = 7, Fill = A (Invalid Shift)", test_count++);
    in = {10{5'h5}};
    shift = 7;
    fill = 5'hA;

    expected_out = 0;
    expected_out_valid = 0;

    #1;
    if (out_valid === expected_out_valid) begin
      $display("  PASS");
    end else begin
      $display("  FAIL: out_valid=%b, expected_valid=%b", out_valid, expected_out_valid);
      error_count++;
    end

     // Test Case 6: Shift = 2, Fill = 5'h3
    $display("Test Case %0d: Shift = 2, Fill = 3", test_count++);
    in = {10{5'hA}};
    shift = 2;
    fill = 5'h3;
    expected_out_valid = 1;

    expected_out = 0;
    for (i = 0; i < NUM_SYMBOLS; i++) begin
      if (i < shift) begin
        expected_out = set_symbol(i, fill, expected_out);
      end else begin
        expected_out = set_symbol(i, get_symbol(i-shift,in), expected_out);
      end
    end

    #1;
    if (out === expected_out && out_valid === expected_out_valid) begin
      $display("  PASS");
    end else begin
      $display("  FAIL: out=%h, expected=%h, out_valid=%b, expected_valid=%b", out, expected_out, out_valid, expected_out_valid);
      error_count++;
    end

    // Test Case 7: Shift = 4, Fill = 5'h1F
    $display("Test Case %0d: Shift = 4, Fill = 1F", test_count++);
    in = {10{5'h9}};
    shift = 4;
    fill = 5'h1F;
    expected_out_valid = 1;

    expected_out = 0;
    for (i = 0; i < NUM_SYMBOLS; i++) begin
      if (i < shift) begin
        expected_out = set_symbol(i, fill, expected_out);
      end else begin
        expected_out = set_symbol(i, get_symbol(i-shift,in), expected_out);
      end
    end


    #1;
    if (out === expected_out && out_valid === expected_out_valid) begin
      $display("  PASS");
    end else begin
      $display("  FAIL: out=%h, expected=%h, out_valid=%b, expected_valid=%b", out, expected_out, out_valid, expected_out_valid);
      error_count++;
    end

    // Final Result
    if (error_count == 0) begin
      $display("SUCCESS: All test cases passed!");
    end else begin
      $display("ERROR: %0d test cases failed.", error_count);
    end

    $finish;
  end

endmodule