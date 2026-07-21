module next_pc_logic(
    input  logic [31:0] pc,
    input  logic [31:0] immediate,
    input  logic [31:0] alu_result,
    input  logic branch,
    input  logic branch_taken,
    input  logic jump,
    input  logic jalr,
    output logic [31:0] next_pc
);
always_comb begin
    if (jump) begin
        if (jalr)
            next_pc = {alu_result[31:1], 1'b0};
        else
            next_pc = pc + immediate;
    end
    else if (branch && branch_taken) begin
        next_pc = pc + immediate;
    end
    else begin
        next_pc = pc + 32'd4;
    end
end
endmodule