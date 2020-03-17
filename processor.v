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


// TODO: fix control unit
// TODO: clock on real board

reg [4:0] pc; // program counter
wire [31:0] instr; // current instruction

wire [4:0] rr1; // read reg 1
wire [4:0] rr2; // read reg 2
wire reg_wrenable; // write enable
wire [4:0] w; // write reg
wire [31:0] wd; // write data
wire [31:0] rd1; // read data 1
wire [31:0] rd2; // read data 2

initial begin
	pc = 0;
end

reg [31:0] alu_src;
wire [31:0] alu_res;
wire mem_wrenable;
wire [31:0] mem_res;

wire halt;
assign halt = instr[6:0] == 7'b1111111;

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

// instantiate alu
// if load or store, use add; else, use combo of f3 and f7
// TODO: make switch on instr-type; have separate block that assigns all vals based
// on instr-type flag

reg [4:0] alu_op;
always @* begin
	case (instr[6:0])
	7'b0010011: alu_op = {2'd0, instr[14:12]};
	7'b0110011: alu_op = {instr[30], instr[25], instr[14:12]};
	default: alu_op = 5'd0;
	endcase
end
alu alu(.opc(alu_op), .op1(rd1),
		  .op2(alu_src), .res(alu_res));

// instantiate data memory
// write enabled only on stores
wire [7:0] mem_addr;
assign mem_addr = alu_res[9:2];
ram ram(.address(mem_addr), .clock(mem_clk), .data(rd2), .wren(mem_wrenable), .q(mem_res));

always @(posedge clock) begin
	pc <= halt ? pc : pc + 1'b1;
end

// if r-type, then use rd2
// if i-type or load, then use 12-bit immediate
// if s-type, then use 12-bit immediate (in diff locations)
always @* begin
	case (instr[6:0])
	7'b0010011, 7'b0000011: alu_src = instr[31:20]; // i-type and load
	7'b0100011: alu_src = {instr[31:25], instr[11:7]}; // s-type
	default: alu_src = rd2; // r-type
	endcase
end

assign rr1 = instr[19:15];
assign rr2 = instr[24:20];
assign w   = instr[11:7];

// regwrite: only write to regfile when load, i-type, or r-type
assign reg_wrenable = instr[6:0] == 7'b0110011 || instr[6:0] == 7'b0010011 || instr[6:0] == 7'd3;

// memwrite: only write to data mem on store instrs
assign mem_wrenable = instr[6:0] == 7'b0100011;

// memtoreg: only copy data mem to regs on loads; otherwise use alu result
assign wd = instr[6:0] == 7'd3 ? mem_res : alu_res;

endmodule