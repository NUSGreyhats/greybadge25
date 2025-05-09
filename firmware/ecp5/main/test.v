module top(input clk, input [4:0] btn, output [7:0] led, output [7:0] interconnect);
    reg [7:0] shooting = 8'b101;
    reg [31:0] counter;
    always @ (posedge clk) begin
        counter <= counter + 1;
        if (counter == 32_000_00/20) begin
            shooting <= shooting << 1 | shooting[7];
            counter <= 0;
        end
    end

    /// UART ////////////////////////////////////////////////////////////
    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 4;
    //// UART Setup ///////////////
    wire  btn_tick;
    wire [7:0] rec_data, rec_data1;
    
    wire [UART_FRAME_SIZE*DBITS-1:0] tx_fifo_out;
    
    wire [UART_FRAME_SIZE*DBITS-1:0] rx_out;
    wire rx_full, rx_empty, rx_tick;
    // Complete UART Core
    uart_top 
        #(
            .FIFO_IN_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE_EXP(32)
        ) 
        UART_UNIT
        (
            .clk_100MHz(clk_100MHz),
            .write_data(rec_data1),
            
            .rx(rx),
            .tx(tx),
            
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .rx_tick(rx_tick),
            .rx_out(rx_out),
            
            .tx_trigger(btn),
            .tx_in({8'd65, 8'd65, 8'd65, 8'd65})
        );
    //////////////////////////////////////////////////////////////

    assign led = ~btn[0] ? btn : shooting;
    assign interconnect = {3'b111, btn};
endmodule
