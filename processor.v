module processor(input CLOCK_50);
//					  output reg [4:0] pc,
//					  output [31:0] instr,
//					  output [4:0] rr1,
//					  output [4:0] rr2,
//					  output [31:0] rd1,
//					  output [31:0] rd2,
//					  output [4:0] w,
//					  output [31:0] alu_res,
//					  output [31:0] wd,
//					  output reg_wrenable,
//					  output mem_wrenable,
//					  output reg [31:0] alu_src,
//					  output reg [4:0] alu_op,
//					  output [7:0] mem_addr,
//					  output [31:0] mem_res,
//					  output halt);


reg [4:0] pc; // program counter
wire [31:0] instr; // current instruction
reg halt;

initial begin
	pc = 0;
	halt = 0;
end

always @(posedge clock) begin
	pc <= halt ? pc : pc + 1'b1;
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

// control unit: set flags based on opcode
always @* begin
	halt = 1'b0;
	reg_wrenable = 1'b0;
	mem_wrenable = 1'b0;
	alu_src = rd2;
	alu_op = 5'd0;
	wd = alu_res;
	
	case (instr[6:0])
	7'b1111111: halt = 1'b1;
	7'b0100011: begin // s-type
		alu_src = {instr[31:25], instr[11:7]};
		mem_wrenable = 1'b1;
	end
	7'b0010011: begin // i-type
		alu_op = {2'd0, instr[14:12]};
		alu_src = instr[31:20];
		reg_wrenable = 1'b1;
	end
	7'b0000011: begin // load
		alu_src = instr[31:20];
		reg_wrenable = 1'b1;
		wd = mem_res;
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