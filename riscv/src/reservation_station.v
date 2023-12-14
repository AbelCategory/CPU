`define RS_SIZE 15:0
`define RS_LEN 16
module RS (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_dc_ok,
    input wire [31:0] vj, vk,
    input wire [ 4:0] qj, qk, en,
    input wire [ 5:0] opt,

    output wire is_rs_full,
    
    output reg [ 5:0] to_alu_ok,
    output reg [ 5:0] to_alu_opt,
    output reg [31:0] to_alu_rs1, to_alu_rs2, to_alu_imm,
    output reg [ 3:0] to_alu_en, 
    input wire [31:0] from_alu_rd,

    input wire        CDB_1_ok,
    input wire [ 4:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 4:0] CDB_2_en,
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

assign is_rs_full = emp == 0 && from_dc_ok;

always @(posedge clk) begin
    if(rst || clear) begin
        to_alu_ok <= 0;
        busy <= 0;
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
                    op[i] <= opt; Qr[i] <= en;
                end
            end
        end
        if (ok != 0) begin
            for (i = 0; i < `RS_LEN; ++i) begin
                if (okp[i] == 1) begin
                    to_alu_ok <= 1;
                    to_alu_opt <= op[i];
                    to_alu_rs1 <= Vj[i];
                    case (op[i][5:3])
                        3'b000 : to_alu_rs2 <= Vk[i];
                        3'b010 : to_alu_imm <= Vk[i];
                        3'b100 : begin
                            
                        end
                    endcase
                end
            end
        end
        else begin
            to_alu_ok <= 0;
        end

        if (CDB_1_ok) begin
            for (i = 0; i < `RS_LEN; ++i) begin
                if (!ok[i]) begin
                    if ((Qj[i] == 0 || Qj[i] == CDB_1_en) && (Qk[i] == 0 || Qk[i] == CDB_1_en)) begin
                        ok[i] <= 1;
                    end
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
        end

        if (CDB_2_ok) begin
            for (i = 0; i < `RS_LEN; ++i) begin
                if (!ok[i]) begin
                    if ((Qj[i] == 0 || Qj[i] == CDB_2_en) && (Qk[i] == 0 || Qk[i] == CDB_2_en)) begin
                        ok[i] <= 1;
                    end
                    if (Qj[i] == CDB_2_en) begin
                        Qj[i] <= 0;
                        Vj[i] <= CDB_2_val;
                    end
                    if (Qk[i] == CDB_2_en) begin
                        Qk[i] <= 0;
                        Vk[i] <= CDB_2_val;
                    end
                end
            end
        end

    end
end
endmodule //reservation_station
