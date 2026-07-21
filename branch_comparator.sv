import riscv_pkg::*;
module branch_comparator(
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [2:0] funct3,
    output logic branch_taken
);
always_comb begin
    case (funct3)
        FUNCT3_BEQ:
            branch_taken = (rs1_data == rs2_data);
        FUNCT3_BNE:
            branch_taken = (rs1_data != rs2_data);
        FUNCT3_BLT:
            branch_taken = ($signed(rs1_data) < $signed(rs2_data));
        FUNCT3_BGE:
            branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
        FUNCT3_BLTU:
            branch_taken = (rs1_data < rs2_data);
        FUNCT3_BGEU:
            branch_taken = (rs1_data >= rs2_data);
        default:
            branch_taken = 1'b0;
    endcase
end

endmodule