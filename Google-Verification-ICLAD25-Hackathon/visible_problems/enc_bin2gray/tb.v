`timescale 1ns / 1ps

module tb;

  reg [9:0] bin;
  wire [9:0] gray;

  enc_bin2gray dut (
    .bin(bin),
    .gray(gray)
  );

  initial begin
    // Test case 1: bin = 0
    bin = 10'b0000000000;
    #1;
    check(bin, gray);

    // Test case 2: bin = 1
    bin = 10'b0000000001;
    #1;
    check(bin, gray);

    // Test case 3: bin = all 1s
    bin = 10'b1111111111;
    #1;
    check(bin, gray);

    // Test case 4: bin = alternating 0s and 1s
    bin = 10'b1010101010;
    #1;
    check(bin, gray);

    // Test case 5: bin = single 1 at MSB
    bin = 10'b1000000000;
    #1;
    check(bin, gray);

    // Test case 6: bin = single 1 at LSB
    bin = 10'b0000000001;
    #1;
    check(bin, gray);

    // Test case 7: bin = incrementing sequence
    bin = 10'b0000000010;
    #1;
    check(bin, gray);

    bin = 10'b0000000011;
    #1;
    check(bin, gray);

    bin = 10'b0000000100;
    #1;
    check(bin, gray);

    // Test case 8: Edge case - large binary number
    bin = 10'b1011010011;
    #1;
    check(bin, gray);
    
    // Test case 9: Edge case - another binary number
    bin = 10'b0100101100;
    #1;
    check(bin, gray);

    // Test case 10: Edge case - zero again to reset.
    bin = 10'b0000000000;
    #1;
    check(bin, gray);

    $display("SUCCESS: All test cases passed!");
    $finish;
  end

  function automatic [9:0] calculate_gray(input [9:0] binary);
    integer i;
    calculate_gray[9] = binary[9];
    for (i = 0; i < 9; i = i + 1) begin
      calculate_gray[i] = binary[i+1] ^ binary[i];
    end
  endfunction

  task check(input [9:0] current_bin, input [9:0] current_gray);
    reg [9:0] expected_gray;
    expected_gray = 10'bx; // Initialize. Important!
    expected_gray = calculate_gray(current_bin);

    if (current_gray == expected_gray) begin
      $display("PASS: bin = %b, gray = %b", current_bin, current_gray);
    end else begin
      $display("FAIL: bin = %b, expected gray = %b, actual gray = %b", current_bin, expected_gray, current_gray);
      $stop;
    end
  endtask

endmodule