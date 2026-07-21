import riscv_pkg::*;
module alu_control(
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [6:0] opcode,
    output logic [4:0] alu_control
);
always_comb begin
    alu_control = ALU_ADD;
    case (opcode)
        OP: begin
            case (funct3)
                FUNCT3_ADD_SUB: begin
                    case (funct7)
                        FUNCT7_STD:
                            alu_control = ALU_ADD;
                        FUNCT7_SUB_SRA:
                            alu_control = ALU_SUB;
                        default:
                            alu_control = ALU_ADD;
                    endcase
                end
                FUNCT3_SR: begin
                    case (funct7)
                        FUNCT7_STD:
                            alu_control = ALU_SRL;
                        FUNCT7_SUB_SRA:
                            alu_control = ALU_SRA;
                        default:
                            alu_control = ALU_SRL;
                    endcase
                end
                FUNCT3_OR:
                    alu_control = ALU_OR;
                FUNCT3_AND:
                    alu_control = ALU_AND;
                FUNCT3_XOR:
                    alu_control = ALU_XOR;
                FUNCT3_SLL:
                    alu_control = ALU_SLL;
                FUNCT3_SLT:
                    alu_control = ALU_SLT;
                FUNCT3_SLTU:
                    alu_control = ALU_SLTU;
                default:
                    alu_control = ALU_ADD;
            endcase
        end
        OP_IMM: begin
            case (funct3)
                FUNCT3_ADD_SUB: begin
                    alu_control = ALU_ADD;//op immediate has no sub instruction, so we can just use add
                end
                FUNCT3_SR: begin
                    case (funct7)
                        FUNCT7_STD:
                            alu_control = ALU_SRL;
                        FUNCT7_SUB_SRA:
                            alu_control = ALU_SRA;
                        default:
                            alu_control = ALU_SRL;
                    endcase
                end
                FUNCT3_OR:
                    alu_control = ALU_OR;
                FUNCT3_AND:
                    alu_control = ALU_AND;
                FUNCT3_XOR:
                    alu_control = ALU_XOR;
                FUNCT3_SLL:
                    alu_control = ALU_SLL;
                FUNCT3_SLT:
                    alu_control = ALU_SLT;
                FUNCT3_SLTU:
                    alu_control = ALU_SLTU;
                default:
                    alu_control = ALU_ADD;
            endcase
        end  
        LOAD: begin
                 alu_control = ALU_ADD;// Address calculation: rs1 + immediate
        end
        STORE: begin
            alu_control = ALU_ADD;// Address calculation: rs1 + immediate
        end    
        LUI: begin
            alu_control = ALU_ADD;// Address calculation: immediate
        end   
        AUIPC: begin
            alu_control = ALU_ADD;// Address calculation: pc + immediate
        end   
        JAL: begin
            alu_control = ALU_ADD;// Jump target = PC + immediate
        end     
        JALR: begin
            alu_control = ALU_ADD;// Jump target = rs1 + immediate
        end   
        BRANCH: begin
            // Branch condition (taken/not-taken) is decided entirely by branch_comparator,
            // not the ALU. The ALU's only job for BRANCH is address arithmetic:
            //   - single-cycle: this result is unused (next_pc_logic has its own pc+imm adder)
            //   - multicycle: EXEC_BRANCH reuses this ALU to compute old_pc + imm as the target,
            //     so it must always be ADD regardless of funct3.
            alu_control = ALU_ADD;
        end
        default:
            alu_control = ALU_ADD;
    endcase
end
endmodule