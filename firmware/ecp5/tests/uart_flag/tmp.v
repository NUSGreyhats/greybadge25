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
            .reset(1),
            
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
    assign led = (~btn[4] ? 
        rx_out :
        btn
    );

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
// Authored by: Dr. Pong P. Chu
// Published by: Wiley
//
// Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
//
// Baud Rate Generator for the UART System
//
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////

module baud_rate_generator
    #(              // 9600 baud
        parameter   N = 10,     // number of counter bits
                    M = 651     // counter limit value
    )
    (
        input clk_100MHz,       // basys 3 clock
        input reset,            // reset
        output tick             // sample tick
    );
    
    // Counter Register
    reg [N-1:0] counter;        // counter value
    wire [N-1:0] next;          // next counter value
    
    // Register Logic
    always @(posedge clk_100MHz, posedge reset)
        if(reset)
            counter <= 0;
        else
            counter <= next;
            
    // Next Counter Value Logic
    assign next = (counter == (M-1)) ? 0 : counter + 1;
    
    // Output Logic
    assign tick = (counter == (M-1)) ? 1'b1 : 1'b0;
       
endmodule
`timescale 1ns /1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Reference book:
// "FPGA Prototyping by Verilog Examples"
// "Xilinx Spartan-3 Version"
// Dr. Pong P. Chu
// Wiley
//
// Adapted for Artix-7
// David J. Marion
//
// Parameterized FIFO Unit for the UART System
// 
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////////////

// Modified to basically become a shift register
 module fifo_shift
	#(
	   parameter	DATA_SIZE  = 8,	       // number of bits in a data word
				    ADDR_SPACE = 4	           // number of addresses
	)
	(
	   input clk,                              // FPGA clock           
	   input reset,                            // reset button
	   
       input write_to_fifo,                    // signal start writing to FIFO
	   input [DATA_SIZE-1:0] write_data_in,    // data word into FIFO
       
       input write_batch_to_fifo,              // signal start writing to FIFO
       input [(DATA_SIZE * ADDR_SPACE)-1:0] write_batch_data_in,       // data word into FIFO
       
       input shift,
       
	   output [DATA_SIZE-1:0] read_data_out,   // first word into FIFO
       output [DATA_SIZE-1:0] read_data_out_last,   // last word out of FIFO
	   output [(DATA_SIZE * ADDR_SPACE)-1:0] read_all_data_out,
	   output reg tick
);

	// signal declaration
	reg [(DATA_SIZE * ADDR_SPACE)-1:0] memory;		// memory array register
	reg fifo_full, fifo_empty, full_buff, empty_buff;
    
    wire [(DATA_SIZE * ADDR_SPACE)-1:0]shifted_memory = memory << DATA_SIZE; // auto truncated
    
    reg past_shift = 0;
	// register file (memory) write operation
	always @(posedge clk) begin
	    tick <= 1'b0;
        if(write_batch_to_fifo) begin
            memory <= write_batch_data_in;
			tick = 1'b1;
		end
		if(write_to_fifo || (shift != past_shift && shift == 1)) begin // Shift operation
		    memory <= shifted_memory | write_data_in ;  // Make space for new byte
			tick <= 1'b1;
		end 
        past_shift <= shift;
    end
    
	// register file (memory) read operation
	assign read_data_out = memory[DATA_SIZE-1:0];
	assign read_data_out_last = memory[(DATA_SIZE * ADDR_SPACE)-1:(DATA_SIZE * (ADDR_SPACE-1))];
	assign read_all_data_out = memory;
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
// Authored by: Dr. Pong P. Chu
// Published by: Wiley
//
// Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
//
// UART Receiver for the UART System
//
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////

module uart_receiver
    #(
        parameter   DBITS = 8,          // number of data bits in a data word
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk_100MHz,               // basys 3 FPGA
        input reset,                    // reset
        input rx,                       // receiver data line
        input sample_tick,              // sample tick from baud rate generator
        output reg data_ready,          // signal when new data word is complete (received)
        output [DBITS-1:0] data_out     // data to FIFO
    );
    
    // State Machine States
    localparam [1:0] idle  = 2'b00,
                     start = 2'b01,
                     data  = 2'b10,
                     stop  = 2'b11;
    
    // Registers                 
    reg [1:0] state, next_state;        // state registers
    reg [3:0] tick_reg, tick_next;      // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;    // number of bits received in data state
    reg [7:0] data_reg, data_next;      // reassembled data word
    
    // Register Logic
    always @(posedge clk_100MHz, posedge reset)
        if(reset) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
        end        

    // State Machine Logic
    always @* begin
        next_state = state;
        data_ready = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        
        case(state)
            idle:
                if(~rx) begin               // when data line goes LOW (start condition)
                    next_state = start;
                    tick_next = 0;
                end
            start:
                if(sample_tick)
                    if(tick_reg == 7) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            data:
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = {rx, data_reg[7:1]};
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            stop:
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        data_ready = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
        endcase                    
    end
    
    // Output Logic
    assign data_out = data_reg;

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
// Authored by: Dr. Pong P. Chu
// Published by: Wiley
//
// Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
//
// Top Module for the Complete UART System
//
// Setup for 9600 Baud Rate
//
// For 9600 baud with 100MHz FPGA clock: 
// 9600 * 16 = 153,600
// 100 * 10^6 / 153,600 = ~651      (counter limit M)
// log2(651) = 10                   (counter bits N) 
//
// For 19,200 baud rate with a 100MHz FPGA clock signal:
// 19,200 * 16 = 307,200
// 100 * 10^6 / 307,200 = ~326      (counter limit M)
// log2(326) = 9                    (counter bits N)
//
// For 115,200 baud with 100MHz FPGA clock:
// 115,200 * 16 = 1,843,200
// 100 * 10^6 / 1,843,200 = ~52     (counter limit M)
// log2(52) = 6                     (counter bits N) 
//
// For 1500 baud with 100MHz FPGA clock:
// 1500 * 16 = 24,000
// 100 * 10^6 / 24,000 = ~4,167     (counter limit M)
// log2(4167) = 13                  (counter bits N) 

// For 460800 baud with 100MHz FPGA clock:
// 460800 * 16 = 7372800
// 100 * 10^6 / 7372800 = ~13.5633680556     (counter limit M)
// log2(14) = 4                    (counter bits N) 
//

// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////

module uart_top
    #(
        parameter   
            // UART Params
            DBITS = 8,          // number of data bits in a word
            SB_TICK = 16,       // number of stop bit / oversampling ticks
            
            // Baud Rate
            //BR_LIMIT = 14,     // baud rate generator counter limit
            //BR_BITS = 4,       // number of baud rate generator counter bits
            // 9600
            BR_LIMIT = 208,     // baud rate generator counter limit
            BR_BITS = 9,       // number of baud rate generator counter bits
            
            // Size
            FIFO_IN_SIZE = 4,        
            FIFO_OUT_SIZE = 4, 
            FIFO_OUT_SIZE_EXP = 32
    )
    (
        // General
        input clk_100MHz,               // FPGA clock
        input reset,                    // reset
        
        input [DBITS-1:0] write_data,   // data from Tx FIFO
        
        // Serial ports
        input rx,               // USB-RS232 Rx
        output tx,              // USB-RS232 Tx
    
        // Receiving
        output rx_full,                 // do not write data to FIFO
        output rx_empty,                // no data to read from FIFO
        output [DBITS*FIFO_IN_SIZE - 1:0] rx_out,
        output rx_tick,
        
        // Debugging
        output [DBITS*FIFO_OUT_SIZE - 1:0] tx_fifo_out,
        
        // Sending
        input tx_trigger,
        input [DBITS*FIFO_OUT_SIZE -1 :0] tx_in //2**FIFO_EXP_IN) -  1
    );
    
    // Connection Signals
    wire tick;                          // sample tick from baud rate generator
    // Instantiate Modules for UART Core
    baud_rate_generator 
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
         ) 
        BAUD_RATE_GEN   
        (
            .clk_100MHz(clk_100MHz), 
            .reset(reset),
            .tick(tick)
         );
    
    // UART Receiver ///////////////////////////////////////////////////
    wire rx_done_tick;                  // data word received
    wire [DBITS-1:0] rx_data_out;       // from UART receiver to Rx FIFO
    uart_receiver
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_RX_UNIT
         (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .rx(rx),
            .sample_tick(tick),
            
            .data_ready(rx_done_tick),
            .data_out(rx_data_out)
         );
    // above working
    
    fifo_shift
         #(
             .DATA_SIZE(DBITS),
             .ADDR_SPACE(FIFO_IN_SIZE)
          )
          FIFO_RX_UNIT
          (
             .clk(clk_100MHz),
             .write_to_fifo(rx_done_tick),
             .write_data_in(rx_data_out),
             .write_batch_to_fifo(0),
             .write_batch_data_in(0),
             .read_all_data_out(rx_out),
             .tick(read_tick)  
           );
    
    // UART Transmitter ////////////////////////////////////////////////
    
    wire tx_empty;                      // Tx FIFO has no data to transmit
    wire tx_fifo_not_empty;             // Tx FIFO contains data to transmit
    //wire [DBITS-1:0] tx_fifo_out;       // from Tx FIFO to UART transmitter
    
    fifo_shift
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE(FIFO_OUT_SIZE)
         )
         FIFO_TX_UNIT
         (
             .clk(clk_100MHz),
             .write_to_fifo(0),
             .write_data_in(0),
             .write_batch_to_fifo(tx_trigger),
             .write_batch_data_in(tx_in),
             .shift(tx_done_tick),
             .read_data_out_last(tx_fifo_out),
             .tick(read_tick)  
           );
    
    reg [FIFO_OUT_SIZE_EXP-1:0] count = 0;
    wire tx_done_tick;                  // data transmission complete
    reg tx_done_tick_latch = 0;
    wire tx_send = count != 0 & ~tx_trigger;
    uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_TX_UNIT
         (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .tx(tx),
            .sample_tick(tick),
            .tx_start(tx_trigger), //tx_send),
            .data_in(8'd65), //tx_fifo_out),
            .tx_done(tx_done_tick)
         );
    
    always @(posedge clk_100MHz) begin
         if (tx_trigger) begin
            count <= FIFO_OUT_SIZE; // Edge
        // Debug this part
         end else if (tx_done_tick != tx_done_tick_latch && tx_done_tick && count != 0) begin
            count <= count - 1;
         end
         tx_done_tick_latch <= tx_done_tick;
    end
    //////////////////////////////////////////////
    
    /*
    fifo
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_RX_UNIT
         (
            .clk(clk_100MHz),
            .reset(reset),
            .write_to_fifo(rx_done_tick),
	        .read_from_fifo(read_uart),
	        .write_data_in(rx_data_out),
	        .read_data_out(read_data),
	        .empty(rx_empty),
	        .full(rx_full)            
	      );
	   
    fifo
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_TX_UNIT
         (
            .clk(clk_100MHz),
            .reset(reset),
            .write_to_fifo(write_uart),
	        .read_from_fifo(tx_done_tick),
	        .write_data_in(write_data),
	        .read_data_out(tx_fifo_out),
	        .empty(tx_empty),
	        .full()                // intentionally disconnected
	      );
    
    // Signal Logic
    assign tx_fifo_not_empty = ~tx_empty;
    */
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
// Authored by: Dr. Pong P. Chu
// Published by: Wiley
//
// Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
//
// UART Transmitter for the UART System
//
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////

module uart_transmitter
    #(
        parameter   DBITS = 8,          // number of data bits
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk_100MHz,               // basys 3 FPGA
        input reset,                    // reset
        input tx_start,                 // begin data transmission (FIFO NOT empty)
        input sample_tick,              // from baud rate generator
        input [DBITS-1:0] data_in,      // data word from FIFO
        output reg tx_done,             // end of transmission
        output tx                       // transmitter data line
    );
    
    // State Machine States
    localparam [1:0]    idle  = 2'b00,
                        start = 2'b01,
                        data  = 2'b10,
                        stop  = 2'b11;
    
    // Registers                    
    reg [1:0] state, next_state;            // state registers
    reg [3:0] tick_reg, tick_next;          // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;        // number of bits transmitted in data state
    reg [DBITS-1:0] data_reg, data_next;    // assembled data word to transmit serially
    reg tx_reg, tx_next;                    // data filter for potential glitches
    
    // Register Logic
    always @(posedge clk_100MHz, posedge reset)
        if(reset) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
            tx_reg <= 1'b1;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
            tx_reg <= tx_next;
        end
    
    // State Machine Logic
    always @* begin
        next_state = state;
        tx_done = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        tx_next = tx_reg;
        
        case(state)
            idle: begin                     // no data in FIFO
                tx_next = 1'b1;             // transmit idle
                if(tx_start) begin          // when FIFO is NOT empty
                    next_state = start;
                    tick_next = 0;
                    data_next = data_in;
                end
            end
            
            start: begin
                tx_next = 1'b0;             // start bit
                if(sample_tick)
                    if(tick_reg == 15) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            data: begin
                tx_next = data_reg[0];
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = data_reg >> 1;
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            stop: begin
                tx_next = 1'b1;         // back to idle
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        tx_done = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
        endcase    
    end
    
    // Output Logic
    assign tx = tx_reg;
 
endmodule