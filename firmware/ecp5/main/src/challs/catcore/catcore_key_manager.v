module catcore_key_manager(input clk, input [4:0] address, output reg [7:0] value);
	// memory retrieval
	always @ (posedge clk) begin
		value <= (
			address == 5'd0 ? "g" :
			address == 5'd1 ? "r" :
			address == 5'd2 ? "e" :
			address == 5'd3 ? "y" :
			address == 5'd4 ? "{" :
			address == 5'd5 ? "r" :
			address == 5'd6 ? "a" :
			address == 5'd7 ? "c" :
			address == 5'd8 ? "e" :
			address == 5'd9 ? "_" :
			address == 5'd10 ? "f" :
			address == 5'd11 ? "l" :
			address == 5'd12 ? "a" :
			address == 5'd13 ? "g" :
			address == 5'd14 ? "}" :
			address == 5'd31 ? "L" :
			0
		);
	end
endmodule
