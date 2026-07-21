import riscv_pkg::*;
module control_unit(
    input logic [6:0] opcode,
    output logic reg_write,
    output logic [1:0] wb_sel,
    output logic mem_read,
    output logic mem_write,
    output logic branch,
    output logic jump,
    output logic [1:0] alu_src_a_sel,
    output logic [1:0] alu_src_b_sel,
    output logic [1:0] alu_op,
    output logic jalr
);
always_comb begin
    reg_write = 1'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;
    branch = 1'b0;
    jump = 1'b0;
    alu_src_a_sel = 2'b00;
    alu_src_b_sel = 2'b00;
    wb_sel = 2'b00;
    alu_op = 2'b00;
    jalr = 1'b0;
    case (opcode)
    OP: begin
    reg_write = 1'b1;
    alu_src_a_sel = 2'b00;// RS1
    alu_src_b_sel = 2'b00;// RS2
    wb_sel = 2'b00;// ALU Result
    alu_op = 2'b01;// R-type, funct3/funct7 decide exact op
    jalr = 1'b0;
    end
    OP_IMM: begin
    reg_write = 1'b1;
    alu_src_a_sel = 2'b00;// ALU operates on a base register (RS1) and an immediate offset/value.
    alu_src_b_sel = 2'b01;// Immediate
    wb_sel = 2'b00;// ALU Result
    alu_op = 2'b01;// Same funct3-decoded ALU op as R-type
    jalr = 1'b0;
    end
    LOAD: begin
    reg_write = 1'b1;
    mem_read = 1'b1;
    alu_src_a_sel = 2'b00;// Use RS1 as the base address register.
    alu_src_b_sel = 2'b01;// Add the immediate offset to the base address to form the memory address.
    wb_sel = 2'b01;// Memory Data
    alu_op = 2'b00;// Address calc: RS1 + imm
    jalr = 1'b0;
    end
    STORE: begin
    mem_write=1'b1;
    alu_src_a_sel=2'b00;// Use RS1 as the base address register.
    alu_src_b_sel=2'b01;// Add the immediate offset to compute the memory address; RS2 provides the data to store.
    wb_sel=2'b00;//Alu result, but we don't care about this since we aren't writing to the register file
    alu_op = 2'b00;// Address calc: RS1 + imm
    jalr = 1'b0;
    end
    BRANCH: begin
    branch = 1'b1;
    jalr = 1'b0;
    alu_src_a_sel = 2'b00;// Use RS1 as the first operand for comparison.
    alu_src_b_sel = 2'b00;// Use RS2 so the ALU can compare the two registers.
    wb_sel = 2'b00;//Alu result, but we don't care about this since we aren't writing to the register file
    alu_op = 2'b10;// Branch comparison, funct3 decides eq/ne/lt/ge
    end
    LUI: begin
    reg_write = 1'b1;
    jalr = 1'b0;
    alu_src_a_sel = 2'b10;// Use zero as the first ALU operand.
    alu_src_b_sel = 2'b01;// Use the U-type immediate value.
    wb_sel = 2'b00;// Write ALU result to the register.
    alu_op = 2'b11;// Pass immediate straight through
    end
    AUIPC: begin
    reg_write = 1'b1;
    jalr = 1'b0;
    alu_src_a_sel = 2'b01;// Use the current PC as the first ALU operand.
    alu_src_b_sel = 2'b01;// Use the U-type immediate value.
    wb_sel = 2'b00;// Write ALU result to the register.
    alu_op = 2'b00;// PC + imm
    end
    JAL: begin
    reg_write = 1'b1;
    jump = 1'b1;
    jalr = 1'b0;
    alu_src_a_sel = 2'b00;
    alu_src_b_sel = 2'b00;// PC + imm (jump target)
    wb_sel = 2'b10;// Write the return address (PC + 4)
    alu_op = 2'b00;// PC + imm (jump target)
    end
    JALR: begin
    reg_write = 1'b1;
    jump = 1'b1;  
    jalr = 1'b1;  
    alu_src_a_sel = 2'b00;// Use RS1 as the first ALU operand.
    alu_src_b_sel = 2'b01;// Use the I-type immediate value.
    wb_sel = 2'b10;// Write the return address (PC + 4)
    alu_op = 2'b00;// RS1 + imm (jump target)
    end
    endcase
end
endmodule