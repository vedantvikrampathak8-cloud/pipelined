import riscv_pkg::*;
module alu(
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    input logic [4:0] alu_control,
    output logic [31:0] result,
    output logic zero
);
assign zero = (result == 32'b0);
always_comb begin
    result=32'b0;
    case (alu_control)
        ALU_ADD :begin
            result = operand_a + operand_b;
        end
        ALU_SUB: begin
            result = operand_a - operand_b;
        end
        ALU_AND: begin
            result = operand_a & operand_b;
        end
        ALU_OR: begin
            result = operand_a | operand_b;
        end
        ALU_XOR: begin
            result = operand_a ^ operand_b;
        end
        ALU_SLL: begin
            result = operand_a << operand_b[4:0];
        end
        ALU_SRL: begin
            result = operand_a >> operand_b[4:0];
        end
        ALU_SRA:begin
            result = $signed(operand_a) >>> operand_b[4:0];
        end
        ALU_SLT:begin
            result = ($signed(operand_a) < $signed(operand_b)) ? 32'b1 : 32'b0;
        end
        ALU_SLTU:begin
            result = (operand_a < operand_b) ? 32'b1 : 32'b0;
        end
        default: begin
            result = 32'b0;
        end
    endcase 
end
endmodule
