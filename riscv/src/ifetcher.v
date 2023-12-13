`define IDLE 3'b000
`define BUSY 3'b001
module ifetcher (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_ic_hit,
    input wire [31:0] from_ic_data,
    output wire        to_ic_ready,
    output wire [31:0] to_ic_addr,

    // input wire        from_decoder_ok,
    output reg        to_decoder_ready,
    output reg [31:0] to_decoder_data,
    output reg [31:0] to_decoder_pc,

    input wire        from_predictor_ok,
    output reg [31:0] to_predictor_pc,
    output reg [31:0] to_predictor_ins
);
reg [31:0] pc, next_pc;
reg [2:0] stat;

assign to_ic_addr = pc;
assign to_ic_ready = stat == `IDLE;

always @(*) begin
    if (rst) begin
        pc <= 0;
    end
    else if(!rst) begin
        
    end
    else begin
        if (from_ic_hit) begin
            to_decoder_data <= from_ic_data;
            to_decoder_pc <= pc;
            to_decoder_ready <= 1;
            next_pc <= pc + 4;
            stat = `IDLE;
        end
        else begin
            stat = `BUSY;
            to_decoder_ready <= 0;
        end
    end

end
endmodule //ifetcher
