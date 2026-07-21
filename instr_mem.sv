module instr_mem (
    input logic [31:0] addr,
    output logic [31:0] instruction
);
logic [31:0] memory [0:255];
initial begin
    memory[0] = 32'h00500093;
    memory[1] = 32'h00A00113;
    memory[2] = 32'h002081B3;
    memory[3] = 32'h00000013;
end
always_comb 
begin
    instruction = memory[addr[31:2]];
    
end
    
endmodule