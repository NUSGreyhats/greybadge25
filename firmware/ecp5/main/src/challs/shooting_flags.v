module shooting_flags #(
    parameter CLK_FREQ = 48_000_000
) (
    input clk, input got_commanding_officer, output [7:0] cats
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

    //// Shooting Rate ////////////////////////////////////////////////////
    // Create a new clock
    reg [31:0] counter = 0;
    reg clk_shooting = 0;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == CLK_FREQ/30) begin
            clk_shooting <= ~clk_shooting;
            counter <= 0;
        end
    end

    //// Shooting /////////////////////////////////////////////////////////
    localparam FLAG_LEN = 45;
    reg [7:0] flag[FLAG_LEN];
    always @ (*) begin
        flag[0] = 103; flag[1] = 114; flag[2] = 101; flag[3] = 121; flag[4] = 123;
        flag[5] = 101; flag[6] = 104; flag[7] = 95; flag[8] = 108; flag[9] = 105;
        flag[10] = 118; flag[11] = 101; flag[12] = 95; flag[13] = 102; flag[14] = 105;
        flag[15] = 114; flag[16] = 105; flag[17] = 110; flag[18] = 103; flag[19] = 95;
        flag[20] = 100; flag[21] = 111; flag[22] = 110; flag[23] = 116; flag[24] = 95;
        flag[25] = 116; flag[26] = 117; flag[27] = 114; flag[28] = 110; flag[29] = 95;
        flag[30] = 121; flag[31] = 111; flag[32] = 117; flag[33] = 114; flag[34] = 95;
        flag[35] = 98; flag[36] = 114; flag[37] = 97; flag[38] = 105; flag[39] = 110;
        flag[40] = 95; flag[41] = 111; flag[42] = 102; flag[43] = 102; flag[44] = 125;
    end

    reg [7:0] shooting = 8'b101;
    reg [7:0] shooting_flag = 8'b0;
    reg [$clog2(FLAG_LEN)-1:0] counter_display = 0;
    always @ (posedge clk_shooting) begin
        shooting <= shooting << 1 | shooting[7];
        shooting_flag <= (
            flag[counter_display] << counter_display % 8 | 
            flag[counter_display] >> (8-counter_display%8)
        );
        counter_display <= (counter_display + 1) % FLAG_LEN;
    end

    /// LED output //////////////////////////////////////////////////////
    assign cats = (
        (got_commanding_officer ? shooting_flag : shooting) & 
        {pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out}
    );

endmodule

    // // Regular Shooting
    // reg [7:0] shooting = 8'b101;
    // reg [31:0] counter;
    // always @ (posedge clk) begin
    //     counter <= counter + 1;
    //     if (counter == 48_000_00/2) begin
    //         shooting <= shooting << 1 | shooting[7];
    //         counter <= 0;
    //     end
    // end