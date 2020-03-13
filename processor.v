module processor(input CLOCK_50,
					  output reg [4:0] pc,
					  output [31:0] instr,
					  output reg [4:0] rd1,
					  output reg [4:0] rd2,
					  output [31:0] rr1,
					  output [31:0] rr2,
					  output reg [4:0] w,
					  output [31:0] alu_res,
					  output [31:0] wd,
					  output reg_wrenable,
					  output mem_wrenable,
					  output [31:0] alu_src,
					  output [31:0] mem_res);
// TODO: add instruction ROM, reg file, data RAM, control unit

//reg [4:0] pc;
//reg [4:0] rd1;
//reg [4:0] rd2;
//reg [4:0] w;

//wire [31:0] instr;
//wire [31:0] rr1;
//wire [31:0] rr2;
//wire [31:0] alu_res;
//wire [31:0] wd;

initial begin
	pc = 0;
	rd1 = 0;
	rd2 = 0;
	w = 0;
end

//wire reg_wrenable;
//wire mem_wrenable;
//wire [31:0] alu_src;
//wire [31:0] mem_res;

// connect to reg file
regfile rf(.clk(CLOCK_50), .read_reg1(rd1), .read_reg2(rd2),
   		  .write_reg(w), .write_data(wd), .write_enable(reg_wrenable),
			  .read_data1(rr1), .read_data2(rr2));
				
// instantiate instruction memory
instruction_rom rom(pc, instr);

// instantiate data memory
// write enabled only on stores

wire mem_clk;
assign mem_clk = ~CLOCK_50;

fakeram ram(.address(alu_res[4:0]), .clock(CLOCK_50), .data(rr2), .wren(mem_wrenable), .q(mem_res));

always @(posedge CLOCK_50) begin
	if (pc < 5'd8) pc <= pc + 1'b1;
	else pc <= pc;
end

always @* begin
	rd1 = instr[19:15];
	rd2 = instr[24:20];
	w   = instr[11:7];
end

// if r-type, then use rr2
// if i-type, then use 12-bit immediate
// if s-type, then use 12-bit immediate (in diff locations)
assign alu_src = instr[6:0] == 7'b0110011 ? rr2 : (instr[6:0] == 7'b0010011 ? instr[31:20] : {instr[31:25], instr[11:7]});

// shitty alu for now
// check opcode for add or addi
assign alu_res = rr1 + alu_src;

// regwrite: only write to regfile when load, i-type, or r-type
// TODO: change when adding loads
assign reg_wrenable = instr[6:0] == 7'b0110011 || instr[6:0] == 7'b0010011;

// memwrite: only write to data mem on store instrs
assign mem_wrenable = instr[6:0] == 7'b0100011;

// memtoreg: only copy data mem to regs on loads
// TODO: change when adding loads
assign wd = alu_res;

endmodule