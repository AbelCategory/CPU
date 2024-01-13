`define ROB_SIZE 15:0
`define ROB_LEN 16
// `define DEBUG_ALL

module ROB (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_dc_ok,
    input wire [ 5:0] opt,
    input wire [31:0] val,
    input wire [ 4:0] en,
    input wire        dc_ok,
    input wire        dc_jump,
    input wire [31:0] dc_pc,
    input wire [31:0] dc_jump_addr,
    
    output wire is_rob_full,
    output reg clear,

    output wire [3:0] out_rob_en,
    output wire [3:0] out_rob_L,

    output reg        to_predictor_ok,
    output reg [31:0] to_predictor_add,
    output reg        to_predictor_jump,

    output reg [31:0] to_if_addr,

    output reg        reg_commit,
    output reg [ 3:0] reg_commit_en,
    output reg [31:0] reg_commit_val,
    output reg [ 4:0] reg_commit_addr,

    output reg        to_lsb_commit,
    output reg [ 3:0] to_lsb_pos,
    // output reg [31:0] to_lsb_val,

    input wire  [ 3:0] from_reg_Qj,
    input wire  [ 3:0] from_reg_Qk,
    output wire        reg_Qj_ok,
    output wire        reg_Qk_ok,
    output wire [31:0] reg_Vj,
    output wire [31:0] reg_Vk,

    input wire        CDB_1_ok,
    input wire [ 3:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 3:0] CDB_2_en,
    input wire [31:0] CDB_2_val
);
integer i;
reg [ 3:0] L, R;
reg [`ROB_SIZE] ok, jp;
reg [ 5:0] op[`ROB_SIZE];
reg [31:0] Val[`ROB_SIZE];
reg [31:0] pc[`ROB_SIZE], jpc[`ROB_SIZE];
reg [ 4:0] Qr[ `ROB_SIZE];

assign reg_Qj_ok = ok[from_reg_Qj];
assign reg_Qk_ok = ok[from_reg_Qk];
assign reg_Vj = ok[from_reg_Qj] ? Val[from_reg_Qj] : 0;
assign reg_Vk = ok[from_reg_Qk] ? Val[from_reg_Qk] : 0;

assign out_rob_en = R;
assign out_rob_L = L;

reg emp;
wire is_commit = !emp && ok[L];
wire [3:0] nL = L + is_commit;
wire [3:0] nR = R + from_dc_ok;
wire nemp = nL == nR && (emp || is_commit && !from_dc_ok);
assign is_rob_full = (nL == nR) && !nemp;

reg[31:0] time_cur;

always @(posedge clk) begin
    if (rst || clear) begin
        if (rst) begin
            time_cur <= 0;
        end else begin
            time_cur <= time_cur + 2;
        end
        clear <= 0;
        emp <= 1;
        to_predictor_ok <= 0;
        L <= 0; R <= 0;
        for (i = 0; i < `ROB_LEN; i = i + 1) begin
            ok[i] <= 0;
        end
    end
    else if(!rdy) begin
        
    end
    else begin
        time_cur <= time_cur + 2;
        if (from_dc_ok) begin
            op[R] <= opt; jp[R] <= dc_jump;
            ok[R] <= dc_ok; pc[R] <= dc_pc;
            jpc[R] <= dc_jump_addr; Qr[R] <= en;
            Val[R] <= val;
            R <= R + 1;
        end
        if (is_commit) begin
            reg_commit_addr <= Qr[L];
            reg_commit_en <= L;
            reg_commit_val <= Val[L];
            case (op[L][5:3])
                // L-type
                3'b101 : begin
                    reg_commit <= 1;
                    to_lsb_commit <= 0;
`ifdef DEBUG_ALL
                    $display("pc: %x reg: %x val: %x", pc[L], Qr[L], Val[L]);
                    // $display("time_cur: %x pc: %x reg: %x val: %x", time_cur, pc[L], Qr[L], Val[L]);
`endif
                end
                // S-type
                3'b111 : begin
                    to_lsb_commit <= 1;
                    reg_commit <= 0;
                    to_lsb_pos <= L;
                    // to_lsb_val <= Val[L];
`ifdef DEBUG_ALL
                    $display("pc: %x store!!!", pc[L]);
                    // $display("time_cur: %x pc: %x store!!!", time_cur, pc[L]);
`endif
                end
                // B-type
                3'b100 : begin
                    reg_commit <= 0;
`ifdef DEBUG_ALL
                    $display("pc: %x is_jump: %x", pc[L], Val[L][0]);
`endif
                    if (Val[L][0] != jp[L]) begin
                        to_predictor_ok <= 1;
                        to_predictor_jump <= Val[L][0];
                        to_predictor_add <= pc[L];
                        to_if_addr <= jpc[L];
                        clear <= 1;
                    end
                end
                default: begin // arith, arithI, LUI, AUIPC, JAL
                    reg_commit <= 1;
                    to_lsb_commit <= 0;
`ifdef DEBUG_ALL
                    $display("pc: %x reg: %x val: %x", pc[L], Qr[L], Val[L]);
                    // $display("time_cur: %x pc: %x reg: %x val: %x", time_cur, pc[L], Qr[L], Val[L]);
`endif
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
            // for (i = L; i != R; ++i) begin
            //     if (op[i][5:3] == 3'b111 && !ok[i]) begin
                    
            //     end
            // end
        end

        if (CDB_2_ok) begin
            Val[CDB_2_en] <= CDB_2_val;
            ok[CDB_2_en] <= 1;
        end

        emp <= nemp;
    end
end

endmodule //ROB
