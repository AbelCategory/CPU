`define LSB_SIZE 15:0
`define LSB_LEN 16
module LSB (
    input wire clk,
    input wire rst,
    inout wire rdy,

    input wire        from_dc_ok,
    input wire [31:0] vj, vk,
    input wire [ 4:0] qj, qk, en,
    input wire [ 5:0] opt,

    input wire        from_mc_ok,
    output reg        to_mc_ok,
    output reg [31:0] to_mc_addr,
    output reg [31:0] to_mc_imm,
    output reg [31:0] to_mc_val,
    output reg [ 5:0] to_mc_opt,
    
    output wire is_lsb_full,

    input wire        from_rob_commit,
    input wire [ 3:0] from_rob_pos,

    input wire        CDB_1_ok,
    input wire [ 4:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 4:0] CDB_2_en,
    input wire [31:0] CDB_2_val,

    input wire clear
);

reg [ 5:0] op[`LSB_SIZE];
reg [31:0] Vj[`LSB_SIZE], Vk[`LSB_SIZE];
reg [ 4:0] Qj[`LSB_SIZE], Qk[`LSB_SIZE], Qr[`LSB_SIZE];
reg [ 3:0] L, R;
integer i;
assign is_lsb_full = (L == R + 1) && from_dc_ok;

always @(posedge clk) begin
    if (rst) begin
        L <= 0; R <= 0;
        for (i = 0; i < `LSB_LEN; ++i) begin
            Qj[i] <= 0;
            Qk[i] <= 0;
        end
    end
    else if(!rdy) begin
        
    end
    else if(clear) begin
        
    end
    else begin
        if (from_dc_ok) begin
            op[R] <= opt; Qr[i] <= en;
            Vj[R] <= vj; Vk[R] <= vk;
            Qj[R] <= qj; Qk[R] <= qk;
            R <= R + 1;
        end

        if (L != R && Qj[L] == 0 && Qk[L] == 0) begin
            if (from_mc_ok) begin
                to_mc_ok <= 1;
                to_mc_opt <= op[L];
                to_mc_addr <= Vj[L];
                if (op[L][5:3] == 3'b101) begin // Load
                    to_mc_imm <= Vk[L];
                    to_mc_val <= en[L];
                end
                else begin // Store
                    to_mc_imm <= en[L];
                    to_mc_val <= Vk[L];
                end
            end
            else begin
                to_mc_ok <= 0;
            end
        end
        else begin
            to_mc_ok <= 0;
        end

        if (CDB_1_ok) begin
            for (i = 0; i < `LSB_LEN; ++i) begin
                if (Qj[i] == CDB_1_en) begin
                    Qj[i] <= 0;
                    Vj[i] <= CDB_1_val;
                end
                if (Qk[i] == CDB_1_en) begin
                    Qk[i] <= 0;
                    Vk[i] <= CDB_1_val;
                end
            end
        end

        if (CDB_2_ok) begin
            for (i = 0; i < `LSB_LEN; ++i) begin
                if (Qj[i] == CDB_2_en) begin
                    Qj[i] <= 0;
                    Vj[i] <= CDB_1_val;
                end
                if (Qk[i] == CDB_2_en) begin
                    Qk[i] <= 0;
                    Vk[i] <= CDB_2_val;
                end
            end
        end

        if (from_rob_commit) begin
            Qk[from_rob_pos] <= 0;
        end
    end
end
endmodule //LSB
