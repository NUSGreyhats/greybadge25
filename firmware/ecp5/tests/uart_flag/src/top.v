module top(input clk, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 4;

    // UART Params
    parameter SB_TICK = 16;       // number of stop bit / oversampling ticks
    // Baud Rate
    parameter BR_LIMIT = 204;     // baud rate generator counter limit
    parameter BR_BITS = 8;       // number of baud rate generator counter bits
    
    
    //// UART Setup ////////////////////////////////////////////////////
    wire reset = 0; // = ~btn[1];


    //// Baud Rate ////////////////////////////////////////////////////
    wire tick = ~btn[1];                  // sample tick from baud rate generator
    // Instantiate Modules for UART Core
    baud_rate_generator // basically a clock scalar
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
         ) 
        BAUD_RATE_GEN   
        (
            .clk_100MHz(clk), 
            .reset(reset),
            //.tick(tick)
         );
    
    //// Transmitter /////////////////////////////////////////////////
    wire tx;
    wire tx_done_tick;                  // data transmission complete
    wire [1:0] state_out;
    uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_TX_UNIT
         (
            .clk_100MHz(clk),
            .reset(reset),
            .tx(tx),
            .sample_tick(tick),
            .tx_start(~btn[0]), //tx_send),
            .data_in(8'd0), //tx_fifo_out),
            .tx_done(tx_done_tick), 
            .state_out(state_out)
         );

    assign interconnect[0] = tx;
    assign led = (~btn[4] ? 
        btn :
        (~btn[3] ? 
            rx_out :
            {state_out, 4'b1111,  tick, tx}
        )
    );

endmodule
