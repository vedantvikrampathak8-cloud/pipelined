import riscv_pkg::*;

module pipeline_top(
    input logic clk,
    input logic rst_n
);

//IF
logic [31:0] pc, next_pc, pc_plus4_if, if_instruction;
logic stall_id, flush_ex;

pc pc_inst(.clk(clk), .rst_n(rst_n), .pc_write(1'b1), .next_pc(next_pc), .pc(pc));
instr_mem instr_mem_inst(.addr(pc), .instruction(if_instruction));
assign pc_plus4_if = pc + 32'd4;

logic [31:0] flush_target;
always_comb begin
    if (flush_ex) next_pc = flush_target;// taken branch/jump wins over everything
    else if (stall_id) next_pc = pc;// load-use stall: hold, refetch same instruction
    else next_pc = pc_plus4_if;
end

//IF/ID
logic [31:0] pc_id, pc_plus4_id, instruction_id;
if_id_reg if_id_reg_inst(
    .clk(clk), .rst_n(rst_n), .stall(stall_id), .flush(flush_ex),
    .pc_in(pc), .pc_plus4_in(pc_plus4_if), .instruction_in(if_instruction),
    .pc_out(pc_id), .pc_plus4_out(pc_plus4_id), .instruction_out(instruction_id)
);

//ID
logic [6:0] opcode_id, funct7_id;
logic [4:0] rd_id, rs1_id, rs2_id;
logic [2:0] funct3_id;
decoder decoder_inst(
    .instruction(instruction_id), .opcode(opcode_id), .rd(rd_id),
    .funct3(funct3_id), .rs1(rs1_id), .rs2(rs2_id), .funct7(funct7_id)
);
logic reg_write_id, mem_read_id, mem_write_id, branch_id, jump_id;
logic [1:0] alu_src_a_sel_id, alu_src_b_sel_id, wb_sel_id;
id_control_unit id_control_unit_inst(
    .opcode(opcode_id), .reg_write(reg_write_id), .mem_read(mem_read_id),
    .mem_write(mem_write_id), .branch(branch_id), .jump(jump_id),
    .alu_src_a_sel(alu_src_a_sel_id), .alu_src_b_sel(alu_src_b_sel_id), .wb_sel(wb_sel_id)
);
logic [31:0] imm_id, rs1_data_id, rs2_data_id, writeback_data;
logic [4:0] rd_wb;
logic reg_write_wb;
imm_gen imm_gen_inst(.instruction(instruction_id), .immediate(imm_id));
register_file register_file_inst(
    .clk(clk), .rd(rd_wb), .write_data(writeback_data), .we(reg_write_wb),
    .rs1(rs1_id), .rs2(rs2_id), .read_data1(rs1_data_id), .read_data2(rs2_data_id)
);
logic [4:0] rd_ex;
logic mem_read_ex;
logic bubble_hazard;
hazard_detection_unit hazard_detection_unit_inst(
    .rs1_id(rs1_id), .rs2_id(rs2_id), .rd_ex(rd_ex), .mem_read_ex(mem_read_ex),
    .stall(stall_id), .bubble(bubble_hazard)
);

//ID/EX
logic [31:0] pc_ex, rs1_data_ex, rs2_data_ex, imm_ex;
logic [4:0] rs1_ex, rs2_ex;
logic [2:0] funct3_ex;
logic [6:0] funct7_ex, opcode_ex;
logic reg_write_ex, mem_write_ex, branch_ex, jump_ex;
logic [1:0] alu_src_a_sel_ex, alu_src_b_sel_ex, wb_sel_ex;
id_ex_reg id_ex_reg_inst(
    .clk(clk), .rst_n(rst_n), .bubble(bubble_hazard || flush_ex),
    .pc_in(pc_id), .rs1_data_in(rs1_data_id), .rs2_data_in(rs2_data_id), .imm_in(imm_id),
    .rs1_in(rs1_id), .rs2_in(rs2_id), .rd_in(rd_id), .funct3_in(funct3_id),
    .funct7_in(funct7_id), .opcode_in(opcode_id), .reg_write_in(reg_write_id),
    .mem_read_in(mem_read_id), .mem_write_in(mem_write_id),
    .alu_src_a_sel_in(alu_src_a_sel_id), .alu_src_b_sel_in(alu_src_b_sel_id),
    .wb_sel_in(wb_sel_id), .branch_in(branch_id), .jump_in(jump_id),
    .pc_out(pc_ex), .rs1_data_out(rs1_data_ex), .rs2_data_out(rs2_data_ex), .imm_out(imm_ex),
    .rs1_out(rs1_ex), .rs2_out(rs2_ex), .rd_out(rd_ex), .funct3_out(funct3_ex),
    .funct7_out(funct7_ex), .opcode_out(opcode_ex), .reg_write_out(reg_write_ex),
    .mem_read_out(mem_read_ex), .mem_write_out(mem_write_ex),
    .alu_src_a_sel_out(alu_src_a_sel_ex), .alu_src_b_sel_out(alu_src_b_sel_ex),
    .wb_sel_out(wb_sel_ex), .branch_out(branch_ex), .jump_out(jump_ex)
);

//EX
logic [4:0] rd_mem;
logic reg_write_mem;
logic [1:0] wb_sel_mem;
logic [31:0] alu_result_mem, pc_plus4_mem;
logic [1:0] wb_sel_wb;
logic [31:0] alu_result_wb, mem_read_data_wb, pc_plus4_wb;
logic [1:0] forward_a, forward_b;
forwarding_unit forwarding_unit_inst(
    .rs1_ex(rs1_ex), .rs2_ex(rs2_ex), .rd_mem(rd_mem), .reg_write_mem(reg_write_mem),
    .rd_wb(rd_wb), .reg_write_wb(reg_write_wb), .forward_a(forward_a), .forward_b(forward_b)
);
logic [31:0] ex_mem_fwd_value;
always_comb begin
    case (wb_sel_mem)
        WB_PC4: ex_mem_fwd_value = pc_plus4_mem;
        default: ex_mem_fwd_value = alu_result_mem;// WB_MEM never lands here: hazard stall
    endcase // guarantees a load has moved to MEM/WB
end// before anything forwards from it
logic [31:0] rs1_forwarded, rs2_forwarded;
always_comb begin
    case (forward_a)
        2'b01: rs1_forwarded = ex_mem_fwd_value;
        2'b10: rs1_forwarded = writeback_data;// writeback_data doubles as the MEM/WB tap
        default: rs1_forwarded = rs1_data_ex;
    endcase
    case (forward_b)
        2'b01: rs2_forwarded = ex_mem_fwd_value;
        2'b10: rs2_forwarded = writeback_data;
        default: rs2_forwarded = rs2_data_ex;
    endcase
end
logic [31:0] alu_operand_a, alu_operand_b, alu_result_ex;
logic [4:0] alu_control_signal;
logic zero_ex, branch_taken_ex;
alu_src_mux alu_src_mux_inst(
    .rs1_data(rs1_forwarded), .rs2_data(rs2_forwarded), .imm(imm_ex),
    .pc(pc_ex), .old_pc(pc_ex),// old_pc tied off: never selected, pipeline doesn't need it
    .alu_src_a_sel(alu_src_a_sel_ex), .alu_src_b_sel(alu_src_b_sel_ex),
    .alu_a(alu_operand_a), .alu_b(alu_operand_b)
);
alu_control alu_control_inst(
    .opcode(opcode_ex), .funct3(funct3_ex), .funct7(funct7_ex), .alu_control(alu_control_signal)
);
alu alu_inst(
    .operand_a(alu_operand_a), .operand_b(alu_operand_b),
    .alu_control(alu_control_signal), .result(alu_result_ex), .zero(zero_ex)
);
branch_comparator branch_comparator_inst(
    .rs1_data(rs1_forwarded), .rs2_data(rs2_forwarded), .funct3(funct3_ex), .branch_taken(branch_taken_ex)
);
assign flush_ex = jump_ex || (branch_ex && branch_taken_ex);
assign flush_target = (opcode_ex == JALR) ? {alu_result_ex[31:1], 1'b0} : alu_result_ex; // JALR needs the                                                                                  // bit-0 mask; JAL/branch don't

//EX/MEM
logic [31:0] mem_write_data_mem;
logic mem_read_mem, mem_write_mem;
ex_mem_reg ex_mem_reg_inst(
    .clk(clk), .rst_n(rst_n), .alu_result_in(alu_result_ex), .mem_write_data_in(rs2_forwarded),
    .pc_plus4_in(pc_ex + 32'd4), .rd_in(rd_ex), .reg_write_in(reg_write_ex),
    .mem_read_in(mem_read_ex), .mem_write_in(mem_write_ex), .wb_sel_in(wb_sel_ex),
    .alu_result_out(alu_result_mem), .mem_write_data_out(mem_write_data_mem),
    .pc_plus4_out(pc_plus4_mem), .rd_out(rd_mem), .reg_write_out(reg_write_mem),
    .mem_read_out(mem_read_mem), .mem_write_out(mem_write_mem), .wb_sel_out(wb_sel_mem)
);

//MEM
logic [31:0] mem_read_data_mem;
data_mem data_mem_inst(
    .clk(clk), .mem_read(mem_read_mem), .mem_write(mem_write_mem),
    .addr(alu_result_mem), .write_data(mem_write_data_mem), .read_data(mem_read_data_mem)
);

//MEM/WB
mem_wb_reg mem_wb_reg_inst(
    .clk(clk), .rst_n(rst_n), .alu_result_in(alu_result_mem), .mem_read_data_in(mem_read_data_mem),
    .pc_plus4_in(pc_plus4_mem), .rd_in(rd_mem), .reg_write_in(reg_write_mem), .wb_sel_in(wb_sel_mem),
    .alu_result_out(alu_result_wb), .mem_read_data_out(mem_read_data_wb),
    .pc_plus4_out(pc_plus4_wb), .rd_out(rd_wb), .reg_write_out(reg_write_wb), .wb_sel_out(wb_sel_wb)
);
//WB
writeback_mux writeback_mux_inst(
    .alu_result(alu_result_wb), .mem_data(mem_read_data_wb), .pc_plus4(pc_plus4_wb),
    .wb_sel(wb_sel_wb), .writeback_data(writeback_data)
);
endmodule
