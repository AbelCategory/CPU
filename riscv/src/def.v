// U-type
`ifndef DEF
`define DEF

`define LUI 6'b000000
`define AUIPC 6'b000001
// J-type
`define JAL 6'b000010
// jalr
`define JALR 6'b011111
// R-type
`define ADD 6'b000011
`define SUB 6'b000100
`define SLL 6'b000011
`define SLT 6'b000100
`define SLTU 6'b000101
`define XOR 6'b000110
`define SRL 6'b000111
`define SRA 6'b001000
`define OR  6'b001001
`define AND 6'b001010
// I-type
//load
`define LB  6'b101011
`define LH  6'b101100
`define LW  6'b101101
`define LBU 6'b101110
`define LHU 6'b101111
//alu-type
`define ADDI 6'b010000
`define SLTI 6'b010001
`define SLTIU 6'b010010
`define XORI 6'b010011
`define ORI  6'b010100
`define ANDI 6'b010101
`define SLLI 6'b010110
`define SRLI 6'b010111
`define SRAI 6'b011000
//S-type save
`define SB  6'b111001
`define SH  6'b111010
`define SW  6'b111011
// B-type
`define BEQ 6'b100000
`define BNE 6'b100001
`define BLT 6'b100010
`define BGE 6'b100011
`define BLTU 6'b100100
`define BGEU 6'b100101

`endif