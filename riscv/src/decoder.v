`include "def.v"

module Decoder(
    input wire rst,
    input wire rdy,
    
    input wire clear,

    input wire        from_if_ok,
    input wire [31:0] from_if_pc,
    input wire [31:0] from_if_ins,
    input wire        from_if_jp,
    // input wire [31:0] from_if_jp_pc,


    output reg        to_rs_ready,
    output reg [31:0] rs_vj, rs_vk,
    output reg [ 4:0] rs_qj, rs_qk,
    // output reg [ 4:0] rs_en,
    output reg [ 5:0] to_rs_opt,

    output reg        to_lsb_ready,
    output reg        to_lsb_isok,
    output reg [31:0] lsb_vj, lsb_vk,
    output reg [ 4:0] lsb_qj, lsb_qk,
    // output reg [ 4:0] lsb_en,
    output reg [ 5:0] to_lsb_opt,

    output reg        to_rob_ready,
    output reg [ 5:0] to_rob_opt,
    output reg [ 4:0] to_rob_en,
    output reg        to_rob_isok,
    output reg        to_rob_jp,
    output reg [31:0] to_rob_val, 
    output reg [31:0] to_rob_pc,
    output reg [31:0] to_rob_jpc,

    output reg        to_if_ok,
    output reg [31:0] to_if_pc,

    // output reg        to_reg_ok,
    output wire [ 4:0] Rj, Rk,
    input wire  [31:0] vj, vk,
    input wire  [ 4:0] qj, qk,

    input wire        CDB_1_ok,
    input wire [ 3:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 3:0] CDB_2_en,
    input wire [31:0] CDB_2_val

);
wire [5:0] opt;
wire [4:0] rs1, rs2, rd;
wire [31:0] imm;

wire [31:0] Vj, Vk;
wire [4:0] Qj, Qk;

assign Vj = vj | ((CDB_1_ok && CDB_1_en == qj) ? CDB_1_val : 0) | ((CDB_2_ok && (CDB_2_en == qj)) ? CDB_2_val : 0);
assign Vk = vk | ((CDB_1_ok && CDB_1_en == qk) ? CDB_1_val : 0) | ((CDB_2_ok && (CDB_2_en == qk)) ? CDB_2_val : 0);

assign Qj = ((qj == 16) || (CDB_1_ok && qj == CDB_1_en) || (CDB_2_ok && qj == CDB_2_en)) ? 16 : qj;
assign Qk = ((qk == 16) || (CDB_1_ok && qk == CDB_1_en) || (CDB_2_ok && qk == CDB_2_en)) ? 16 : qk;


// wire is_L, is_S, is_B;
deco Dec(.code(from_if_ins), .opt(opt), .rs1(rs1), .rs2(rs2), .rd(rd), .imm(imm));

// assign to_reg_ok = from_if_ok;
assign Rj = rs1;
assign Rk = rs2;
// assign Rr = rd;

always @(*) begin
    if (rst || !rdy || clear) begin
        to_rs_ready = 0; to_lsb_ready = 0; to_rob_ready = 0;
    end
    else begin
        if (from_if_ok) begin
            to_rob_ready = opt != `JALR || Qj == 16;
            to_rob_jp = from_if_jp;
            to_rob_en = rd;
            to_rob_opt = opt;
            to_rob_pc = from_if_pc;
            // if (opt != 6'b011111) begin
            //     to_if_ok = 0;
            // end
            if (opt != 0 && opt != 1 && opt != 2 && opt != 31 && opt[5:3] != 7) begin
                to_rob_val = 0;
                to_rob_isok = 0;
            end
            else to_rob_isok = 1;
            case (opt[5:3])
                3'b101 : begin //Load
                    to_rs_ready = 0;
                    to_rs_opt = 0;
                    rs_vj = 0; rs_vk = 0;
                    rs_qj = 0; rs_qk = 0;

                    to_lsb_ready = 1;
                    to_lsb_isok = Qj == 16;
                    lsb_vj = Vj; lsb_vk = imm;
                    lsb_qj = Qj; lsb_qk = 16;
                    // lsb_en = rd;
                    to_lsb_opt = opt;
                    to_if_ok = 0;
                end
                3'b111 : begin //Store
                    // to be done
                    to_rs_ready = 0;
                    to_rs_opt = 0;
                    rs_vj = 0; rs_vk = 0;
                    rs_qj = 0; rs_qk = 0;

                    to_lsb_ready = 1;
                    to_lsb_isok = 0;
                    lsb_vj = imm + Vj; lsb_vk = Vk;
                    lsb_qj = Qj; lsb_qk = Qk;
                    // lsb_en = rd;
                    to_lsb_opt = opt;
                    to_if_ok = 0;
                end
                3'b011 : begin // JALR & SRAI
                    to_lsb_ready = 0;
                    to_lsb_isok = 0;
                    lsb_qj = 0; lsb_qk = 0;
                    lsb_vj = 0; lsb_vk = 0;
                    to_lsb_opt = 0;

                    if (opt[2:0] == 0) begin // SRAI
                        to_rs_ready = 1;
                        to_rs_opt = opt;
                        rs_vj = Vj; rs_vk = imm;
                        rs_qj = Qj; rs_qk = 16;
                        to_if_ok = 0;
                        // rs_en = rd;
                    end
                    if (opt[2:0] == 7) begin //JALR
                        to_rs_ready = 0;
                        to_rs_opt = 0;
                        rs_vj = 0; rs_vk = 0;
                        rs_qj = 0; rs_qk = 0;
                    // $display("jump %x Qj %x", from_if_pc, Qj);
                        if (Qj == 16) begin
                            // $display("entered!!!");
                            to_if_ok = 1;
                            to_if_pc = imm + Vj;
                            to_rob_val = from_if_pc + 4;
                        end
                        else begin
                            to_if_ok = 0;
                        end
                        // else begin
                        //     to_rob_ready = 0;
                        // end
                    end
                end
                3'b000 : begin
                    to_lsb_ready = 0;
                    to_lsb_isok = 0;
                    lsb_qj = 0; lsb_qk = 0;
                    lsb_vj = 0; lsb_vk = 0;
                    to_lsb_opt = 0;

                    to_if_ok = 0;
                    case (opt[2:0])
                        3'b000 : begin // LUI
                            to_rs_ready = 0;
                            to_rob_val = imm;
                        end
                        3'b001 : begin // AUIPC
                            to_rs_ready = 0;
                            to_rob_val = imm + from_if_pc;
                        end
                        3'b010 : begin // JAL
                            to_rs_ready = 0;
                            to_rob_val = from_if_pc + 4;
                        end
                        default: begin //arith
                            to_rs_ready = 1;
                            to_rs_opt = opt;
                            rs_vj = Vj; rs_vk = Vk;
                            rs_qj = Qj; rs_qk = Qk;
                            // rs_en = rd;
                        end
                    endcase
                end
                3'b001 : begin
                    to_if_ok = 0;

                    to_lsb_ready = 0;
                    to_lsb_isok = 0;
                    lsb_qj = 0; lsb_qk = 0;
                    lsb_vj = 0; lsb_vk = 0;
                    to_lsb_opt = 0;

                    to_rs_ready = 1;
                    to_rs_opt = opt;
                    rs_vj = Vj; rs_vk = Vk;
                    rs_qj = Qj; rs_qk = Qk;
                    // rs_en = rd;
                end
                3'b100 : begin //B
                    to_if_ok = 0;

                    to_lsb_ready = 0;
                    to_lsb_isok = 0;
                    lsb_qj = 0; lsb_qk = 0;
                    lsb_vj = 0; lsb_vk = 0;
                    to_lsb_opt = 0;

                    to_rs_ready = 1;
                    to_rs_opt = opt;
                    rs_vj = Vj; rs_vk = Vk;
                    rs_qj = Qj; rs_qk = Qk;
                    // rs_en = 0;

                    // to_rob_pc = from_if_pc;
                    if (from_if_jp) begin
                        to_rob_jpc = from_if_pc + 4;
                    end
                    else begin
                        to_rob_jpc = from_if_pc + imm;
                    end
                end
                3'b010 : begin //arith_I
                    to_if_ok = 0;

                    to_lsb_ready = 0;
                    to_lsb_isok = 0;
                    lsb_qj = 0; lsb_qk = 0;
                    lsb_vj = 0; lsb_vk = 0;
                    to_lsb_opt = 0;

                    to_rs_ready = 1;
                    to_rs_opt = opt;
                    rs_vj = Vj; rs_vk = imm;
                    rs_qj = Qj; rs_qk = 16;
                    // rs_en = rd;
                end
                default : begin
                    to_lsb_ready = 0;
                    to_lsb_isok = 0;
                    lsb_qj = 0; lsb_qk = 0;
                    lsb_vj = 0; lsb_vk = 0;
                    to_lsb_opt = 0;

                    to_rob_ready = 0;

                    to_rs_ready = 0;
                    to_rs_opt = 0;
                    rs_vj = 0; rs_vk = 0;
                    rs_qj = 0; rs_qk = 0;

                    to_if_ok = 0;
                end
            endcase
        end
        else begin
            to_lsb_ready = 0;
            to_rob_ready = 0;
            to_rs_ready  = 0;
            to_if_ok = 0;
        end
    end
end
endmodule 


module deco (
    input wire [31:0] code,
    output reg [5:0] opt,
    output reg [4:0] rs1, rs2, rd,
    output reg [31:0] imm
);
always @(*) begin
    if (code[6:0] == 7'b1100011 || code[6:0] == 7'b0100011) begin
        rd = 0;
    end
    else rd = code[11:7];

    if (code[6:0] == 7'b0110111) begin
        rs1 = 0;
    end
    else rs1 = code[19:15];

    if (code[6:0] == 7'b1100011 || code[6:0] == 7'b0100011 || code[6:0] == 7'b0110011) begin
        rs2 = code[24:20];
    end
    else rs2 = 0;
    // rs2 <= code[24:20];
    // imm = 0;
    case (code[6:0])
        7'b0110111 : begin
            opt = `LUI;
            imm = {code[31:12], 12'b0};
        end
        7'b0010111 : begin
            opt = `AUIPC;
            imm = {code[31:12], 12'b0};
        end
        7'b1101111 : begin
            opt = `JAL;
            imm = {{12{code[31]}}, code[19:12], code[20], code[30:21], 1'b0};
                
        end
        7'b1100111 : begin
            opt = `JALR;
            imm = {{20{code[31]}}, code[31:20]};
        end
        7'b1100011 : begin
            imm = {{20{code[31]}}, code[7], code[30:25], code[11:8], 1'b0};
            case (code[14:12])
                3'b000 : opt = `BEQ;
                3'b001 : opt = `BNE;
                3'b100 : opt = `BLT;
                3'b101 : opt = `BGE;
                3'b110 : opt = `BLTU;
                3'b111 : opt = `BGEU;
                default : opt = 0;
                    
            endcase
        end
        7'b0000011 : begin
            imm = {{20{code[31]}}, code[31:20]};
            case (code[14:12])
                3'b000 : opt = `LB;
                3'b001 : opt = `LH;
                3'b010 : opt = `LW;
                3'b100 : opt = `LBU;
                3'b101 : opt = `LHU;
                default : opt = 0;
            endcase
        end
        7'b0100011 : begin
            imm = {{20{code[31]}}, code[31:25], code[11:7]};
            case (code[14:12])
                3'b000 : opt = `SB;
                3'b001 : opt = `SH;
                3'b010 : opt = `SW;
                default : opt = 0;
                    
            endcase
        end
        7'b0010011 : begin
            imm = (code[14:12] == 3'b001 || code[14:12] == 3'b101) ? {27'b0, code[24:20]} : {{20{code[31]}}, code[31:20]};
            case (code[14:12])
                3'b000 : opt = `ADDI;
                3'b010 : opt = `SLTI;
                3'b011 : opt = `SLTIU;
                3'b100 : opt = `XORI;
                3'b110 : opt = `ORI;
                3'b111 : opt = `ANDI;
                3'b001 : opt = `SLLI;
                3'b101 : opt = (code[31:25] == 7'b0) ? `SRLI : `SRAI;
                default : opt = 0;
                    
            endcase
        end
        7'b0110011 : begin
            imm = 0;
            case (code[14:12])
                3'b000 : opt = (code[31:25] == 7'b0) ? `ADD : `SUB;
                3'b001 : opt = `SLL;
                3'b010 : opt = `SLT;
                3'b011 : opt = `SLTU;
                3'b100 : opt = `XOR;
                3'b101 : opt = (code[31:25] == 7'b0) ? `SRL : `SRA;
                3'b110 : opt = `OR;
                3'b111 : opt = `AND;
                default : opt = 0;
                    
            endcase
        end
        default : begin
            imm = 0;
            opt = 0;
        end
            
    endcase
end
endmodule //Decoder
