module pc(
    input logic clk,
    input logic rst_n,
    input logic pc_write,
    input logic [31:0] next_pc,
    output logic [31:0] pc
);
always_ff @( posedge clk or negedge rst_n)
 begin
 if(!rst_n)
 pc <= 32'h0000_0000;
 else if(pc_write)
 pc<=next_pc;
end
endmodule