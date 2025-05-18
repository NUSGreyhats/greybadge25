module top(input clk, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 4;

    // UART Params
    parameter SB_TICK = 16;       // number of stop bit / oversampling ticks
    // Baud Rate
    parameter BR_LIMIT = 20;     // baud rate generator counter limit
    parameter BR_BITS = 5;       // number of baud rate generator counter bits
    

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    reg l;
    reg [31:0] counter;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == 32_000_00) begin
            l <= 1;
        end
        if (counter == 64_000_00) begin
            l <= 0;
            counter <= 0;
        end
    end
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////

    reg trigger = 0;
    reg prev_btn = 0;
    always @ (posedge clk) begin
        trigger <= 0;
        if (prev_btn == 1 && ~btn[0] == 0) begin
            trigger <= 1;
        end
        prev_btn <= ~btn[0];
    end
    //// UART Setup ////////////////////////////////////////////////////
    // TX Wires
    wire tx;
    wire reset = ~btn[2];
    wire tx_start = ~btn[0];

    //// Baud Rate ////////////////////////////////////////////////////
    wire tick; // = ~btn[1];                  // sample tick from baud rate generator
    // Instantiate Modules for UART Core
    baud_rate_generator 
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
         ) 
        BAUD_RATE_GEN   
        (
            .clk_100MHz(clk), 
            .reset(reset),
            .tick(tick)
         );
    //// Transmitter /////////////////////////////////////////////////
    wire [1:0] state_out;
    wire tx_done_tick;                  // data transmission complete
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
            .tx_start(tx_start), //tx_send),
            .data_in(8'd65), //tx_fifo_out),
            .tx_done(tx_done_tick), 
            .state_out(state_out)
         );

    assign interconnect[1] = tx;
    assign led = (~btn[4] ? 
        btn :
        (~btn[3] ? 
            rx_out :
            {2'b11, state_out, 2'b11, tick, tx}
        )
    );

endmodule

/*
def func():
    d = 1
    while d is not None:
        d = uart.read(4)
        print("a", d)
import hardware.fpga
hardware.fpga.upload_bitstream("test.bit")
import board
import busio
import time

# Set up UART with the appropriate TX and RX pins and baudrate
uart = busio.UART(board.GP8, board.GP9, baudrate=9600, timeout=0.1)
*/
