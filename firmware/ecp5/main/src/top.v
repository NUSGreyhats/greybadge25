module top(
    input clk_ext, input [4:0] btn, output [7:0] led, 
    inout [7:0] interconnect, 
    inout [7:0] pmod_j1, inout [7:0] pmod_j2,
);
    /// Internal Configuration ///////////////////////////////////////////
    wire          clk_int;        // Internal OSCILLATOR clock
    defparam OSCI1.DIV = "3"; // Info: Max frequency for clock '$glbnet$clk': 162.00 MHz (PASS at 103.34 MHz)
    OSCG OSCI1 (.OSC(clk_int));

    wire clk;
    assign clk = clk_int;

    localparam CLK_FREQ = 103_340_000; // EXT CLK

    /// PWM for Generic Control //////////////////////////////////////////
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
    wire [7:0] pwm_bulk_out = {pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out};

    /// Chall: Shooting Flags ////////////////////////////////////////////
    wire [7:0] chall_shootingflags_leds;
    shooting_flags #(.CLK_FREQ(CLK_FREQ)) chall_shootingflags (
        .clk(clk), 
        .got_commanding_officer(~btn[2]),
        .cats(chall_shootingflags_leds)
    );

    /// Chall: SecureMemory /////////////////////////////////////////////////////
    reg chall_secmem_clk = 0; // 10hz clock
    reg [31:0] chall_secmem_clk_counter = 0; 
    always @ (posedge clk) begin
        chall_secmem_clk_counter <= chall_secmem_clk_counter + 1;
        if (chall_secmem_clk_counter >= CLK_FREQ/20) begin
            chall_secmem_clk <= ~chall_secmem_clk;
            chall_secmem_clk_counter <= 0;
        end
    end
    wire [4:0] chall_secmem_address;
    wire [7:0] chall_secmem_value;
    secure_memory chall_secmem(
        .clk(chall_secmem_clk), 
        .address(chall_secmem_address), 
        .value(chall_secmem_value)
    );
    assign chall_secmem_address = interconnect[4:0];
    assign pmod_j2 = chall_secmem_value;
    /// UART ////////////////////////////////////////////////////////////
    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 18;

    wire reset = ~btn[2];

    wire rx; //d 
    wire tx;
    wire [UART_FRAME_SIZE*DBITS-1:0] rx_out;
    wire rx_full, rx_empty;
    // Complete UART Core
    uart_top 
        #(
            .FIFO_IN_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE_EXP(32)
        ) 
        UART_UNIT
        (
            .clk_100MHz(clk),
            .reset(reset),
            
            .rx(rx),
            .tx(tx),
            
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .rx_out(rx_out),
            
            .tx_trigger(~btn[3]),
            .tx_in({8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d, 8'h79, 8'h7d})
        );

    reg [7:0] cat_status = 8'b11111111;
    always @ (posedge clk) begin
        if (rx_out[7:0] <= 65+7 && rx_out[7:0] >= 65) begin
            cat_status[rx_out[7:0]-65] <= 0;
        end
        if (rx_out[7:0] <= 97+7 && rx_out[7:0] >= 97) begin
            cat_status[rx_out[7:0]-97] <= 1;
        end
        if (rx_out[7:0] == 96) begin // clear all
            cat_status <= 8'b11111111;
        end
    end 
    //////////////////////////////////////////////////////////////

    //// Shooting Cats /////////////////////////////////////////////////
    parameter MODE_BUTTON = 3'b000;
    parameter MODE_UART = 3'b100;
    parameter MODE_CHALL_SECURE_MEM = 3'b010;

    // Combinational Logic
    reg [7:0] wire_led;
    reg [7:0] wire_interconnect;
    reg [7:0] wire_pmod_j1;
    reg [7:0] wire_pmod_j2;
    // always @ (*) begin
    //     wire_pmod_j1 = chall_secmem_value;
    // end
    // assign pmod_j1 = wire_pmod_j1;

    wire [4:0] btn_out = btn;
    assign led = (( 
            //~btn[0] ? btn : 
            ~btn[1] ? (rx_out[7:0] & pwm_bulk_out) : // Debugging
            ~btn[3] ? (interconnect & pwm_bulk_out) : 
            ~btn[4] ? (chall_secmem_clk) : 
            (chall_shootingflags_leds & pwm_bulk_out) | ~cat_status
        )
    ); // & cat_status;


    //assign interconnect[7:5] = 3'bxxx;
    wire [2:0] mode = interconnect[7:5];
    assign interconnect[4:0] = (
        //mode == MODE_UART ? {3'bzzz, tx, 1'bz} : // this line causing button 0 to not enable, also tx not working
        mode == MODE_BUTTON ? {btn_out} : 
        5'bzzzzz
    );
    assign rx = (mode == MODE_UART ? interconnect[0] : 1'bz);
endmodule
