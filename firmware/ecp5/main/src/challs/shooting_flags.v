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
    localparam FLAG_LEN = 36;
    reg [(8*FLAG_LEN-1):0] flag  = "grey{fire_movement_got_fire_pattern}";

    reg [7:0] shooting = 8'b0; //8'b101;
    reg [31:0] counter;
    reg [31:0] counter_display;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == CLK_FREQ/2) begin
            shooting <= flag[(counter_display+1)*8-1: (counter_display)*8]; //shooting << 1 | shooting[7];
            counter <= 0;
            counter_display <= (counter_display + 1) % FLAG_LEN;
        end
    end

    /// LED output //////////////////////////////////////////////////////
    assign cats = shooting & {pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out};

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