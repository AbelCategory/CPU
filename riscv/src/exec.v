`include "def.v"

module exec (
    input wire [5:0] opt,
    input wire [31:0] rs1,
    input wire [31:0] rs2,
    input wire [31:0] imm,
    output reg [31:0] rd
);
always @(*) begin
    case (opt)
        // R-type
        `ADD : rd = rs1 + rs2;
        `SUB : rd = rs1 - rs2;
        `SLL : rd = rs1 << (rs2 & 5'b11111);
        `SLT : rd = $signed(rs1) < $signed(rs2) ? 1 : 0;
        `SLTU: rd = rs1 < rs2 ? 1 : 0;
        `XOR : rd = rs1 ^ rs2;
        `SRL : rd = rs1 >> (rs2 & 5'b11111);
        `SRA : rd = $signed(rs1) >> (rs2 & 5'b11111);
        `OR  : rd = rs1 | rs2;
        `AND : rd = rs1 & rs2;
        
        // I-type
        `JALR : begin

        end
        `ADDI : rd = rs1 + imm
        `SLTI : rd = $signed(rs1) < $signed(imm) ? 1 : 0;
        `SLTIU: rd = rs1 < imm ? 1 : 0;
        `XORI : rd = rs1 ^ imm;
        `ORI  : rd = rs1 | imm;
        `ANDI : rd = rs1 & imm;
        `SLLI : rd = rs1 << (imm & 5'b11111);
        `SRLI : rd = rs1 >> (imm & 5'b11111);
        `SRAI : rd = $signed(rs1) >> (imm & 5'b11111);
        
        // B-type
    endcase
end
endmodule //exec
