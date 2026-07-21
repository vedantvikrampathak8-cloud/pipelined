module if_id_reg(
    input logic clk,
    input logic rst_n,
    input logic stall,          // hazard downstream: freeze, don't advance this cycle
    input logic flush,          // branch/jump resolved taken: kill the fetched instruction
    input logic [31:0] pc_in,
    input logic [31:0] pc_plus4_in,
    input logic [31:0] instruction_in,
    output logic [31:0] pc_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] instruction_out
);
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_out <= 32'b0;
        pc_plus4_out <= 32'b0;
        instruction_out <= 32'b0;
    end else if (flush) begin
        pc_out <= 32'b0;
        pc_plus4_out <= 32'b0;
        instruction_out <= 32'b0;   // squash: wrong-path instruction never reaches ID
    end else if (!stall) begin
        pc_out <= pc_in;
        pc_plus4_out <= pc_plus4_in;
        instruction_out <= instruction_in;
    end
    // stall && !flush: no assignment -> holds current value, same instruction re-seen next cycle
end
endmodule
