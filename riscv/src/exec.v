`include "def.v"

module exec (
    input wire        rs_ok,
    input wire [ 5:0] opt,
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire [31:0] imm,
    input wire [31:0] en,

    output reg        CDB_1_ok,
    output reg [ 4:0] CDB_1_en,
    output reg [31:0] CDB_1_val
);
reg [31:0] rd;
always @(*) begin
    if (rs_ok) begin
        case (opt)
            // R-type
            `ADD : rd <= rs1 + rs2;
            `SUB : rd <= rs1 - rs2;
            `SLL : rd <= rs1 << (rs2 & 5'b11111);
            `SLT : rd <= $signed(rs1) < $signed(rs2) ? 1 : 0;
            `SLTU: rd <= rs1 < rs2 ? 1 : 0;
            `XOR : rd <= rs1 ^ rs2;
            `SRL : rd <= rs1 >> (rs2 & 5'b11111);
            `SRA : rd <= $signed(rs1) >> (rs2 & 5'b11111);
            `OR  : rd <= rs1 | rs2;
            `AND : rd <= rs1 & rs2;
        
            // I-type
            `JALR : begin

            end
            `ADDI : rd <= rs1 + imm
            `SLTI : rd <= $signed(rs1) < $signed(imm) ? 1 : 0;
            `SLTIU: rd <= rs1 < imm ? 1 : 0;
            `XORI : rd <= rs1 ^ imm;
            `ORI  : rd <= rs1 | imm;
            `ANDI : rd <= rs1 & imm;
            `SLLI : rd <= rs1 << (imm & 5'b11111);
            `SRLI : rd <= rs1 >> (imm & 5'b11111);
            `SRAI : rd <= $signed(rs1) >> (imm & 5'b11111);
        
            // B-type
            `BEQ  : rd <= rs1 == rs2;
            `BNE  : rd <= rs1 != rs2;
            `BLT  : rd <= rs1 < rs2;
            `BGE  : rd <= rs1 >= rs2;
            `BLTU : rd <= $signed(rs1) < $signed(rs2);
            `BGEU : rd <= $signed(rs1) >= $signed(rs2);
        endcase
        CDB_1_ok <= 1;
        CDB_1_en <= en;
        CBD_1_val <= rd;
    end
    else begin
        CDB_1_ok <= 0;
    end
end
endmodule //exec
