module shooting_flags #(
    parameter CLK_FREQ = 48_000_000
) (
    input clk, output [7:0] cats
);

    //// PWM //////////////////////////////////////////////////////////////
    reg [31:0] counter_pwm;
    reg pwm_out = 0;
    always @ (posedge clk) begin
        counter_pwm <= counter_pwm + 1;
        if (counter_pwm == 1) begin
            pwm_out <= 0;
            //counter_pwm <= 0;
        end else if (counter_pwm == 4) begin
            pwm_out <= 1;
            counter_pwm <= 0;
        end
    end

    //// Shooting /////////////////////////////////////////////////////////
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
        if (counter == CLK_FREQ/2) begin
            shooting <= flag[counter_display] << counter_display; //shooting << 1 | shooting[7];
            counter <= 0;
            counter_display <= (counter_display + 1) % FLAG_LEN;
        end
    end

    /// LED output //////////////////////////////////////////////////////
    assign cats = shooting & {pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out};

endmodule
