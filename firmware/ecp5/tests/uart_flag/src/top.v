module top(input clk, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 18;

    wire reset = ~btn[2];

    wire rx;
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
            
            .rx(interconnect[0]),
            .tx(tx),
            
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .rx_out(rx_out),
            
            .tx_trigger(~btn[0]),
            .tx_in({8'h7b, 8'h68, 8'h69, 8'h5f, 8'h69, 8'h27, 8'h6d, 8'h5f, 8'h79, 8'h6f, 8'h75, 8'h72, 8'h5f, 8'h61, 8'h72, 8'h6d, 8'h79, 8'h7d})
        );

    // https://gchq.github.io/CyberChef/#recipe=To_Hex('Space',0)Find_/_Replace(%7B'option':'Regex','string':'%20'%7D,',%208%5C'h',true,false,true,false)&input=e2hpX2knbV95b3VyX2FybXl9
    assign interconnect[1] = tx;
    assign led = (~btn[4] ? 
        btn :
        (~btn[3] ? 
            rx_out :
            {2'b11, state_out, interconnect[0], rx_out[7:0] == 65,  ~btn[0], tx}
        )
    );

endmodule
