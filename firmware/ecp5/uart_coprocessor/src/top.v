module top(input clk_ext, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    /// Internal Configuration ///////////////////////////////////////////
    wire clk_int;        // Internal OSCILLATOR clock
    defparam OSCI1.DIV = "3"; // Info: Max frequency for clock '$glbnet$clk': 162.00 MHz (PASS at 103.34 MHz)
    OSCG OSCI1 (.OSC(clk_int));

    wire clk = clk_int;
    localparam CLK_FREQ = 103_340_000; // EXT CLK

    // AES Coprocessor /////////////////////////////////////////////////
    reg [127:0] aes_enc_key;
    reg [127:0] aes_enc_text_in;
    wire [127:0] aes_enc_text_out;
    reg aes_enc_ld = 0;
    wire aes_enc_done;
    aes_cipher_top AES_ENC(
        .clk(clk), 
        .rst(0), .ld(aes_enc_ld), 
        .done(aes_enc_done), 
        .key(aes_enc_key), 
        .text_in(aes_enc_text_in),
        .text_out(aes_enc_text_out) 
    );

    reg [127:0] aes_enc_text_out_reg;
    always @ (posedge clk_ext) begin
        if (aes_enc_done) begin
            aes_enc_text_out_reg <= aes_enc_text_out;
        end
    end
    /// UART ////////////////////////////////////////////////
    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 18;

    wire reset = ~btn[2];

    wire rx;
    wire tx;
    wire [UART_FRAME_SIZE*DBITS-1:0] rx_out;
    reg [UART_FRAME_SIZE*DBITS-1:0] uart_tx_out = "asdfghjkl";
    reg tx_controller_send = 0;
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
            
            .rx(interconnect[0]),
            .tx(tx),
            
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .rx_out(rx_out),
            
            .tx_trigger(tx_controller_send | ~btn[1]),
            .tx_in(uart_tx_out) //{8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d, 8'h79, 8'h7d})
        );

    /// Control Logic ///////////////////////////////////////////////
    task uart_decoder_reset();
        tx_controller_send <= 0;
        aes_enc_ld <= 0;
    endtask

    task uart_decoder();
        if (rx_out[8*(18)-1:8*(17)] == rx_out[8*(1)-1:8*(0)]) begin 
            case (rx_out[8*(1)-1:8*(0)]) 
                "A": begin // testing
                    uart_tx_out <= "123456789012345678";
                    tx_controller_send <= 1;
                end
                "B": begin // display AES encryption
                    uart_tx_out <= aes_enc_text_out_reg;
                    tx_controller_send <= 1;
                end
                "C": begin // Key
                    aes_enc_key <= rx_out[8*(17)-1:8*(1)];
                end
                "D": begin // PlainText
                    aes_enc_text_in <= rx_out[8*(17)-1:8*(1)];
                end
                "E": begin // PlainText
                    aes_enc_ld <= 1;
                end
            endcase
        end
    endtask

    always @ (posedge clk_ext) begin
        uart_decoder_reset();
        uart_decoder();
    end 

    // https://gchq.github.io/CyberChef/#recipe=To_Hex('Space',0)Find_/_Replace(%7B'option':'Regex','string':'%20'%7D,',%208%5C'h',true,false,true,false)&input=e2hpX2knbV95b3VyX2FybXl9
    assign interconnect[1] = tx;
    assign led = (
        ~btn[4] ? rx_out[8*(1)-1:8*(0)] :
        ~btn[3] ? rx_out[8*(2)-1:8*(1)] :
        interconnect
    );

endmodule
