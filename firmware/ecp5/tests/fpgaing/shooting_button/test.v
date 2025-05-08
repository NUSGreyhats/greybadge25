module top(input clk, input [4:0] btn, output [7:0] led, output [7:0] interconnect);
    reg [7:0] shooting = 8'b101;
    reg [31:0] counter;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == 32_000_00/20) begin
            shooting <= shooting << 1 | shooting[7];
            counter <= 0;
        end
    end

    assign led = ~btn[0] ? btn : shooting;
    assign interconnect = {3'b111, btn};
endmodule
