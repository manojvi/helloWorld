module lfsr (
    input clk,
    input rst,
    input reinit,
    input advance,
    output out,
    input [4:0] initial_state,
    input [4:0] taps,
    output [4:0] out_state
);

  reg [4:0] state;

  assign out_state = state;
  assign out = state[0];

  always @(posedge clk) begin
    if (rst) begin
      state <= initial_state;
    end else if (reinit) begin
      state <= initial_state;
    end else if (advance) begin
      state <= {state[3:0], ^(state & taps)};
    end
  end

endmodule

module tb;

  reg clk;
  reg rst;
  reg reinit;
  reg advance;
  wire out;
  reg [4:0] initial_state;
  reg [4:0] taps;
  wire [4:0] out_state;

  lfsr dut (
    .clk(clk),
    .rst(rst),
    .reinit(reinit),
    .advance(advance),
    .out(out),
    .initial_state(initial_state),
    .taps(taps),
    .out_state(out_state)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Testbench stimulus
  initial begin
    clk = 0;
    rst = 0;
    reinit = 0;
    advance = 0;
    initial_state = 5'b00000;
    taps = 5'b10001; // Example taps for a maximal length LFSR

    // Reset test
    rst = 1;
    #10;
    rst = 0;
    initial_state = 5'b10101;
    #10;
    if (out_state != 5'b10101) begin
      $display("FAIL: Reset test failed. Expected 5'b10101, got %b", out_state);
    end else begin
      $display("PASS: Reset test passed.");
    end

    // Basic advance test
    advance = 1;
    #10;
    advance = 0;
    initial_state = 5'b10101;
    taps = 5'b10001;
    reg [4:0] expected_adv;
    expected_adv = {initial_state[3:0], ^(initial_state & taps)};
    if (out_state != expected_adv) begin
        $display("FAIL: Advance test failed. Expected %b, got %b", expected_adv, out_state);
    end else begin
        $display("PASS: Advance test passed.");
    end

    // Reinit test
    reinit = 1;
    initial_state = 5'b01010;
    #10;
    reinit = 0;
    if (out_state != 5'b01010) begin
      $display("FAIL: Reinit test failed. Expected 5'b01010, got %b", out_state);
    end else begin
      $display("PASS: Reinit test passed.");
    end

    // Advance and reinit test (reinit should take precedence)
    advance = 1;
    reinit = 1;
    initial_state = 5'b11001;
    #10;
    advance = 0;
    reinit = 0;
    if (out_state != 5'b11001) begin
      $display("FAIL: Advance and reinit test failed. Expected 5'b11001, got %b", out_state);
    end else begin
      $display("PASS: Advance and reinit test passed.");
    end

    // Hold state test (advance and reinit low)
    #10;
    if (out_state != 5'b11001) begin
      $display("FAIL: Hold state test failed. Expected 5'b11001, got %b", out_state);
    end else begin
      $display("PASS: Hold state test passed.");
    end

    // Multiple advance test
    initial_state = 5'b00001;
    taps = 5'b10001;
    rst = 1;
    #10;
    rst = 0;
    #1;
    advance = 1;
    #10;
    advance = 1;
    #10;
    advance = 1;
    #10;
    advance = 0;
    #10;

    reg [4:0] expected_state;
    expected_state = initial_state;
    for (int i = 0; i < 3; i++) begin
        expected_state = {expected_state[3:0], ^(expected_state & taps)};
    end

    if (out_state != expected_state) begin
        $display("FAIL: Multiple advance test failed. Expected %b, got %b", expected_state, out_state);
    end else begin
        $display("PASS: Multiple advance test passed.");
    end

    $display("SUCCESS: All test cases passed!");
    $finish;
  end

endmodule