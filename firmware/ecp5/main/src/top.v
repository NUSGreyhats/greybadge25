module top(
    input clk_ext, input [4:0] btn, output [7:0] led, 
    inout [7:0] interconnect, 
    inout [7:0] pmod_j1, inout [7:0] pmod_j2,
);
    /// Internal Configuration ///////////////////////////////////////////
    wire          clk_int;        // Internal OSCILLATOR clock
    defparam OSCI1.DIV = "3";
    OSCG OSCI1 (.OSC(clk_int));

    wire clk;
    assign clk = clk_int;
    //param CLK_FREQ = 48_000_00; // EXT CLK

    /// Chall: Shooting Flags ////////////////////////////////////////////
    // PWM Counter
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

    // Regular Shooting
    reg [7:0] shooting = 8'b101;
    reg [31:0] counter;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == 48_000_00/2) begin
            shooting <= shooting << 1 | shooting[7];
            counter <= 0;
        end
    end

    /// Chall: SecureMemory /////////////////////////////////////////////////////
    reg chall_secmem_clk; 
    reg [31:0] chall_secmem_clk_counter; 
    always @ (posedge clk) begin
        chall_secmem_clk_counter <= chall_secmem_clk_counter + 1;
        if (chall_secmem_clk_counter == CLK_FREQ/1000) begin
            chall_secmem_clk <= ~chall_secmem_clk;
        end
    end
    wire [4:0] chall_secmem_address;
    wire [7:0] chall_secmem_value;
    // secure_memory chall_secmem(
    //     .clk(chall_secmem_clk), 
    //     .address(chall_secmem_address), 
    //     .value(chall_secmem_value)
    // );

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
            
            .tx_trigger(~btn[0]),
            .tx_in({8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d, 8'h79, 8'h7d})
        );

    reg [7:0] cat_status = 8'b11111111;
    always @ (posedge clk) begin
        if (rx_out[7:0] <= 65+7 && rx_out[7:0] >= 65) begin
            cat_status[rx_out[7:0]-65] = 0;
        end
        if (rx_out[7:0] <= 97+7 && rx_out[7:0] >= 97) begin
            cat_status[rx_out[7:0]-97] = 1;
        end
    end 
    //////////////////////////////////////////////////////////////

    //// Shooting Cats /////////////////////////////////////////////////
    parameter MODE_BUTTON = 3'b000;
    parameter MODE_UART = 3'b001;
    parameter MODE_CHALL_SECURE_MEM = 3'b001;

    // Combinational Logic
    reg [7:0] wire_led;
    reg [7:0] wire_interconnect;
    reg [7:0] wire_pmod_j1;
    reg [7:0] wire_pmod_j2;

    

    wire [4:0] btn_out = btn;
    assign led = (( 
            ~btn[0] ? mode : 
            ~btn[1] ? rx_out[7:0] : 
            ~btn[2] ? {pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out} : 
            ~btn[3] ? shooting : 
            (shooting & cat_status & {pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out, pwm_out} | ~cat_status)
        )
    ); // & cat_status;


    //assign interconnect[7:5] = 3'bxxx;
    wire [2:0] mode = interconnect[7:5];
    assign interconnect[4:0] = (
        mode == MODE_BUTTON ? {btn_out} : 
        mode == MODE_UART ? {3'b101, tx, 1'bz} : 
        5'bzzzzz
    );
    assign rx = (mode == MODE_UART ? interconnect[0] : 1'bz);
endmodule
