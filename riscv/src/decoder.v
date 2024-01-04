`include "def.v"

module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_if_ok,
    input wire [31:0] from_if_ins,
    input wire        from_if_jp,
    input wire [31:0] from_if_pc,

    output reg        to_rs_ready,
    output reg [31:0] rs_vj, rs_vk,
    output reg [ 4:0] rs_qj, rs_qk, rs_en,
    output reg [ 5:0] to_rs_opt,

    output reg        to_lsb_ready,
    output reg [31:0] lsb_vj, lsb_vk,
    output reg [ 4:0] lsb_qj, lsb_qk, lsb_en,
    output reg [ 5:0] to_lsb_opt,

    output reg        to_rob_ready,
    output reg [ 5:0] to_rob_opt,
    output reg [ 4:0] to_rob_en,
    output reg        to_rob_jp,
    output reg        to_rob_pc, 


    output wire        to_dc_ok,
    output wire [ 4:0] Rj, Rk, Rr
    input wire  [31:0] Vj, Vk,
    input wire  [ 3:0] Qj, Qk

);
reg [5:0] opt;
reg [4:0] rs1, rs2, rd, imm;
wire is_L, is_S, is_B;
decoder Dec(.code(from_if_ins), .opt(opt), .rs1(rs1), .rs2(rs2), .rd(rd), .imm(imm));

assign to_dc_ok = from_if_ok;
assign Rj = rs1;
assign Rk = rs2;
assign Rr = rd;

always @(posedge clk) begin
    if (rst) begin
        to_rs_ready <= 0; to_lsb_ready <= 0; to_rob_ready <= 0;
    end
    else if(!rdy) begin
        
    end
    else begin
        if (from_if_ok) begin
            to_rob_ready <= 1;
            to_rob_jp <= from_if_jp;
            to_rob_pc <= ;
            case (opt[5:3])
                3'b101 : begin //Load
                    to_lsb_ready <= 1;
                    lsb_vj <= Vj; lsb_vk <= imm;
                    lsb_qj <= Rj; lsb_qk <= 0;
                    lsb_en <= rd;
                    lsb_opt <= opt;
                end
                3'b111 : begin //Store  
                    to_lsb_ready <= 1;
                    lsb_vj <= Vj; lsb_vk <= imm + Vk;
                    lsb_qj <= Rj; lsb_qk <= ;
                end
                3'b000 : begin
                    if (opt == 0) begin // LUI
                        to_rs_ready <= 1;
                        to_rs_opt <= opt;
                    end
                end
                3'b001 : begin
                    to_rs_ready <= 1;
                    to_rs_opt <= opt;
                    rs_vj <= Vj; rs_vk <= Vk;
                    rs_qj <= Rj; rs_qk <= Rk;
                    rs_en <= rd;
                end
                3'b100 : begin
                    rs_
                end
                3'b010 : begin
                    to_rs_ready <= 1;
                    to_rs_opt <= opt;
                    rs_vj <= Vj; rs_vk <= imm;
                    rs_qj <= Rj; rs_qk <= 0;
                    rs_en <= rd;
                end
            endcase
        end
        else begin
            to_lsb_ready <= 1;
            to_rob_ready <= 1;
            to_rs_ready  <= 1;
        end
    end
end
endmodule //Decoder


module decoder (
    input wire [31:0] code,
    output reg [5:0] opt,
    output reg [4:0] rs1, rs2, rd,
    output reg [31:0] imm
);
always @(*) begin
    rd = code[11:7];
    rs1 = code[19:15];
    rs2 = code[24:20];
    imm = 0;
    case (code[6:0])
        7'b0110111 : begin
            opt = LUI;
            imm = {code[31:12], 12'b0};
        end
        7'b0010111 : begin
            opt = AUIPC;
            imm = {code[31:12], 12'b0};
        end
        7'b1101111 : begin
            opt = JAL;
            imm = {12{code[31]}, code[19:12], code[20], code[30:21], 1'b0};
        end
        7'b1100111 : begin
            opt = JALR;
            imm = {20{code[31]}, code[31:20]};
        end
        7'b1100011 : begin
            imm = {20{code[31]}, code[7], code[30:25], code[11:8], 1'b0};
            case (code[14:12])
                3'b000 : opt = BEQ;
                3'b001 : opt = BNE;
                3'b100 : opt = BLT;
                3'b101 : opt = BGE;
                3'b110 : opt = BLTU;
                3'b111 : opt = BGEU;
            endcase
        end
        7'b0000011 : begin
            imm = {20{code[31]}, code[31:20]};
            case (code[14:12])
                3'b000 : opt = LB;
                3'b001 : opt = LH;
                3'b010 : opt = LW;
                3'b100 : opt = LBU;
                3'b101 : opt = LHU;
            endcase
        end
        7'b0100011 : begin
            imm = {20{code[31]}, code[31:25], code[11:7]};
            case (code[14:12])
                3'b000 : opt = SB;
                3'b001 : opt = SH;
                3'b010 : opt = SW;
            endcase
        end
        7'b0010011 : begin
            imm = (code[14:12] == 3'b001 || code[14:12] == 3'b101) ? {27'b0, code[24:20]} : {20{code[31]}, code[31:20]};
            case (code[14:12])
                3'b000 : opt = ADDI;
                3'b010 : opt = SLTI;
                3'b011 : opt = SLTIU;
                3'b100 : opt = XORI;
                3'b110 : opt = ORI;
                3'b111 : opt = ANDI;
                3'b001 : opt = SLLI;
                3'b101 : opt = (code[31:25] == 7'b0) ? SRLI : SRAI;
            endcase
        end
        7'b0110011 : begin
            case (code[14:12])
                3'b000 : opt = (code[31:25] == 7'b0) ? ADD : SUB;
                3'b001 : opt = SLL;
                3'b010 : opt = SLT;
                3'b011 : opt = SLTU;
                3'b100 : opt = XOR;
                3'b101 : opt = (code[31:25] == 7'b0) ? SRL : SRA;
                3'b110 : opt = OR;
                3'b111 : opt = AND;
            endcase
        end
    endcase
end
endmodule //Decoder
