module top(input clk, input [4:0] btn, inout [7:0] pmod, output [7:0] led, output [7:0] interconnect);
    assign led = pmod;
    assign interconnect = {3'b111, btn};
endmodule
