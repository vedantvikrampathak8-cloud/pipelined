module data_mem(
    input logic clk,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    output logic [31:0] read_data
);
integer i;//so memory does not start with xxxx
initial begin
    for (i = 0; i < 256; i = i + 1)
        memory[i] = 32'd0;
end
logic [31:0] memory [0:255];
always_ff @(posedge clk) begin
    if (mem_write) begin
        memory[addr[9:2]] <= write_data;
    end
end
always_comb begin
    if (mem_read) begin
        read_data = memory[addr[9:2]];
    end else begin
        read_data = 32'b0;
    end
end
endmodule