`define REG_SIZE 31:0
// `define DEBUG_REG
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
    output wire [ 4:0] Qj,
    output wire [ 4:0] Qk,

    input wire [ 3:0] rob_en,

    output wire [3:0] to_rob_Qj,
    output wire [3:0] to_rob_Qk,
    input wire        rob_Qj_ok,
    input wire        rob_Qk_ok,
    input wire [31:0] rob_Vj,
    input wire [31:0] rob_Vk,

    input wire        rob_commit,
    input wire [ 3:0] rob_commit_en,
    input wire [31:0] rob_commit_val,
    input wire [ 4:0] rob_commit_addr,

    input wire clear
);
reg [31:0] reg_val[`REG_SIZE];
reg [ 3:0] reg_rob[`REG_SIZE];
reg [`REG_SIZE] reg_busy;
integer i;

reg[31:0] time_clock;

assign to_rob_Qj = reg_rob[Rj];
assign to_rob_Qk = reg_rob[Rk];

assign Vj = reg_busy[Rj] ? (rob_Qj_ok ? rob_Vj : 0) : reg_val[Rj];
assign Vk = reg_busy[Rk] ? (rob_Qk_ok ? rob_Vk : 0) : reg_val[Rk];
assign Qj = reg_busy[Rj] ? (rob_Qj_ok ? 16 : reg_rob[Rj]) : 16;
assign Qk = reg_busy[Rk] ? (rob_Qk_ok ? 16 : reg_rob[Rk]) : 16;

always @(posedge clk) begin
`ifdef DEBUG_REG
    $display("time_clock: %d", time_clock);
    for (i = 0; i < 32; ++i) begin
        $display("reg %d: %d %d %d",i, reg_val[i], reg_rob[i], reg_busy[i]);
    end
`endif
    time_clock <= time_clock + 2;
    if (rst) begin
        for (i = 0; i < 32; ++i) begin
            reg_val[i] <= 0;
            reg_busy[i] <= 0;
        end
        time_clock <= 0;
    end
    else if(!rdy) begin
        
    end
    else begin
        // if (r) begin
            
        // end
        if (rob_commit && rob_commit_addr != 0) begin
// `ifdef DEBUG_REG
//             $display("%d %d %d, %d", rob_commit_addr, rob_commit_en, rob_commit_val, reg_rob[rob_commit_addr]);
//             $display("%d %d", from_dc_ok, Rr);
// `endif
            reg_val[rob_commit_addr] <= rob_commit_val;
            if (reg_busy[rob_commit_addr] && reg_rob[rob_commit_addr] == rob_commit_en && (!from_dc_ok || Rr != rob_commit_addr)) begin
                // reg_busy[rob_commit_addr] <= from_dc_ok || Rr != rob_commit_addr;
                // reg_rob[rob_commit] ;
                reg_busy[rob_commit_addr] <= 0;
                // reg_rob[rob_commit_addr] <= ;
            end
        end


        if (clear) begin
            for (i = 0; i < 32; ++i) begin
                reg_busy[i] <= 0;
                reg_rob[i] <= 16;
            end
        end
        else if (from_dc_ok && Rr != 0) begin
            reg_busy[Rr] <= 1;
            reg_rob[Rr] <= rob_en;
        end
    end
end
endmodule //REG
