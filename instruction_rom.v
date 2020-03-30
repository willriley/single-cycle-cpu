module instruction_rom(input [4:0] addr, output reg [31:0] instr);

always @* begin
	case (addr)
	5'd0: instr = 32'h00600513;
	5'd1: instr = 32'h00c000ef;
	5'd2: instr = 32'h00a02023;
	5'd3: instr = 32'hffffffff; 
	5'd4: instr = 32'hff810113;
	5'd5: instr = 32'h00112223;
	5'd6: instr = 32'h00a12023;
	5'd7: instr = 32'hfff50513;  
	5'd8: instr = 32'h00051863;  
	5'd9: instr = 32'h00100513;  
	5'd10: instr = 32'h00810113;  
	5'd11: instr = 32'h00008067;  
	5'd12: instr = 32'hfe1ff0ef;  
	5'd13: instr = 32'h00050293;  
	5'd14: instr = 32'h00012503;  
	5'd15: instr = 32'h00412083;  
	5'd16: instr = 32'h00810113;  
	5'd17: instr = 32'h02550533;  
	5'd18: instr = 32'h00008067;  
	default: instr = 32'hffff_ffff; // halt
	endcase
end

endmodule