`define ROB_SIZE 15:0
`define ROB_LEN 16
module ROB (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_dc_ok,
    input wire [ 5:0] opt,
    input wire [31:0] val,
    input wire [ 4:0] en,
    input wire        dc_jump,
    input wire [31:0] dc_jump_addr,


    
    output wire is_rob_full
    
);
integer i;
reg [ 3:0] L, R;
reg [`ROB_SIZE] ok;
reg [ 5:0] op[`ROB_SIZE];
reg [31:0] Val[`ROB_SIZE];
reg [ 4:0] Qr[ `ROB_SIZE];

always @(posedge clk) begin
    if (rst) begin
        L <= 0; R <= 0;
        for (i = 0; i < `ROB_LEN; ++i) begin
            
        end
    end
    else if(!rdy) begin
        
    end
    else begin
        
    end
end

endmodule //ROB
