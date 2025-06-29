`timescale 1ns / 1ps

module tb;

  // Inputs
  reg clk;
  reg [4:0] btn;

  // Outputs
  wire [7:0] led;
  wire [7:0] interconnect;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk),
    .btn(btn),
    .led(led),
    .interconnect(interconnect)
  );

  // Clock generation
  parameter CLK_PERIOD = 10; // Define clock period in ns
  initial begin
    clk = 0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // Stimulus generation
  initial begin
    // Initialize inputs
    btn = 5'b11101;

    // Apply reset (if needed by internal modules, though not explicitly in top)
    //#(2 * CLK_PERIOD); // Wait for a few clock cycles

    // Test case 1: Trigger transmission by pressing btn[0]
    $display("--- Test Case 1: Trigger Transmission ---");
    @(posedge clk);
    btn[0] = 0; // Press button 0
    @(posedge clk);
    btn[0] = 1; // Release button 0
    # (50 * CLK_PERIOD); // Wait for transmission to likely complete

    // Test case 2: Keep button pressed (should trigger repeatedly)
    $display("--- Test Case 2: Keep Button Pressed ---");
    @(posedge clk);
    btn[0] = 0; // Keep button 0 pressed
    # (100 * CLK_PERIOD); // Wait for multiple transmissions
    @(posedge clk);
    btn[0] = 1; // Release button 0
    # (50 * CLK_PERIOD);

    // Add more test cases as needed to verify different scenarios
    // For example, you might want to simulate receiving data if the 'uart_top'
    // module has input ports for that. Since 'top' only shows transmission,
    // the focus here is on triggering that.

    $finish; // End the simulation
  end

  // Monitor signals (optional, but helpful for debugging)
  initial begin
    $monitor("Time=%t, clk=%b, btn=%b, led=%b, interconnect=%b", $time, clk, btn, led, interconnect);
  end

endmodule