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
    
    output wire is_rob_full,

    output wire [3:0] out_rob_en,

    output reg        to_predictor_ok,
    output reg [31:0] to_predictor_add,
    output reg [31:0] to_predictor_jump,

    output reg        reg_commit,
    output reg [ 3:0] reg_commit_en,
    output reg [31:0] reg_commit_val,
    output reg [ 4:0] reg_commit_addr,

    output reg        to_lsb_commit,
    output reg [ 3:0] to_lsb_pos,
    output reg [31:0] to_lsb_val,

    input wire  [ 3:0] from_reg_Qj,
    input wire  [ 3:0] from_reg_Qk,
    output wire        reg_Qj_ok,
    output wire        reg_Qk_ok,
    output wire [31:0] reg_Vj,
    output wire [31:0] reg_Vk,

    input wire        CDB_1_ok,
    input wire [ 4:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 4:0] CDB_2_en,
    input wire [31:0] CDB_2_val
);
integer i;
reg [ 3:0] L, R;
reg [`ROB_SIZE] ok, jp;
reg [ 5:0] op[`ROB_SIZE];
reg [31:0] Val[`ROB_SIZE];
reg [31:0] pc[`ROB_SIZE];
reg [ 4:0] Qr[ `ROB_SIZE];

assign reg_Qj_ok = ok[from_reg_Qj];
assign reg_Qk_ok = ok[from_reg_Qk];
assign reg_Vj = ok[from_reg_Qj] ? Val[from_reg_Qj] : 0;
assign reg_Vk = ok[from_reg_Qk] ? Val[from_reg_Qk] : 0;

assign out_rob_en = R;

always @(posedge clk) begin
    if (rst) begin
        L <= 0; R <= 0;
        for (i = 0; i < `ROB_LEN; ++i) begin
            ok[i] <= 0;
        end
    end
    else if(!rdy) begin
        
    end
    else begin
        if (from_dc_ok) begin
            op[R] <= opt; jp[R] <= dc_jump;
            ok[R] <= 0; pc[R] <= dc_jump_addr;
            R <= R + 1;
        end
        if (L != R && ok[L]) begin
            reg_commit_addr <= Qr[L];
            reg_commit_en <= L;
            reg_commit_val <= Val[L];
            case (op[L][5:3])
                // L-type
                3'b101 : begin
                    reg_commit <= 1;
                    to_lsb_commit <= 0;
                end
                // S-type
                3'b111 : begin
                    to_lsb_commit <= 1;
                    reg_commit <= 0;
                    to_lsb_pos <= Qr[L];
                    to_lsb_val <= Val[L];
                end
                // B-type
                3'b100 : begin
                    if (Val[L][0] != jp[L]) begin
                        to_predictor_ok <= 1;
                        to_predictor_jump <= Val[L][0];
                        to_predictor_add <= pc[L];
                    end
                end
                // I-type
                3'b010 : begin
                    reg_commit <= 1;
                    to_lsb_commit <= 0;
                end
                3'b011 : begin
                    
                end
                3'b000 : begin
                    if (op[L] == 1) begin // AUIPC
                        
                    end
                    else begin
                        reg_commit <= 1;
                    end
                end
                default: begin
                    reg_commit <= 1;
                end
            endcase
            L <= L + 1;
        end
        else begin
            reg_commit <= 0;
            to_lsb_commit <= 0;
            to_predictor_ok <= 0;
        end

        if (CDB_1_ok) begin
            Val[CDB_1_en] <= CDB_1_val;
            ok[CDB_1_en] <= 1;
            for (i = L; i != R; ++i) begin
                if (op[i][5:3] == 3'b111 && !ok[i]) begin
                    
                end
            end
        end

        if (CDB_2_ok) begin
            Val[CDB_2_en] <= CDB_2_val;
        end
    end
end

endmodule //ROB
