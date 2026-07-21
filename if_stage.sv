module if_stage(
    input logic clk,
    input logic rst_n,
    output logic [31:0] pc,
    output logic [31:0] instruction
);

logic [31:0] next_pc;

pc u_pc (
    .clk(clk),
    .rst_n(rst_n),
    .pc_write(1'b1),
    .next_pc(next_pc),
    .pc(pc)
);

next_pc_logic u_next_pc (
    .pc(pc),
    .next_pc(next_pc)
);

instr_mem u_imem (
    .addr(pc),
    .instruction(instruction)
);

endmodule



