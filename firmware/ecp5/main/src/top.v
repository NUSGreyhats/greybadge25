module top(input clk, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    // Regular Shooting
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
    parameter UART_FRAME_SIZE = 18;

    wire reset = ~btn[2];

    wire rx; // 
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
    //////////////////////////////////////////////////////////////

    //// Shooting Cats /////////////////////////////////////////////////
    reg [7:0] cat_status = 8'b11111111;
    always @ (posedge clk) begin
        if (65 <= rx_out[7:0] <= 65+7) begin
            cat_status[rx_out[7:0]] = 0;
        end
    end 

    
    assign led = ~btn[0] ? mode : shooting; // & cat_status;


    parameter MODE_BUTTON = 3'b000;
    parameter MODE_UART = 3'b001;

    wire [2:0] mode = interconnect[7:5];
    assign interconnect[4:0] = (
        mode == MODE_BUTTON ? {btn} : 
        mode == MODE_UART ? {3'bzzz, tx, 1'bz} : 
        5'bzzzzz
    );
    assign rx = (mode == MODE_UART ? interconnect[0] : 1'bx);
endmodule
