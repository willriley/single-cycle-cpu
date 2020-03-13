module regfile(input clk,
					input [4:0] read_reg1,
					input [4:0] read_reg2,
					input [4:0] write_reg,
					input [31:0] write_data,
					input write_enable,
					output [31:0] read_data1,
					output [31:0] read_data2);
			
reg [31:0] regs[0:31]; // 32x32 bit array
initial begin
	regs[0] = 0;
end

// reading is combinational
assign read_data1 = regs[read_reg1];
assign read_data2 = regs[read_reg2];
	
// writing is sequential	
always @(posedge clk) begin
	if (write_enable) regs[write_reg] <= write_data;
end
					
endmodule