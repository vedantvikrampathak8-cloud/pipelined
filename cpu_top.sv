module cpu_top (
    input logic clk,
    input logic rst_n
);
logic [31:0] pc;
logic jalr;
logic [31:0] next_pc;
logic [31:0] instruction;
logic [6:0] opcode;
logic [4:0] rd;
logic [2:0] funct3;
logic [4:0] rs1;
logic [4:0] rs2;
logic [6:0] funct7;
logic [31:0] read_data1;
logic [31:0] read_data2;
logic [31:0] immediate;
logic reg_write;
logic [1:0] wb_sel;
logic mem_read;
logic mem_write;
logic branch;
logic jump;
logic [1:0] alu_src_a_sel;
logic [1:0] alu_src_b_sel;
logic [1:0] alu_op;
logic [4:0] alu_control_signal;
logic [31:0] alu_a;
logic [31:0] alu_b;
logic [31:0] alu_result;
logic zero;
logic branch_taken;
logic [31:0] mem_read_data;
logic [31:0] writeback_data;
logic [31:0] pc_plus4;
assign pc_plus4 = pc + 32'd4;
pc pc_inst(
    .clk(clk),
    .rst_n(rst_n),
    .pc_write(1'b1),
    .next_pc(next_pc),
    .pc(pc)
);
next_pc_logic next_pc_logic_inst(
    .pc(pc),
    .immediate(immediate),
    .alu_result(alu_result),
    .branch(branch),
    .branch_taken(branch_taken),
    .jump(jump),
    .jalr(jalr),
    .next_pc(next_pc)
);
instr_mem instr_mem_inst(
    .addr(pc),
    .instruction(instruction)
);
decoder decoder_inst(
    .instruction(instruction),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
);
register_file register_file_inst(
    .rd(rd),
    .clk(clk),
    .write_data(writeback_data),
    .we(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .read_data1(read_data1),
    .read_data2(read_data2)
);
imm_gen imm_gen_inst(
    .instruction(instruction),
    .immediate(immediate)
);
control_unit control_unit_inst(
    .opcode(opcode),
    .reg_write(reg_write),
    .wb_sel(wb_sel),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),
    .alu_src_a_sel(alu_src_a_sel),
    .alu_src_b_sel(alu_src_b_sel),
    .alu_op(alu_op),
    .jalr(jalr)
);
alu_control alu_control_inst(
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_control(alu_control_signal)
);
alu_src_mux alu_src_mux_inst(
    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .imm(immediate),
    .pc(pc),
    .old_pc(pc), // single-cycle: pc never increments mid-instruction, so old_pc == pc here
    .alu_src_a_sel(alu_src_a_sel),
    .alu_src_b_sel(alu_src_b_sel),
    .alu_a(alu_a),
    .alu_b(alu_b)
);
alu alu_inst(
    .operand_a(alu_a),
    .operand_b(alu_b),
    .alu_control(alu_control_signal),
    .result(alu_result),
    .zero(zero)
);
branch_comparator branch_comparator_inst(
    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .funct3(funct3),
    .branch_taken(branch_taken)
);
data_mem data_mem_inst(
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .addr(alu_result),
    .write_data(read_data2),
    .read_data(mem_read_data)
);
writeback_mux writeback_mux_inst(
    .alu_result(alu_result),
    .mem_data(mem_read_data),
    .pc_plus4(pc_plus4),
    .wb_sel(wb_sel),
    .writeback_data(writeback_data)
);
endmodule