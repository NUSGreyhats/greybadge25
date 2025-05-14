module top(input clk, input [4:0] btn, output [7:0] led, output [7:0] interconnect);

    localparam FLAG_LEN = 16;
    reg [7:0] flag[FLAG_LEN];
    always @ (*) begin
        flag[0] = 103;
        flag[1] = 114;
        flag[2] = 121;
        flag[3] = 123;
        flag[4] = 49;
        flag[5] = 95;
        flag[6] = 99;
        flag[7] = 97;
        flag[8] = 116;
        flag[9] = 95;
        flag[10] = 49;
        flag[11] = 95;
        flag[12] = 98;
        flag[13] = 105;
        flag[14] = 116;
        flag[15] = 125;
    end


    reg [7:0] shooting = 8'b101;
    reg [31:0] counter;
    reg [31:0] counter_display;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == 32_000_00/20) begin
            shooting <= flag[counter_display]; //shooting << 1 | shooting[7];
            counter <= 0;
            counter_display <= (counter_display + 1) % FLAG_LEN;
        end
    end

    assign led = shooting;
    assign interconnect = {3'b111, btn};
endmodule
