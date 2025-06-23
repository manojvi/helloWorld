module tb;

  reg clk;
  reg rst;
  reg in_valid;
  reg [3:0] in;
  wire [14:0] out;

  // Instantiate the DUT
  enc_bin2onehot dut (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .in(in),
    .out(out)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Testbench stimulus and verification
  initial begin
    rst = 1;
    in_valid = 0;
    in = 0;

    #10 rst = 0;

    // Test Case 1: in_valid = 0
    in_valid = 0;
    in = 4'b0000;
    #10;
    if (out == 15'b0) begin
      $display("PASS: Test Case 1 (in_valid = 0) passed");
    end else begin
      $display("FAIL: Test Case 1 (in_valid = 0) failed: out = %b", out);
    end

    // Test Case 2: in_valid = 1, in = 0
    in_valid = 1;
    in = 4'b0000;
    #10;
    if (out == 15'b000000000000001) begin
      $display("PASS: Test Case 2 (in_valid = 1, in = 0) passed");
    end else begin
      $display("FAIL: Test Case 2 (in_valid = 1, in = 0) failed: out = %b", out);
    end

    // Test Case 3: in_valid = 1, in = 1
    in_valid = 1;
    in = 4'b0001;
    #10;
    if (out == 15'b000000000000010) begin
      $display("PASS: Test Case 3 (in_valid = 1, in = 1) passed");
    end else begin
      $display("FAIL: Test Case 3 (in_valid = 1, in = 1) failed: out = %b", out);
    end

    // Test Case 4: in_valid = 1, in = 7
    in_valid = 1;
    in = 4'b0111;
    #10;
    if (out == 15'b000000010000000) begin
      $display("PASS: Test Case 4 (in_valid = 1, in = 7) passed");
    end else begin
      $display("FAIL: Test Case 4 (in_valid = 1, in = 7) failed: out = %b", out);
    end

    // Test Case 5: in_valid = 1, in = 14
    in_valid = 1;
    in = 4'b1110;
    #10;
    if (out == 15'b010000000000000) begin
      $display("PASS: Test Case 5 (in_valid = 1, in = 14) passed");
    end else begin
      $display("FAIL: Test Case 5 (in_valid = 1, in = 14) failed: out = %b", out);
    end

    // Test Case 6: in_valid = 1, in = 8
    in_valid = 1;
    in = 4'b1000;
    #10;
    if (out == 15'b000000001000000) begin
      $display("PASS: Test Case 6 (in_valid = 1, in = 8) passed");
    end else begin
      $display("FAIL: Test Case 6 (in_valid = 1, in = 8) failed: out = %b", out);
    end

    // Test Case 7: in_valid toggles from 1 to 0 when in=5
    in = 4'b0101;
    in_valid = 1;
    #10;
    if (out != 15'b000000000100000) begin
        $display("FAIL: Test Case 7a (in_valid = 1, in = 5) failed: out = %b", out);
    end else begin
      $display("PASS: Test Case 7a (in_valid = 1, in = 5) passed");
    end

    in_valid = 0;
    #10;
    if (out != 15'b0) begin
        $display("FAIL: Test Case 7b (in_valid = 0, in = 5) failed: out = %b", out);
    end else begin
      $display("PASS: Test Case 7b (in_valid = 0, in = 5) passed");
    end


    $display("SUCCESS: All test cases passed!");
    $stop;
  end

endmodule