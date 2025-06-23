module top(
    input clk_ext, input [4:0] btn, output [7:0] led, 
    inout [7:0] interconnect, 
    inout [7:0] pmod_j1, inout [7:0] pmod_j2,
    inout [4:0] s // secret pins
);
    /// Internal Configuration ///////////////////////////////////////////
    wire clk_int;        // Internal OSCILLATOR clock
    defparam OSCI1.DIV = "3"; // Info: Max frequency for clock '$glbnet$clk': 162.00 MHz (PASS at 103.34 MHz)
    OSCG OSCI1 (.OSC(clk_int));

    wire clk = clk_int;
    localparam CLK_FREQ = 103_340_000; // EXT CLK

    // External Oscillator Easter egg /////
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
    
    /// UART ////////////////////////////////////////////////////////////
    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 18;
    
    // Outputs
    wire rx; 
    wire tx;
    // Control
    wire reset = ~btn[2];
    wire rx_full, rx_empty;
    wire tx_trigger;
    // Data
    reg  [UART_FRAME_SIZE*DBITS-1:0] uart_tx_out;
    wire [UART_FRAME_SIZE*DBITS-1:0] rx_out;

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

    // posedge detector for tx_trigger
    reg  tx_controller_send = 0;
    wire tx_trigger_pe;
    assign tx_trigger = ~btn[3] | tx_trigger_pe;
    pos_edge_det UART_TRIGGER_UNIT (.sig(tx_controller_send), .clk(clk), .pe(tx_trigger_pe));

    // RX handling
    assign rx = (mode == MODE_UART ? interconnect[0] : 1'b1);

    /// CatCore ///////////////////////////////////////////////////////////////////////
    wire catcore_devmode_input = s[0]; //cs
    reg catcore_devmode_counter = 0;
    reg catcore_devmode = 1;
    always @ (posedge clk) begin
        if (catcore_devmode_counter == 0 && catcore_devmode_input == 0) begin
            catcore_devmode <= 1;
        end
        catcore_devmode_counter <= 1;
    end

    //// CatCore Key Manager    
    reg chall_catcore_address;
    reg [127:0] chall_catcore_value;
    always @ (*) begin
        case (chall_catcore_address)
            0: chall_catcore_value = 127'b0; // Developer key
            1: chall_catcore_value = "theadminispowers"; // Developer key
            default: catcore_key = 127'b0;
        endcase
    end

    //// CatCore Hyper - Super Hyper Mode
    parameter CATCORE_HYPER_STAGE_IDLE = 0;
    parameter CATCORE_HYPER_STAGE_DECODE = 1;
    parameter CATCORE_HYPER_STAGE_RUN = 2;
    reg [1:0]   catcore_hyper_stage = CATCORE_HYPER_STAGE_IDLE;
    reg [127:0] catcore_hyper_instruction;
    reg [127:0] catcore_hyper_instruction_decrypted; 

    parameter CATCORE_HYPER_INSTR_FLAG = "A";
    task catcore_hyper_instruction_decoder(input [127:0] instr);
        if (instr[8*(16)-1:8*(15)] == instr[8*(1)-1:8*(0)]) begin
            case (instr[8*(1)-1:8*(0)])
                CATCORE_HYPER_INSTR_FLAG: begin
                    tx_controller_send <= 1;
                    uart_tx_out <= "grey{lmao_sandbox}";
                end
            endcase
            // Send Flag
        end
        catcore_hyper_stage <= CATCORE_HYPER_STAGE_IDLE;
    endtask
    
    task catcore_hyper_fsm();
        case (catcore_hyper_stage)
            CATCORE_HYPER_STAGE_IDLE: begin
                catcore_hyper_stage <= CATCORE_HYPER_STAGE_IDLE;
            end
            CATCORE_HYPER_STAGE_DECODE: begin
                catcore_hyper_instruction_decrypted <= catcore_hyper_instruction;
                catcore_hyper_stage <= CATCORE_HYPER_STAGE_RUN;
            end
            CATCORE_HYPER_STAGE_RUN: begin
                catcore_hyper_instruction_decoder(catcore_hyper_instruction_decrypted);
            end
        endcase
    endtask


    //////////////////////////////////////////////////////////////
    reg aes_enc_reset_n = 1; // not reset
    reg aes_enc_start = 0; // not reset
    reg [127:0] aes_in;
    reg [127:0] aes_key;
    wire[127:0] aes_enc_out_w;
    reg [127:0] aes_enc_out; 
    wire aes_enc_valid;
    wire[127:0] aes_dec_out_w;
    reg [127:0] aes_dec_out;  
    wire aes_dec_valid;

    // The encryption module uses AES128 by default
    aes enc(
        .clk(clk),
        .nreset(aes_enc_reset_n),
        .data_v_i(aes_enc_start),
        
        .key_i(aes_key),
        .data_i(aes_in),

        .res_o(aes_enc_out_w),
        .res_v_o(aes_enc_valid)
    );

    iaes dec(
        .clk(clk),
        .nreset(aes_enc_reset_n),
        .data_v_i(aes_enc_start),
        
        .key_i(aes_key),
        .data_i(aes_in),

        .res_o(aes_dec_out_w),
        .res_v_o(aes_dec_valid)
    );

    always @ (posedge clk) begin
        if (aes_enc_valid) begin
            aes_enc_out <= aes_enc_out_w;
        end
        if (aes_dec_valid) begin
            aes_dec_out <= aes_dec_out_w;
        end
    end

    /// UART Controller ////////////////////////////////////////////////////////////
    reg tx_controller_send = 0;
    // UART Commands 
    parameter UART_MODE_SHOOTING_FLAGS      = "A"; 
    parameter UART_MODE_SEND_TX             = "@"; 
    parameter UART_MODE_AES_KEY_STORE       = "B"; 
    parameter UART_MODE_AES_PLAINTEXT_STORE = "C"; 
    parameter UART_MODE_PRIVILEGED_EXECUTOR = "D"; 
    
    parameter UART_MODE_DEV_READ_MEM_ADDRESS = "a"; //"a" 97;
    parameter UART_MODE_DEV_READ_VALUES = "b"; //"a" 97;
    
    reg [7:0] cat_status = 8'b11111111;

    task uart_decoder_reset();
        tx_controller_send <= 0;
        aes_enc_start <= 0 ;
    endtask

    task uart_decoder();
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
                    "A": begin uart_tx_out <= "{hi_i'm_your_army}"; end // Hornet Revenge Flag
                    "B": begin uart_tx_out <= "??????????????????";
                        if (clk_ext_soldered) begin
                               uart_tx_out <= "fun{smd_skillz}"; 
                        end
                    end // Hornet Revenge Flag
                    "C": begin uart_tx_out <= aes_enc_out_w; end 
                    "D": begin uart_tx_out <= aes_enc_out; end 
                    "E": begin uart_tx_out <= aes_dec_out_w; end 
                    "F": begin uart_tx_out <= aes_dec_out; end 
                    default begin  end
                endcase
            end end
            /// AES CoProcessor ///////////////////////////////////////////////////////////////////////////
            UART_MODE_AES_KEY_STORE: begin if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                aes128_key <= rx_out[8*(17)-1:8*(1)];
            end end
            UART_MODE_AES_PLAINTEXT_STORE: begin if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                aes128_in <= rx_out[8*(17)-1:8*(1)];
                aes_enc_start <= 1;
            end end
            /// CatCore ///////////////////////////////////////////////////////////////////////////
            UART_MODE_PRIVILEGED_EXECUTOR: begin if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                //// Need to Decrypt
                catcore_stage <= CATCORE_STAGE_DECODE;
                chall_catcore_instruction <= rx_out[8*(17)-1:8*(1)];
            end end
            /// Devmode Hidden Instructions ///////////////////////////////////////////////////////////////////////////
            UART_MODE_DEV_READ_MEM_ADDRESS: if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                chall_catcore_address <= rx_out[8*(17)-1:8*(16)];
            end 
            UART_MODE_DEV_READ_VALUES: if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin // endchar
                tx_controller_send <= 1;
                uart_tx_out <= chall_catcore_value;
            end 
        endcase
    endtask

    always @ (posedge clk) begin
        uart_decoder_reset();
        catcore_hyper_fsm();
        if (catcore_hyper_stage == CATCORE_HYPER_STAGE_IDLE) begin
            uart_decoder();
        end
    end 
    

    //// I/O Configuration /////////////////////////////////////////////////
    parameter MODE_BUTTON = 3'b000;
    parameter MODE_UART = 3'b011;
    parameter MODE_CHALL_SECURE_MEM = 3'b010;
    parameter MODE_PASSTHROUGH = 3'b001;

    wire [4:0] btn_out = btn;
    assign led = (        
        (catcore_devmode & ~btn[3]) ? (interconnect & pwm_bulk_out) :
        (catcore_devmode & ~btn[4])? (s & pwm_bulk_out) :
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
