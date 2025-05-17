module top(input clk, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 4;
    //// UART Setup ////////////////////////////////////////////////////
    // RX Wires
    wire rx = interconnect[1];
    wire [UART_FRAME_SIZE*DBITS-1:0] rx_out;
    wire rx_full, rx_empty, rx_tick;
    
    // TX Wires
    wire tx;

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
            //.write_data(rec_data),
            .reset(~btn[1]),
            
            .rx(rx),
            .tx(tx),
            
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .rx_tick(rx_tick),
            .rx_out(rx_out),
            
            .tx_trigger(~btn[0]),
            .tx_in({8'd65, 8'd65, 8'd65, 8'd65})
        );

    reg t=0;
    always @(posedge clk) begin
        // send A__B
        if (rx_out[7:0] == 65 & rx_out[DBITS*UART_FRAME_SIZE-1:DBITS*(UART_FRAME_SIZE-1)] == 65) begin
            t <= 1;
        end
        if (rx_out[7:0] == 67 & rx_out[DBITS*UART_FRAME_SIZE-1:DBITS*(UART_FRAME_SIZE-1)] == 67) begin
            t <= 0;
        end
    end

    
    assign interconnect[0] = tx;
    assign led = {6'hf0f, t, btn[0], ~tx};

endmodule
