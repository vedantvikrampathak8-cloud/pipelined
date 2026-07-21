module register#(
    parameter WIDTH = 32
)(
    input logic clk,
    input logic reset,
    input logic enable,
    input logic [WIDTH-1:0]d,
    output logic [WIDTH-1:0]q
);
always_ff@(posedge(clk))begin
    if(reset)
        q <= '0;
    else if(enable)
        q <= d;
end
endmodule