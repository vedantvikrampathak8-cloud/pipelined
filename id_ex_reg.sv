module id_ex_reg(
    input logic clk,
    input logic rst_n,
    input logic bubble,             // load-use hazard: force this stage's output to a NOP
    input logic [31:0] pc_in,
    input logic [31:0] rs1_data_in,
    input logic [31:0] rs2_data_in,
    input logic [31:0] imm_in,
    input logic [4:0]  rs1_in,
    input logic [4:0]  rs2_in,
    input logic [4:0]  rd_in,
    input logic [2:0]  funct3_in,
    input logic [6:0]  funct7_in,
    input logic [6:0]  opcode_in,
    input logic reg_write_in,
    input logic mem_read_in,
    input logic mem_write_in,
    input logic [1:0] alu_src_a_sel_in,
    input logic [1:0] alu_src_b_sel_in,
    input logic [1:0] wb_sel_in,
    input logic branch_in,
    input logic jump_in,
    output logic [31:0] pc_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_out,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out,
    output logic [2:0]  funct3_out,
    output logic [6:0]  funct7_out,
    output logic [6:0]  opcode_out,
    output logic reg_write_out,
    output logic mem_read_out,
    output logic mem_write_out,
    output logic [1:0] alu_src_a_sel_out,
    output logic [1:0] alu_src_b_sel_out,
    output logic [1:0] wb_sel_out,
    output logic branch_out,
    output logic jump_out
);
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || bubble) begin
        pc_out <= 32'b0;
        rs1_data_out <= 32'b0;
        rs2_data_out <= 32'b0;
        imm_out <= 32'b0;
        rs1_out <= 5'b0;
        rs2_out <= 5'b0;
        rd_out <= 5'b0;   // rd=0 -> any leftover reg_write downstream becomes harmless
        funct3_out <= 3'b0;
        funct7_out <= 7'b0;
        opcode_out <= 7'b0;
        reg_write_out <= 1'b0;   // this block of resets is the actual bubble: every write-enable forced off
        mem_read_out <= 1'b0;
        mem_write_out <= 1'b0;
        alu_src_a_sel_out <= 2'b0;
        alu_src_b_sel_out <= 2'b0;
        wb_sel_out <= 2'b0;
        branch_out <= 1'b0;
        jump_out <= 1'b0;
    end else begin
        pc_out <= pc_in;
        rs1_data_out <= rs1_data_in;
        rs2_data_out <= rs2_data_in;
        imm_out <= imm_in;
        rs1_out <= rs1_in;   // carried forward for the forwarding unit, not just the ALU
        rs2_out <= rs2_in;
        rd_out <= rd_in;
        funct3_out <= funct3_in;
        funct7_out <= funct7_in;
        opcode_out <= opcode_in;
        reg_write_out <= reg_write_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        alu_src_a_sel_out <= alu_src_a_sel_in;
        alu_src_b_sel_out <= alu_src_b_sel_in;
        wb_sel_out <= wb_sel_in;
        branch_out <= branch_in;
        jump_out <= jump_in;
    end
end
endmodule
