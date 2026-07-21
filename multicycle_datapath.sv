import riscv_pkg::*;

module multicycle_datapath(
    input logic clk,
    input logic rst_n,
    input logic pc_write,
    input logic ir_write,
    input logic a_write,
    input logic b_write,
    input logic aluout_write,
    input logic mdr_write,
    input logic reg_write,
    input logic mem_read,
    input logic mem_write,
    input logic [1:0] alu_src_a_sel,
    input logic [1:0] alu_src_b_sel,
    input logic [1:0] wb_sel,
    input logic [1:0] pc_src,
    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic zero,
    output logic branch_taken
);
logic [31:0] pc_plus4;
// IMPORTANT: derived from old_pc (latched at fetch time), NOT the live pc register.
// FETCH speculatively increments pc every cycle, so by the time later states (WB_ALU,
// EXEC_BRANCH, EXEC_JUMP...) run, live pc no longer equals this instruction's own address.
assign pc_plus4 = old_pc + 32'd4;

//datapath registers
logic [31:0] ir;
logic [31:0] reg_a;
logic [31:0] reg_b;
logic [31:0] alu_out;
logic [31:0] mdr;
logic [31:0] old_pc; // PC of the instruction currently in flight, latched alongside IR in FETCH

//internal wires
logic [31:0] pc;
logic [31:0] next_pc;
logic [31:0] instruction;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] imm;
logic [31:0] alu_operand_a;
logic [31:0] alu_operand_b;
logic [31:0] alu_result;
logic [31:0] mem_read_data;
logic [31:0] writeback_data;
logic [4:0] alu_control_signal; // NOTE: alu_control is fully internal now — see below

alu_control alu_control_inst (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_control(alu_control_signal)
);
pc pc_inst(
    .clk(clk),
    .rst_n(rst_n),
    .pc_write(pc_write),
    .next_pc(next_pc),
    .pc(pc)
);
instr_mem instr_mem_inst (
    .addr(pc),
    .instruction(instruction)   // was .instr(instruction) — instr_mem's port is named "instruction"
);
decoder decoder_inst (
    .instruction(ir),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
);
register_file register_file_inst (
    .clk(clk),
    .rd(rd),
    .write_data(writeback_data),
    .we(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .read_data1(rs1_data),
    .read_data2(rs2_data)
);
imm_gen imm_gen_inst (
    .instruction(ir),
    .immediate(imm)             // was .imm(imm) — imm_gen's port is named "immediate"
);
alu_src_mux alu_src_mux_inst (
    .rs1_data(reg_a),
    .rs2_data(reg_b),
    .imm(imm),
    .pc(pc),
    .old_pc(old_pc),
    .alu_src_a_sel(alu_src_a_sel),
    .alu_src_b_sel(alu_src_b_sel),
    .alu_a(alu_operand_a),       // was .operand_a(...) — alu_src_mux's ports are alu_a/alu_b
    .alu_b(alu_operand_b)
);
alu alu_inst (
    .operand_a(alu_operand_a),
    .operand_b(alu_operand_b),
    .alu_control(alu_control_signal),
    .result(alu_result),
    .zero(zero)
);
branch_comparator branch_comparator_inst (
    .rs1_data(reg_a),
    .rs2_data(reg_b),
    .funct3(funct3),
    .branch_taken(branch_taken)
);
data_mem data_mem_inst (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .addr(alu_out),
    .write_data(reg_b),
    .read_data(mem_read_data)
);
writeback_mux writeback_mux_inst (
    .alu_result(alu_out),
    .mem_data(mdr),
    .pc_plus4(pc_plus4),
    .wb_sel(wb_sel),
    .writeback_data(writeback_data)
);
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ir     <= 32'b0;
        old_pc <= 32'b0;
    end else if (ir_write) begin
        ir     <= instruction;
        old_pc <= pc; // nonblocking: captures pc's value BEFORE this same-cycle FETCH pc_write applies
    end
end
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        reg_a <= 32'b0;
    else if (a_write)
        reg_a <= rs1_data;
end
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        reg_b<= 32'b0;
    else if (b_write)
        reg_b<= rs2_data;
end
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        alu_out<= 32'b0;
    else if (aluout_write)
        alu_out<= alu_result;
end
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mdr<= 32'b0;
    else if (mdr_write)
        mdr<= mem_read_data;
end
always_comb begin
    case (pc_src)
        2'b00: next_pc= pc + 32'd4;
        2'b01: next_pc= alu_result;
        2'b10: next_pc= {alu_out[31:1], 1'b0};
        default: next_pc= pc + 32'd4;
    endcase
end

endmodule
