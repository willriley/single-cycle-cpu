module instruction_rom(input [4:0] addr, output reg [31:0] instr);

always @* begin
	case (addr)
	5'd0: instr = 32'h00f00093;  // addi x1, x0, 15
	5'd1: instr = 32'h00f00113;  // addi x2, x0, 15
	5'd2: instr = 32'h00208663;  // beq x1, x2, 12
	5'd3: instr = 32'h00202023;  // sw x2 0(x0)
	5'd4: instr = 32'hffff_ffff; // halt
	5'd5: instr = 32'h04500093;  // addi x1, x0, 69
	5'd6: instr = 32'h00102023;  // sw x1, 0(x0)
//	5'd7: instr = 32'h00002183;  // lw x3, 0(x0)
	default: instr = 32'hffff_ffff; // halt
	endcase
end

endmodule