module top(input clk, output reg led);
    reg [31:0] counter;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == 32_000_00) begin
            led <= 1;
        end
        if (counter == 64_000_00) begin
            led <= 0;
            counter <= 0;
        end
    end
endmodule
