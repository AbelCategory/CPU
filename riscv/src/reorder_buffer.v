module ROB (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_dc_ok,
    input wire [ 5:0] opt,
    input wire [31:0] val,
    input wire [ 4:0] en,
    
    output wire is_rob_full
    
);

always @(posedge clk) begin
    if (rst) begin
        
    end
    else if(!rdy) begin
        
    end
    else begin
        
    end
end

endmodule //ROB
