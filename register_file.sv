module register_file(
    input logic [4:0] rd,
    input logic clk,
    input logic [31:0] write_data,
    input logic we,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);
logic [31:0] regs [0:31];
integer i;//so registers do not start with xxxx
initial begin
    for (i = 0; i < 32; i = i + 1)
        regs[i] = 32'd0;
end
always_ff @( posedge clk ) begin
    if(we) begin
        if(rd != 5'd0)begin
            regs[rd] <= write_data;
        end

    end
end
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 : (we && rd == rs1 && rd != 5'd0) ? write_data : regs[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'd0 : (we && rd == rs2 && rd != 5'd0) ? write_data : regs[rs2];
endmodule
