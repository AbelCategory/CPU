`define RS_SIZE 15:0
`define RS_LEN 16
module RS (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_dc_ok,
    input wire [31:0] vj, vk,
    input wire [ 4:0] qj, qk,
    input wire [ 5:0] opt,

    input wire [3:0] from_rob_en,

    output wire is_rs_full,
    
    output reg        to_alu_ok,
    output reg [ 5:0] to_alu_opt,
    output reg [31:0] to_alu_rs1, to_alu_rs2, to_alu_imm,
    output reg [ 3:0] to_alu_en, 
    // input wire [31:0] from_alu_rd,

    input wire        CDB_1_ok,
    input wire [ 3:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 3:0] CDB_2_en,
    input wire [31:0] CDB_2_val,

    input wire clear
);
integer i;
reg [`RS_SIZE] busy, ok;
reg [ 5:0] op[`RS_SIZE];
reg [31:0] Vj[`RS_SIZE], Vk[`RS_SIZE];
reg [ 4:0] Qj[`RS_SIZE], Qk[`RS_SIZE], Qr[`RS_SIZE];
wire [`RS_SIZE] emp = (~busy) & -(~busy);
wire [`RS_SIZE] okp = ok & -ok;

// not needed
assign is_rs_full = 0;

always @(posedge clk) begin
    if(rst || clear) begin
        to_alu_ok <= 0;
        busy <= 0;
        ok <= 0;
    end
    else if(!rdy) begin
        
    end
    else begin
        if (from_dc_ok) begin
            for (i = 0; i < `RS_LEN; ++i) begin
                if (emp[i] == 1) begin
                    busy[i] <= 1;
                    Vj[i] <= vj; Vk[i] <= vk;
                    Qj[i] <= qj; Qk[i] <= qk;
                    op[i] <= opt; Qr[i] <= from_rob_en;
                    ok[i] <= qj == 16 && qk == 16;
                end
            end
        end
        if (ok != 0) begin
            for (i = 0; i < `RS_LEN; ++i) begin
                if (okp[i] == 1) begin
                    to_alu_ok <= 1;
                    to_alu_opt <= op[i];
                    to_alu_rs1 <= Vj[i];
                    to_alu_en <= Qr[i];
                    busy[i] <= 0; ok[i] <= 0;
                    if (op[i][5:3] == 3'b010 || op[i][5:3] == 3'b011) begin
                        to_alu_imm <= Vk[i];
                    end
                    else begin
                        to_alu_rs2 <= Vk[i];
                    end
                    // case (op[i][5:3])
                    //     3'b000 : to_alu_rs2 <= Vk[i];
                    //     3'b010 : to_alu_imm <= Vk[i];
                    //     3'b001 : to_alu_rs2 <= Vk[i];
                    //     3'b100 : 
                    // endcase
                end
            end
        end
        else begin
            to_alu_ok <= 0;
        end

        if (CDB_1_ok) begin
            for (i = 0; i < `RS_LEN; ++i) begin
                if (busy[i] && !ok[i]) begin
                    if ((Qj[i] == 16 || Qj[i] == CDB_1_en) && (Qk[i] == 16 || Qk[i] == CDB_1_en)) begin
                        ok[i] <= 1;
                    end
                    if (Qj[i] == CDB_1_en) begin
                        Qj[i] <= 16;
                        Vj[i] <= CDB_1_val;
                    end
                    if (Qk[i] == CDB_1_en) begin
                        Qk[i] <= 16;
                        Vk[i] <= CDB_1_val;
                    end
                end
            end
        end

        if (CDB_2_ok) begin
            for (i = 0; i < `RS_LEN; ++i) begin
                if (busy[i] && !ok[i]) begin
                    if ((Qj[i] == 16 || Qj[i] == CDB_2_en) && (Qk[i] == 16 || Qk[i] == CDB_2_en)) begin
                        ok[i] <= 1;
                    end
                    if (Qj[i] == CDB_2_en) begin
                        Qj[i] <= 16;
                        Vj[i] <= CDB_2_val;
                    end
                    if (Qk[i] == CDB_2_en) begin
                        Qk[i] <= 16;
                        Vk[i] <= CDB_2_val;
                    end
                end
            end
        end

    end
end
endmodule //reservation_station
