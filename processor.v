module processor(input CLOCK_50);
//					  output reg [4:0] pc,
//					  output [31:0] instr,
//					  output [4:0] rr1,
//					  output [4:0] rr2,
//					  output [31:0] rd1,
//					  output [31:0] rd2,
//					  output [4:0] w,
//					  output [31:0] alu_res,
//					  output reg [31:0] wd,
//					  output reg reg_wrenable,
//					  output reg mem_wrenable,
//					  output reg [31:0] alu_src,
//					  output reg [4:0] alu_op,
//					  output [7:0] mem_addr,
//					  output [31:0] mem_res,
//					  output reg halt);

// TODO: add instruction ROM; create control module; increase clock speed

parameter HALT = 7'b1111111;
parameter LOAD = 7'b0000011;
parameter STORE = 7'b0100011;
parameter ITYPE = 7'b0010011;
parameter BTYPE = 7'b1100011;
parameter RTYPE = 7'b0010011;

reg [4:0] pc; // program counter
wire [31:0] instr; // current instruction
reg halt;

initial begin
	pc = 0;
	halt = 0;
end

always @(posedge clock) begin
	if (halt) pc <= pc;
	else begin
		// increment pc by 1 if instr isn't a branch
		// and the condition isn't met
		if (instr[6:0] != BTYPE || !instr[12] && alu_res || instr[12] && !alu_res) begin
			pc <= pc + 1'b1;
		end
		else pc <= pc + imm;
	end
end

// register file ports
wire [4:0] rr1; // read reg 1
wire [4:0] rr2; // read reg 2
reg reg_wrenable; // write enable
wire [4:0] w; // write reg
reg [31:0] wd; // write data
wire [31:0] rd1; // read data 1
wire [31:0] rd2; // read data 2

// alu ports
reg [4:0] alu_op;
reg [31:0] alu_src;
wire [31:0] alu_res;

// data memory ports
reg mem_wrenable;
wire [31:0] mem_res;

wire clock;
pll pll(CLOCK_50, clock);

// 180 phase shift for memory clock
wire mem_clk;
assign mem_clk = ~clock;

// connect to reg file
regfile rf(.clk(clock), .read_reg1(rr1), .read_reg2(rr2),
   		  .write_reg(w), .write_data(wd), .write_enable(reg_wrenable),
			  .read_data1(rd1), .read_data2(rd2));
				
// instantiate instruction memory
instruction_rom rom(pc, instr);

// immediate generator
reg [31:0] imm; 
always @* begin
	case (instr[6:0])
	STORE: imm = {instr[31:25], instr[11:7]};
	LOAD, ITYPE: imm = instr[31:20];
	BTYPE: imm = {instr[31], instr[7], instr[30:25], instr[11:9]};
	default: imm = 0;
	endcase	
end

// control unit: set flags based on opcode
always @* begin
	halt = 1'b0;
	reg_wrenable = 1'b0;
	mem_wrenable = 1'b0;
	alu_src = rd2;
	alu_op = 5'd0;
	wd = alu_res;
	
	case (instr[6:0])
	HALT: halt = 1'b1;
	STORE: begin // s-type
		alu_src = imm;
		mem_wrenable = 1'b1;
	end
	ITYPE: begin // i-type
		alu_op = {2'd0, instr[14:12]};
		alu_src = imm;
		reg_wrenable = 1'b1;
	end
	LOAD: begin // load
		alu_src = imm;
		reg_wrenable = 1'b1;
		wd = mem_res;
	end
	BTYPE: begin // b-type
		alu_op = 5'b10000; // subtraction
	end
	default: begin // r-type
		alu_op = {instr[30], instr[25], instr[14:12]};
		reg_wrenable = 1'b1;
	end
	endcase
end


// instantiate alu
alu alu(.opc(alu_op), .op1(rd1),
		  .op2(alu_src), .res(alu_res));

wire [7:0] mem_addr;
assign mem_addr = alu_res[9:2];

// instantiate data memory
// write enabled only on stores
ram ram(.address(mem_addr), .clock(mem_clk), .data(rd2), .wren(mem_wrenable), .q(mem_res));

assign rr1 = instr[19:15];
assign rr2 = instr[24:20];
assign w   = instr[11:7];

endmodule