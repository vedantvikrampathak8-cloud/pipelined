import riscv_pkg::*;

module mc_control_unit(
    input logic clk,
    input logic rst_n,
    input logic [6:0] opcode,
    input logic zero,
    input logic branch_taken,
    output logic pc_write,
    output logic ir_write,
    output logic a_write,
    output logic b_write,
    output logic aluout_write,
    output logic mdr_write,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic [1:0] alu_src_a_sel,
    output logic [1:0] alu_src_b_sel,
    output logic [1:0] wb_sel,
    output logic [1:0] pc_src,
    output state_t state
);
state_t current_state;
state_t next_state;
always_ff@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        current_state<= FETCH;
    else
        current_state<= next_state;
end
assign state = current_state;
always_comb begin
    pc_write=0;
    ir_write=0;
    a_write=0;
    b_write=0;
    aluout_write=0;
    mdr_write=0;
    reg_write=0;
    mem_write=0;
    mem_read=0;
    alu_src_a_sel=2'b00;
    alu_src_b_sel=2'b00;
    wb_sel=2'b00;
    pc_src=2'b00;
    next_state=current_state;
    case (current_state)
        FETCH: begin
            // NOTE: no mem_read here — that control signal feeds data_mem, not instr_mem,
            // which reads combinationally off pc regardless. Asserting it here would just
            // pointlessly poke data_mem with a stale address every fetch.
            ir_write=1'b1;
            pc_write=1'b1;
            pc_src=2'b00; // pc + 4 (speculative; EXEC_BRANCH/WB_ALU can override for taken branches/jumps)
            next_state=DECODE;
        end
        DECODE: begin
            a_write=1'b1;
            b_write=1'b1;
            case (opcode)
                OP:
                    next_state=EXEC_R;
                OP_IMM:
                    next_state=EXEC_I;
                LOAD:
                    next_state=EXEC_LOAD;
                STORE:
                    next_state=EXEC_STORE;
                BRANCH:
                    next_state=EXEC_BRANCH;
                JAL,
                JALR:
                    next_state=EXEC_JUMP;
                LUI,
                AUIPC:
                    next_state=EXEC_U;
                default:
                    next_state=FETCH;
            endcase
        end
        EXEC_R: begin
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_RS2;
            aluout_write  = 1'b1;
            next_state    = ST_WB_ALU;
        end
        EXEC_I: begin
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_IMM;
            aluout_write  = 1'b1;
            next_state    = ST_WB_ALU;
        end
        EXEC_U: begin
            // LUI: 0 + imm  |  AUIPC: old_pc + imm
            alu_src_a_sel = (opcode == LUI) ? ALU_SRC_ZERO : ALU_SRC_OLD_PC;
            alu_src_b_sel = ALU_SRC_IMM;
            aluout_write  = 1'b1;
            next_state    = ST_WB_ALU;
        end
        EXEC_LOAD: begin
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_IMM;
            aluout_write  = 1'b1;    // latch effective address into alu_out for MEM_READ
            next_state    = MEM_READ;
        end
        EXEC_STORE: begin
            alu_src_a_sel = ALU_SRC_RS1;
            alu_src_b_sel = ALU_SRC_IMM;
            aluout_write  = 1'b1;    // latch effective address into alu_out for MEM_WRITE
            next_state    = MEM_WRITE;
        end
        EXEC_BRANCH: begin
            alu_src_a_sel = ALU_SRC_OLD_PC;
            alu_src_b_sel = ALU_SRC_IMM;
            if (branch_taken) begin
                pc_write = 1'b1;
                pc_src   = 2'b01; // next_pc <= alu_result (old_pc + imm), computed combinationally this cycle
            end
            // not taken: pc_write stays 0, so pc keeps FETCH's speculative pc+4 — correct fallthrough
            next_state = FETCH;
        end
        EXEC_JUMP: begin
            // JAL: old_pc + imm  |  JALR: rs1 + imm
            alu_src_a_sel = (opcode == JALR) ? ALU_SRC_RS1 : ALU_SRC_OLD_PC;
            alu_src_b_sel = ALU_SRC_IMM;
            aluout_write  = 1'b1;    // latch jump target into alu_out for WB_ALU to commit to pc
            next_state    = ST_WB_ALU;
        end
        MEM_READ: begin
            mem_read   = 1'b1;
            mdr_write  = 1'b1;
            next_state = WB_LOAD;
        end
        MEM_WRITE: begin
            mem_write  = 1'b1;
            next_state = FETCH;
        end
        ST_WB_ALU: begin
            reg_write = 1'b1;
            case (opcode)
                JAL, JALR: begin
                    wb_sel   = WB_PC4;  // rd <= old_pc + 4 (return address)
                    pc_write = 1'b1;
                    pc_src   = 2'b10;   // next_pc <= alu_out (jump target latched in EXEC_JUMP)
                end
                default: begin
                    wb_sel = WB_ALU;    // rd <= alu_out (R-type, I-type, LUI, AUIPC)
                end
            endcase
            next_state = FETCH;
        end
        WB_LOAD: begin
            reg_write  = 1'b1;
            wb_sel     = WB_MEM;
            next_state = FETCH;
        end
        default: begin
            next_state = FETCH;
        end
    endcase
end
endmodule
