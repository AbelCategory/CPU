`define REG_SIZE 31:0
module REG (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire         from_dc_ok,
    input wire  [ 4:0] Rj,
    input wire  [ 4:0] Rk,
    input wire  [ 4:0] Rr,
    output wire [31:0] Vj,
    output wire [31:0] Vk,
    output wire [ 3:0] Qj,
    output wire [ 3:0] Qk,

    input wire [ 3:0] rob_en,

    input wire        rob_commit,
    input wire [ 3:0] rob_commit_en,
    input wire [31:0] rob_commit_val,
    input wire [ 4:0] rob_commit_addr
);
reg [31:0] reg_val[`REG_SIZE];
reg [ 3:0] reg_rob[`REG_SIZE];
reg [`REG_SIZE] reg_busy;
integer i;

assign Vj = reg_busy[Rj] ? 0 : reg_val[Rj];
assign Vk = reg_busy[Rk] ? 0 : reg_val[Rk];
assign Qj = reg_busy[Rj] ? reg_rob[Rj] : 0;
assign Qk = reg_busy[Rk] ? reg_rob[Rk] : 0;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < 32; ++i) begin
            reg_val[i] <= 0;
            reg_busy[i] <= 0;
        end
    end
    else if(!rdy) begin
        
    end
    else begin
        if (from_dc_ok && Rr != 0) begin
            reg_busy[Rr] <= 1;
            reg_rob[Rr] <= rob_en;
        end
        if (rob_commit) begin
            reg_val[rob_commit_addr] <= rob_commit_val;
            if (reg_busy[rob_commit_addr] && reg_rob[rob_commit_addr] == rob_commit_en) begin
                reg_busy[rob_commit_addr] <= !from_dc_ok || Rr != rob_commit_addr;
            end
        end
    end
end
endmodule //REG
