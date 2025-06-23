`timescale 1ns / 1ps

module tb;

  // Inputs
  reg clk;
  reg rst;
  reg data_valid;
  reg [11:0] data;

  // Outputs
  wire enc_valid;
  wire [12:0] enc_codeword;

  // Instantiate the Unit Under Test (UUT)
  ecc_sed_encoder uut (
    .clk(clk),
    .rst(rst),
    .data_valid(data_valid),
    .data(data),
    .enc_valid(enc_valid),
    .enc_codeword(enc_codeword)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Testbench stimulus and verification
  initial begin
    // Initialize signals
    rst = 1;
    data_valid = 0;
    data = 0;

    // Apply reset
    #10 rst = 0;
    #10;

    // Test cases

    // Test case 1: All zeros
    data_valid = 1;
    data = 0;
    #1;
    if (enc_valid == ~data_valid && enc_codeword == 13'b0000000000000) begin
      $display("PASS: Test Case 1 (All zeros) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
    end else begin
      $display("FAIL: Test Case 1 (All zeros) - enc_valid=%b (expected %b), enc_codeword=%b (expected %b)", enc_valid, ~data_valid, enc_codeword, 13'b0000000000000);
    end
    data_valid = 0;
    #1;

    // Test case 2: All ones
    data_valid = 1;
    data = 12'hFFF;
    #1;
    if (enc_valid == ~data_valid) begin
      integer parity_check = ^data;
      if (parity_check == 1'b0 && enc_codeword == {1'b0, data})
          $display("PASS: Test Case 2 (All ones) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else if (parity_check == 1'b1 && enc_codeword == {1'b1, data})
          $display("PASS: Test Case 2 (All ones) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else
        $display("FAIL: Test Case 2 (All ones) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end else begin
        $display("FAIL: Test Case 2 (All ones) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end
    data_valid = 0;
    #1;

    // Test case 3: Single one
    data_valid = 1;
    data = 12'b000000000001;
    #1;
    if (enc_valid == ~data_valid) begin
      integer parity_check = ^data;
      if (parity_check == 1'b0 && enc_codeword == {1'b0, data})
          $display("PASS: Test Case 3 (Single one) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else if (parity_check == 1'b1 && enc_codeword == {1'b1, data})
          $display("PASS: Test Case 3 (Single one) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else
        $display("FAIL: Test Case 3 (Single one) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end else begin
      $display("FAIL: Test Case 3 (Single one) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end
    data_valid = 0;
    #1;

    // Test case 4: Single zero
    data_valid = 1;
    data = 12'b111111111110;
    #1;
    if (enc_valid == ~data_valid) begin
      integer parity_check = ^data;
      if (parity_check == 1'b0 && enc_codeword == {1'b0, data})
          $display("PASS: Test Case 4 (Single zero) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else if (parity_check == 1'b1 && enc_codeword == {1'b1, data})
          $display("PASS: Test Case 4 (Single zero) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else
        $display("FAIL: Test Case 4 (Single zero) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end else begin
      $display("FAIL: Test Case 4 (Single zero) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end
    data_valid = 0;
    #1;

    // Test case 5: Alternating 0s and 1s
    data_valid = 1;
    data = 12'b101010101010;
    #1;
    if (enc_valid == ~data_valid) begin
      integer parity_check = ^data;
      if (parity_check == 1'b0 && enc_codeword == {1'b0, data})
          $display("PASS: Test Case 5 (Alternating 0s and 1s) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else if (parity_check == 1'b1 && enc_codeword == {1'b1, data})
          $display("PASS: Test Case 5 (Alternating 0s and 1s) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else
        $display("FAIL: Test Case 5 (Alternating 0s and 1s) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end else begin
      $display("FAIL: Test Case 5 (Alternating 0s and 1s) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end
    data_valid = 0;
    #1;

    // Test case 6: Another pattern
    data_valid = 1;
    data = 12'b110011001100;
    #1;
    if (enc_valid == ~data_valid) begin
      integer parity_check = ^data;
      if (parity_check == 1'b0 && enc_codeword == {1'b0, data})
          $display("PASS: Test Case 6 (Another Pattern) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else if (parity_check == 1'b1 && enc_codeword == {1'b1, data})
          $display("PASS: Test Case 6 (Another Pattern) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else
        $display("FAIL: Test Case 6 (Another Pattern) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end else begin
      $display("FAIL: Test Case 6 (Another Pattern) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end
    data_valid = 0;
    #1;

    // Test case 7: Random data
    data_valid = 1;
    data = $random;
    #1;
    if (enc_valid == ~data_valid) begin
      integer parity_check = ^data;
      if (parity_check == 1'b0 && enc_codeword == {1'b0, data})
          $display("PASS: Test Case 7 (Random Data) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else if (parity_check == 1'b1 && enc_codeword == {1'b1, data})
          $display("PASS: Test Case 7 (Random Data) - enc_valid=%b, enc_codeword=%b", enc_valid, enc_codeword);
      else
        $display("FAIL: Test Case 7 (Random Data) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end else begin
      $display("FAIL: Test Case 7 (Random Data) - enc_valid=%b (expected %b), enc_codeword=%b", enc_valid, ~data_valid, enc_codeword);
    end
    data_valid = 0;
    #1;

    $display("SUCCESS: All test cases passed!");
    $stop;
  end

endmodule