module alu_src_mux(
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] imm,
    input  logic [31:0] pc,
    input  logic [31:0] old_pc,
    input  logic [1:0] alu_src_a_sel,
    input  logic [1:0] alu_src_b_sel,
    output logic [31:0] alu_a,
    output logic [31:0] alu_b
);
always_comb begin
    case (alu_src_a_sel)
        2'b00: alu_a= rs1_data;
        2'b01: alu_a= pc;
        2'b10: alu_a= 32'd0;    // ALU_SRC_ZERO (LUI)
        2'b11: alu_a= old_pc;   // ALU_SRC_OLD_PC (AUIPC/JAL/BRANCH target math, multicycle only)
        default: alu_a= 32'd0;
    endcase
    case (alu_src_b_sel)
        2'b00: alu_b= rs2_data;
        2'b01: alu_b= imm;
        2'b10: alu_b= 32'd4;
        default: alu_b= 32'd0;
    endcase
end
endmodule