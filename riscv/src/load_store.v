`define LSB_SIZE 15:0
`define LSB_LEN 16
// `define DEBUG_LSB

module LSB (
    input wire clk,
    input wire rst,
    inout wire rdy,

    input wire        from_dc_ok,
    input wire        from_dc_isk,
    input wire [31:0] vj, vk,
    input wire [ 4:0] qj, qk,
    input wire [ 5:0] opt,

    input wire        from_mc_ok,
    output reg        to_mc_ok,
    output reg [31:0] to_mc_addr,
    output reg [31:0] to_mc_imm,
    output reg [31:0] to_mc_val,
    output reg [ 5:0] to_mc_opt,
    
    output wire is_lsb_full,

    input wire [ 3:0] from_rob_L,
    input wire [ 3:0] from_rob_en,

    input wire        from_rob_commit,
    input wire [ 3:0] from_rob_pos,
    // input wire [ 3:0] from_rob_val,
    // output wire [3:0] to_rob_lsb_en,

    input wire        CDB_1_ok,
    input wire [ 3:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 3:0] CDB_2_en,
    input wire [31:0] CDB_2_val,

    input wire clear
);

reg [ 5:0] op[`LSB_SIZE];
reg [`LSB_SIZE] commit, busy;
reg [31:0] Vj[`LSB_SIZE], Vk[`LSB_SIZE];
reg [ 4:0] Qj[`LSB_SIZE], Qk[`LSB_SIZE], Qr[`LSB_SIZE];
reg [ 3:0] L, R;
reg [ 4:0] lst_commit;
reg is_lsb_work;
wire [31:0] head_addr = Vj[L] + Vk[L];
wire write_ok = commit[L];
wire read_ok = op[L][5:3] == 3'b101 && (head_addr[17:16] != 2'b11 || Qr[L] == from_rob_L);
integer i;
reg emp;

wire is_top_done = is_lsb_work && from_mc_ok;
wire [3:0] nL = L + is_top_done;
wire [3:0] nR = R + from_dc_ok;
reg [31:0] time_clock;

wire nemp = nL == nR && (emp || is_top_done && !from_dc_ok);
assign is_lsb_full = (nL == nR) && !nemp;
// assign is_lsb_full = 0;

always @(posedge clk) begin
    if (rst || clear && (lst_commit == 16)) begin
`ifdef DEBUG_LSB
        if (lst_commit == 16 && clear) begin
            $display("clear the lsb and lsb becomes empty!!!");
        end
`endif
        L <= 0; R <= 0;
        if (rst) begin
            time_clock <= 0;
        end
        lst_commit <= 16;
        is_lsb_work <= 0;
        to_mc_ok <= 0;
        emp <= 1;
        for (i = 0; i < `LSB_LEN; i = i + 1) begin
            Qj[i] <= 0;
            Qk[i] <= 0;
            commit[i] <= 0;
            busy[i] <= 0;
        end
    end
    else if(!rdy) begin
        
    end
    else if(clear) begin
        time_clock <= time_clock + 2;
        // to_mc_ok <= 0;
        // if (is_lsb_full && to_mc_opt[5:3] == 3'b101) begin
        //     to_mc_ok <= 0;
        // end
`ifdef DEBUG_LSB
        $display("clear the lsb!!!");
        $display("L: %d R: %d lst_commit: %d", L, R, lst_commit);
`endif
        R <= lst_commit + 1;
        for (i = 0; i < `LSB_LEN; i = i + 1) begin
            if (!commit[i]) begin
                busy[i] <= 0;
            end
        end
        if (from_mc_ok && is_lsb_work) begin
            busy[L] <= 0; commit[L] <= 0;
            to_mc_ok <= 0;
            if (lst_commit == L) begin
                lst_commit <= 16;
                emp <= 1;
            end
            L <= L + 1;
            is_lsb_work <= 0;
        end
    end
    else begin
        time_clock <= time_clock + 2;
        if (from_dc_ok) begin
            op[R] <= opt; Qr[R] <= from_rob_en;
            Vj[R] <= vj; Vk[R] <= vk;
            Qj[R] <= qj; Qk[R] <= qk;
            busy[R] <= 1;
// `ifdef DEBUG_LSB
            // if (opt[5:3] != 3'b111) begin
            //     $display("time: %x R: %d Vj: %x Vk: %x Qj: %x Qk:%x", time_clock, R, vj, vk, qj, qk);
            // end
// `endif 
            // ok[R] <= from_dc_isk;
            R <= R + 1;
        end
        // $display("time: %x LSB[9]: Vj: %x Vk: %x Qj: %x Qk: %x",time_clock, Vj[8], Vk[8], Qj[8], Qk[8]);

        if (from_mc_ok) begin
            busy[L] <= 0; commit[L] <= 0;
            to_mc_ok <= 0;
            L <= L + 1;
            is_lsb_work <= 0;
            if (lst_commit == L) begin
                lst_commit <= 16;
            end
        end
        else begin
            if (L != R && Qj[L] == 16 && Qk[L] == 16 && (read_ok || write_ok) && !is_lsb_work) begin
            // if (from_mc_ok) begin
                to_mc_ok <= 1;
                to_mc_opt <= op[L];
                to_mc_addr <= Vj[L];
                if (op[L][5:3] == 3'b101) begin // Load
                    to_mc_imm <= Vk[L];
                    to_mc_val <= Qr[L];
                    // if (L == 0) begin
                    //     $display("out: to_mc_addr %x to_mc_imm %x", Vj[L], Vk[L]);
                    // end
                end
                else begin // Store
                    to_mc_imm <= 0;
                    to_mc_val <= Vk[L];
                    // fopen
`ifdef DEBUG_LSB
                    $display("L: %d store : %x -> %x", L, Vj[L], Vk[L]);
`endif
                        // // to_mc_imm <= en[L];
                        // to_mc_imm <= en; 
                        // to_mc_val <= Vk[L];
                end
                is_lsb_work <= 1;
            end
        end
        if (CDB_1_ok) begin
            for (i = 0; i < `LSB_LEN; i = i + 1) begin
                if (busy[i]) begin
                    if (Qj[i] == CDB_1_en) begin
                        Qj[i] <= 16;
                        Vj[i] <= CDB_1_val + Vj[i];
                    end
                    if (Qk[i] == CDB_1_en) begin
                        Qk[i] <= 16;
                        Vk[i] <= CDB_1_val;
                    end
                end
                
                // if (op[i][5:3] == 3'b101 && (Qj[i] == CDB_1_en || Qj[i] == 0)) begin
                //     ok[i] <= 1;
                // end
            end
        end

        if (CDB_2_ok) begin
            for (i = 0; i < `LSB_LEN; i = i + 1) begin
                if (busy[i]) begin
                    if (Qj[i] == CDB_2_en) begin
                        Qj[i] <= 16;
                        Vj[i] <= CDB_2_val + Vj[i];
                    end
                    if (Qk[i] == CDB_2_en) begin
                        Qk[i] <= 16;
                        Vk[i] <= CDB_2_val;
                    end
                end
                
            end
        end

        if (from_rob_commit) begin
            // Qk[from_rob_pos] <= 0;
            // Vk[from_rob_pos] = Vk[from_rob_pos] + from_rob_val;
            // ok[from_rob_pos] <= 1;
            for (i = 0; i < `LSB_LEN; i = i + 1) begin
                if (busy[i] && Qr[i] == from_rob_pos && op[i][5:3] == 3'b111 && !commit[i]) begin
                    commit[i] <= 1;
                    lst_commit <= i;
                end
            end
        end

        emp <= nemp;
    end
end
endmodule //LSB
