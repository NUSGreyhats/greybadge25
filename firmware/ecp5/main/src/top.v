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

    // External Oscillator Easter egg ///////////////////////
    reg clk_ext_soldered = 0;
    always @ (posedge clk_ext) begin clk_ext_soldered <= 1; end

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

    /// Chall: UARTProcessor /////////////////////////////////////////////////////

    /// UART ////////////////////////////////////////////////////////////
    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 18;
    reg  [UART_FRAME_SIZE*DBITS-1:0] uart_tx_out = {8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d, 8'h79, 8'h7d};
    
    wire reset = ~btn[2];

    wire rx; //d 
    wire tx;
    wire [UART_FRAME_SIZE*DBITS-1:0] rx_out;
    wire rx_full, rx_empty;
    wire tx_trigger;
    // Complete UART Core
    uart_top 
        #(
            .FIFO_IN_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE_EXP(32), 
            .BR_LIMIT(672), 
            .BR_BITS(10)
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
            
            .tx_trigger(tx_trigger),
            .tx_in(uart_tx_out)
        );

    //////////////////////////////////////////////////////////////
    reg aes_enc_reset_n = 1; // not reset
    reg aes_enc_start = 1; // not reset
    reg [127:0] aes_in;
    reg [127:0] aes_key;
    wire[127:0] aes_enc_out_w; // This wire will contain the encrypted text using the 128bit key
    reg [127:0] aes_enc_out; // This wire will contain the encrypted text using the 128bit key
    wire aes_enc_valid;
    wire[127:0] aes_dec_out;

    // The encryption module uses AES128 by default
    Encryption enc(
        .clock(clk),
        .reset_n(aes_enc_reset_n),
        .start(aes_enc_start),

        .key(aes_key),
        .plain_text(aes_in),

        .enc_data(aes_enc_out_w),
        .valid_flag(aes_enc_valid)
    );
    // shitty buffer
    always @ (posedge clk) begin
        aes_enc_out <= {8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d} ;//aes_enc_out_w;
    end

    /// UART Controller ////////////////////////////////////////////////////////////
    reg tx_controller_send = 0;
    assign tx_trigger = ~btn[3] | tx_controller_send;
    // UART Commands 
    parameter UART_MODE_SHOOTING_FLAGS      = 65; //"A";
    parameter UART_MODE_SEND_TX             = 64; //"A"-1
    parameter UART_MODE_AES_KEY_STORE       = 66; //"B";
    parameter UART_MODE_AES_PLAINTEXT_STORE = 67; //"C";
    
    wire [UART_FRAME_SIZE*DBITS-1:0] flag = {8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d, 8'h79, 8'h7d};
    reg  [UART_FRAME_SIZE*DBITS-1:0] uart_tx_out = {8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d, 8'h79, 8'h7d};
    reg [7:0] cat_status = 8'b11111111;

    always @ (posedge clk) begin
        tx_controller_send <= 0;
        aes_enc_start <= 0 ;
        case (rx_out[8*(1)-1:8*(0)]) 
            UART_MODE_SHOOTING_FLAGS: begin if (rx_out[8*(3)-1:8*(2)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                if (rx_out[8*2-1:8*1] >= 65 && rx_out[8*2-1:8*1] <= 65+8) begin
                    cat_status[rx_out[8*2-1:8*1] - 65] <= 0;
                end
                if (rx_out[8*2-1:8*1] == "`") begin 
                    cat_status  <= 8'b11111111;
                end  
            end end
            /// Extra Code ///////////////////////////////////////////////////////////////////////////
            UART_MODE_SEND_TX: begin if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                // enable tx
                tx_controller_send <= 1;
                case (rx_out[8*2-1:8*1]) 
                    "A": begin uart_tx_out <= flag; end // Hornet Revenge Flag
                    "B": begin 
                        if (clk_ext_soldered) begin
                            uart_tx_out <= "fun{smd_skillz}"; 
                        end
                    end // Hornet Revenge Flag
                    "C": begin uart_tx_out <= aes_dec_out; end // Hornet Revenge Flag
                    default begin uart_tx_out <= "??????????????????"; end
                endcase
            end end
            UART_MODE_AES_KEY_STORE: begin if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                aes128_key <= rx_out[8*(17)-1:8*(1)];
            end end
            UART_MODE_AES_PLAINTEXT_STORE: begin if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                aes128_in <= rx_out[8*(17)-1:8*(1)];
                aes_enc_start <= 1;
            end end
            /// Extra Code ///////////////////////////////////////////////////////////////////////////
        endcase
    end 
    assign rx = (mode == MODE_UART ? interconnect[0] : 1'b1);

    //// I/O Configuration /////////////////////////////////////////////////
    parameter MODE_BUTTON = 3'b000;
    parameter MODE_UART = 3'b011;
    parameter MODE_CHALL_SECURE_MEM = 3'b010;
    parameter MODE_PASSTHROUGH = 3'b001;

    wire [4:0] btn_out = btn;
    assign led = (        
        ~btn[3] ? (interconnect & pwm_bulk_out) :
        mode == MODE_UART ?( 
            //~btn[0] ? btn : 
            ~btn[1] ? ((rx_out[8*1-1:8*0]) & pwm_bulk_out) : // Debugging
            ~btn[0] ? ((rx_out[8*2-1:8*1]) & pwm_bulk_out) : // Debugging
            (chall_shootingflags_leds & pwm_bulk_out) | ~cat_status
        ) : 
        0
    ); 

    wire [2:0] mode = interconnect[7:5];
    assign interconnect[4:0] = (
        mode == MODE_UART ? {3'bzzz, tx, 1'bz} : // this line causing button 0 to not enable, also tx not working
        mode == MODE_BUTTON ? {btn_out} : 
        //mode == MODE_PASSTHROUGH ? 5'bzzzzz : 
        5'bzzzzz
    );
    assign chall_secmem_address = interconnect[4:0];
    
    assign pmod_j2 = (
        mode == MODE_CHALL_SECURE_MEM ? chall_secmem_value : 
        //mode == MODE_PASSTHROUGH ? {interconnect[3:0], interconnect[3:0]}: 
        8'bzzzzzzzz
    );
    
endmodule
