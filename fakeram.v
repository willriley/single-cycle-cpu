module fakeram(input [4:0] address,
					input clock,
					input [31:0] data,
					input wren,
					output reg [31:0] q);

reg [31:0] ram [0:31];

always @(posedge clock) begin
	if (wren) begin
		ram[address] <= data;
		q <= data;
	end
	else q <= ram[address];
end			
		
endmodule