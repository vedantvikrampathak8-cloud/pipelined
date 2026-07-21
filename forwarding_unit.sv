module forwarding_unit(
    input logic [4:0] rs1_ex,
    input logic [4:0] rs2_ex,
    input logic [4:0] rd_mem,
    input logic reg_write_mem,
    input logic [4:0] rd_wb,
    input logic reg_write_wb,
    output logic [1:0] forward_a,   // 00 = reg file, 01 = from EX/MEM, 10 = from MEM/WB
    output logic [1:0] forward_b
);
always_comb begin
    if (reg_write_mem && rd_mem != 5'd0 && rd_mem == rs1_ex)
        forward_a = 2'b01;          // EX/MEM checked first: it's the more recent result
    else if (reg_write_wb && rd_wb != 5'd0 && rd_wb == rs1_ex)
        forward_a = 2'b10;
    else
        forward_a = 2'b00;

    if (reg_write_mem && rd_mem != 5'd0 && rd_mem == rs2_ex)
        forward_b = 2'b01;
    else if (reg_write_wb && rd_wb != 5'd0 && rd_wb == rs2_ex)
        forward_b = 2'b10;
    else
        forward_b = 2'b00;
end
endmodule
