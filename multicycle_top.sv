import riscv_pkg::*;
module multicycle_top (
    input logic clk,
    input logic rst_n
);
logic pc_write, ir_write, a_write, b_write, aluout_write, mdr_write;
logic reg_write, mem_read, mem_write;
logic [1:0] alu_src_a_sel, alu_src_b_sel, wb_sel, pc_src;
logic [6:0] opcode, funct7;
logic [2:0] funct3;
logic zero, branch_taken;
state_t state; // exposed for waveform/debug visibility, not otherwise used here
mc_control_unit control_unit_inst (
    .clk(clk),
    .rst_n(rst_n),
    .opcode(opcode),
    .zero(zero),
    .branch_taken(branch_taken),
    .pc_write(pc_write),
    .ir_write(ir_write),
    .a_write(a_write),
    .b_write(b_write),
    .aluout_write(aluout_write),
    .mdr_write(mdr_write),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .alu_src_a_sel(alu_src_a_sel),
    .alu_src_b_sel(alu_src_b_sel),
    .wb_sel(wb_sel),
    .pc_src(pc_src),
    .state(state)
);
multicycle_datapath datapath_inst (
    .clk(clk),
    .rst_n(rst_n),
    .pc_write(pc_write),
    .ir_write(ir_write),
    .a_write(a_write),
    .b_write(b_write),
    .aluout_write(aluout_write),
    .mdr_write(mdr_write),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .alu_src_a_sel(alu_src_a_sel),
    .alu_src_b_sel(alu_src_b_sel),
    .wb_sel(wb_sel),
    .pc_src(pc_src),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .zero(zero),
    .branch_taken(branch_taken)
);
endmodule