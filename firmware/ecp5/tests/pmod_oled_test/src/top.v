module top(
    input clk_ext, input [4:0] btn, output [7:0] led, 
    inout [7:0] interconnect, 
    output [7:0] pmod_j1, output [7:0] pmod_j2,
);
    /// Internal Configuration ///////////////////////////////////////////
    wire          clk_int;        // Internal OSCILLATOR clock
    defparam OSCI1.DIV = "3"; // Info: Max frequency for clock '$glbnet$clk': 162.00 MHz (PASS at 103.34 MHz)
    OSCG OSCI1 (.OSC(clk_int));

    wire clk;
    assign clk = clk_int;

    localparam CLK_FREQ = 103_340_000; // EXT CLK

    /// LED On to test ////////////////////////////////////////////////
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
    reg slow_clk=0;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == CLK_FREQ/20) begin
            shooting <= flag[counter_display]; //shooting << 1 | shooting[7];
            counter <= 0;
            counter_display <= (counter_display + 1) % FLAG_LEN;
        end
        slow_clk <= ~slow_clk;
    end

    //assign led[6:0] = shooting;
    assign interconnect[4:0] = {btn};

    /// PMOD OLED ///////////////////////////////////////////////////
    wire clk_6_25mhz;
    //assign led[7] = clk_6_25mhz;
    clk_counter #(8, 8, 32) clk6p25m (clk_ext, clk_6_25mhz);

    // Inputs
    wire [7:0] Jx;
    assign pmod_j2[7:0] = 8'b11111111;
    assign pmod_j1[7:0] = 8'b10101010;
    // Outputs
    wire [12:0] oled_pixel_index;
    wire [15:0] oled_pixel_data = 15'b111111111111111;
    // Module
    Oled_Display display(
        .clk(clk_6_25mhz), .reset(0), 
        .frame_begin(), .sending_pixels(), .sample_pixel(), .pixel_index(oled_pixel_index), .pixel_data(oled_pixel_data), 
        .cs(Jx[3]), .sdin(Jx[2]), .sclk(Jx[0]), .d_cn(Jx[7]), .resn(Jx[6]), .vccen(Jx[5]), .pmoden(Jx[4])); //to SPI

    assign led = Jx;

    // OLED not working yet
endmodule
