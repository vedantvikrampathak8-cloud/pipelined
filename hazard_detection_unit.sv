module hazard_detection_unit(
    input logic [4:0] rs1_id,
    input logic [4:0] rs2_id,
    input logic [4:0] rd_ex,
    input logic mem_read_ex,     // true only when the instruction currently in EX is a LOAD
    output logic stall,
    output logic bubble
);
always_comb begin
    if (mem_read_ex && rd_ex != 5'd0 && (rd_ex == rs1_id || rd_ex == rs2_id)) begin
        stall = 1'b1;   // freeze PC + IF/ID: re-present the same instruction to ID next cycle
        bubble = 1'b1;   // force ID/EX to a NOP so EX doesn't act on stale control signals this cycle
    end else begin
        stall = 1'b0;
        bubble = 1'b0;
    end
end
endmodule
