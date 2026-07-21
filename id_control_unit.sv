import riscv_pkg::*;

module id_control_unit(
    input logic [6:0] opcode,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic branch,
    output logic jump,
    output logic [1:0] alu_src_a_sel,
    output logic [1:0] alu_src_b_sel,
    output logic [1:0] wb_sel
);
always_comb begin
    reg_write = 1'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;
    branch = 1'b0;
    jump = 1'b0;
    alu_src_a_sel = ALU_SRC_RS1;
    alu_src_b_sel = ALU_SRC_RS2;
    wb_sel = WB_ALU;
    case (opcode)
        OP: begin
            reg_write = 1'b1;
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_RS2;
            wb_sel = WB_ALU;
        end
        OP_IMM: begin
            reg_write = 1'b1;
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_IMM;
            wb_sel = WB_ALU;
        end
        LOAD: begin
            reg_write = 1'b1;
            mem_read = 1'b1;
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_IMM;
            wb_sel = WB_MEM;
        end
        STORE: begin
            mem_write = 1'b1;
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_IMM;
        end
        BRANCH: begin
            branch = 1'b1;// taken/not-taken comes from branch_comparator's own ports, not this ALU
            alu_src_a_sel = ALU_SRC_PC;// shared ALU instead computes the branch target: pc + imm
            alu_src_b_sel = ALU_SRC_IMM;
        end
        LUI: begin
            reg_write = 1'b1;
            alu_src_a_sel = ALU_SRC_ZERO;
            alu_src_b_sel = ALU_SRC_IMM;
            wb_sel = WB_ALU;
        end
        AUIPC: begin
            reg_write = 1'b1;
            alu_src_a_sel = ALU_SRC_PC;// id_ex_reg.pc_out is already this instruction's own address —
            alu_src_b_sel = ALU_SRC_IMM;// no old_pc-style latch needed, unlike the multicycle version
            wb_sel = WB_ALU;
        end
        JAL: begin
            reg_write = 1'b1;
            jump = 1'b1;
            alu_src_a_sel = ALU_SRC_PC;
            alu_src_b_sel = ALU_SRC_IMM;
            wb_sel = WB_PC4;
        end
        JALR: begin
            reg_write = 1'b1;
            jump = 1'b1;
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_IMM;
            wb_sel = WB_PC4;
        end
        default: begin// unrecognized opcode: all outputs stay at the safe defaults above
        
        end
    endcase
end
endmodule
